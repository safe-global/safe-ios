//
//  LedgerKeyPickerViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate let ledgerSerialQueue = DispatchQueue(label: "io.gnosis.safe.ledger.serial.queue")

class LedgerKeyPickerViewController: SegmentViewController {
    var completion: ((KeyAddressInfo, String?, String) -> Void)?

    private lazy var importButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Import", style: .done, target: self, action: #selector(didTapImport))
        return button
    }()

    convenience init(deviceId: UUID, bluetoothController: BaseBluetoothController) {
        self.init(nibName: "SegmentViewController", bundle: Bundle.main)
        segmentItems = [
            SegmentBarItem(image: nil, title: "Ledger Live"),
            SegmentBarItem(image: nil, title: "Ledger")
        ]
        viewControllers = [
            LedgerKeyPickerContentViewController(type: .ledgerLive,
                                                 deviceId: deviceId,
                                                 bluetoothController: bluetoothController,
                                                 importButton: importButton),
            LedgerKeyPickerContentViewController(type: .ledger,
                                                 deviceId: deviceId,
                                                 bluetoothController: bluetoothController,
                                                 importButton: importButton)
        ]
        selectedIndex = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connect Ledger Wallet"
        navigationItem.rightBarButtonItem = importButton
        importButton.isEnabled = false
    }

    @objc func didTapImport() {
        guard let selectedIndex = selectedIndex,
              let contentVC = viewControllers[selectedIndex] as? LedgerKeyPickerContentViewController,
              let key = contentVC.selectedKey else { return }

        var namePrefix = ""
        switch contentVC.keyType {
        case .ledger: namePrefix = "Ledger key #"
        case .ledgerLive: namePrefix = "Ledger Live key #"
        }
        let defaultName = "\(namePrefix)\(key.index + 1)"
        let derivationPath = contentVC.basePath.replacingOccurrences(of: "{index}", with: "\(key.index)")
        self.completion?(key, defaultName, derivationPath)
    }
}

fileprivate enum LedgerKeyType {
    case ledgerLive
    case ledger
}

fileprivate protocol LedgerKeyPickerViewModelDelegate: AnyObject {
    func didChangeLoadingState()
}

fileprivate class LedgerKeyPickerViewModel {
    let type: LedgerKeyType
    let deviceId: UUID
    let bluetoothController: BaseBluetoothController
    let ledgerController: LedgerController

    weak var delegate: LedgerKeyPickerViewModelDelegate?

    var keys = [KeyAddressInfo]()
    let maxItemCount = 100
    let pageSize = 10
    let getAddressTimeLimitInSec = 20
    var getAddressTimeLimitReached = false

    private(set) var isLoading = true {
        didSet {
            delegate?.didChangeLoadingState()
        }
    }
    var selectedIndex = -1

    var canLoadMoreAddresses: Bool {
        keys.count < maxItemCount
    }

    lazy var basePathPattern: String = {
        switch type {
        case .ledgerLive: return "m/44'/60'/{index}'/0/0"
        case .ledger: return "m/44'/60'/0'/{index}"
        }
    }()

    var bluetoothIsConnected: Bool {
        bluetoothController.devices.first { $0.identifier == deviceId } != nil
    }

    private var workItem: DispatchWorkItem?

    init(type: LedgerKeyType, deviceId: UUID, bluetoothController: BaseBluetoothController) {
        self.type = type
        self.deviceId = deviceId
        self.bluetoothController = bluetoothController
        self.ledgerController = LedgerController(bluetoothController: bluetoothController)
    }

    func generateNextPage(completion: @escaping (Error?) -> Void) {
        isLoading = true
        getAddressTimeLimitReached = false

        // We use serial queue because when switching Ledger / Ledger Live tabs, they should not try to send
        // commands to the Ledger Nano X device while processing other tab commands.
        workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.isLoading  else { return }

            let indexes = (self.keys.count..<self.keys.count + self.pageSize)
            var addresses = [Address]()
            var shouldReturn = false

            for index in indexes {
                // We use dispatch semaphore here because we need to get the required amount of addresses making
                // separate requests to the Ledger device before we continue with processing results.
                let semaphore = DispatchSemaphore(value: 0)
                let path = self.basePathPattern.replacingOccurrences(of: "{index}", with: "\(index)")
                self.ledgerController.getAddress(deviceId: self.deviceId, path: path) { [weak self] addressOrNil in
                    semaphore.signal()
                    guard let address = addressOrNil, self != nil else {
                        self?.isLoading = false
                        completion("Please unlock your Ledger device and open Ethereum App on it.")
                        shouldReturn = true
                        return
                    }
                    addresses.append(address)
                }
                guard semaphore.wait(timeout: .now().advanced(by: .seconds(self.getAddressTimeLimitInSec))) == .success else {
                    self.isLoading = false
                    self.getAddressTimeLimitReached = true
                    completion("""
Please unlock your Ledger device and open Ethereum App on it.

If it does not help, there is probably an issue with Bluetooth device pairing. Please remove pairing in your phone settings and try to pair with opened Ethereum App on your device.
"""
                    )
                    return
                }

                if shouldReturn {
                    return
                }
            }

            do {
                let infoByAddress = try Dictionary(grouping: KeyInfo.keys(addresses: addresses), by: \.address)

                let nextPageKeys = indexes.enumerated().map { (i, addressIndex) -> KeyAddressInfo in
                    let address = addresses[i]
                    return KeyAddressInfo(index: addressIndex,
                                          address: address,
                                          name: infoByAddress[address]?.first?.name)
                }
                self.keys += nextPageKeys

                self.isLoading = false
                completion(nil)
            } catch {
                LogService.shared.error("Failed to generate addresses: \(error)")
                completion(error)
            }
        }
        ledgerSerialQueue.async(execute: workItem!)
    }

    func stopLoading() {
        workItem?.cancel()
        isLoading = false
    }
}

fileprivate class LedgerKeyPickerContentViewController: UITableViewController, LedgerKeyPickerViewModelDelegate {
    private var model: LedgerKeyPickerViewModel!

    let estimatedRowHeight: CGFloat = 58
    var importButton: UIBarButtonItem!

    var shouldShowLoadMoreButton: Bool {
        model.canLoadMoreAddresses && !model.isLoading
    }

    var shouldShowOpenBluetoothSettingsButton: Bool {
        model.getAddressTimeLimitReached
    }

    var selectedKey: KeyAddressInfo? {
        guard model.selectedIndex != -1 else { return nil }
        return model.keys[model.selectedIndex]
    }

    var keyType: LedgerKeyType {
        model.type
    }

    var basePath: String {
        model.basePathPattern
    }

    var footerErrorMessage: String?

    convenience init(type: LedgerKeyType,
                     deviceId: UUID,
                     bluetoothController: BaseBluetoothController,
                     importButton: UIBarButtonItem) {
        self.init()
        self.model = LedgerKeyPickerViewModel(type: type, deviceId: deviceId, bluetoothController: bluetoothController)
        model.delegate = self
        self.importButton = importButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .backgroundPrimary
        tableView.registerCell(DerivedKeyTableViewCell.self)
        tableView.registerCell(ButtonTableViewCell.self)
        tableView.registerHeaderFooterView(LoadingFooterView.self)
        tableView.registerHeaderFooterView(LedgerBluetoothIssueFooterView.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = estimatedRowHeight
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = LedgerBluetoothIssueFooterView.estimatedHeight

        generateNextPage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ledgerSelectKey)
    }

    private func generateNextPage() {
        model.generateNextPage { [weak self] errorOrNil in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // If a Bluetooth device was disconnected while generating the next page with addresses,
                // we pop to select the ledger device screen.
                guard self.model.bluetoothIsConnected else {
                    self.navigationController?.popViewController(animated: true)
                    if let errorOrNil = errorOrNil {
                        App.shared.snackbar.show(message: errorOrNil.localizedDescription)
                    }
                    return
                }
                self.footerErrorMessage = errorOrNil?.localizedDescription
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = model.keys.count
        if shouldShowLoadMoreButton {
            count += 1
        }
        if shouldShowOpenBluetoothSettingsButton {
            count += 1
        }
        return count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == model.keys.count {
            if shouldShowLoadMoreButton {
                return loadMoreCell()
            } else {
                return openBluetoothSettingsCell()
            }
        }

        if indexPath.row == model.keys.count + 1 {
            return openBluetoothSettingsCell()
        }

        let key = model.keys[indexPath.row]
        let cell = tableView.dequeueCell(DerivedKeyTableViewCell.self, for: indexPath)
        cell.setLeft("#\(key.index + 1)")
        cell.setAddress(key.address)
        cell.setSelected(isSelected(indexPath))
        cell.setEnabled(!key.exists)

        return cell
    }

    private func loadMoreCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ButtonTableViewCell.self)
        let text = model.keys.count == 0 ? "Retry" : "Load more"
        cell.height = estimatedRowHeight
        cell.setText(text) { [weak self] in
            self?.generateNextPage()
        }
        return cell
    }

    private func openBluetoothSettingsCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ButtonTableViewCell.self)
        let text = "Open Bluetooth settings"
        cell.height = estimatedRowHeight
        cell.setText(text) {
            UIApplication.shared.open(URL(string: "App-Prefs:root=Bluetooth")!)
        }
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !model.keys[indexPath.row].exists else { return }
        importButton.isEnabled = true
        model.selectedIndex = indexPath.row
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if model.isLoading {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: LoadingFooterView.reuseID)
        }
        if let footerErrorMessage = footerErrorMessage {
            let view = tableView.dequeueHeaderFooterView(LedgerBluetoothIssueFooterView.self)
            view.set(description: footerErrorMessage)
            if shouldShowOpenBluetoothSettingsButton {
                view.set(link: "Learn more", url: App.configuration.help.ledgerPairingURL)
            } else {
                view.set(link: nil, url: nil)
            }
            return view
        }

        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if model.isLoading {
            return estimatedRowHeight
        }
        if footerErrorMessage != nil {
            return UITableView.automaticDimension
        }

        return 0
    }

    private func isSelected(_ indexPath: IndexPath) -> Bool {
        model.selectedIndex == indexPath.row
    }

    // MARK: - LedgerKeyPickerViewModelDelegate
    
    func didChangeLoadingState() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
