//
//  LedgerKeyPickerViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerKeyPickerViewController: SegmentViewController {
    convenience init(deviceId: UUID, bluetoothController: BluetoothController, completion: @escaping () -> Void) {
        self.init(nibName: "SegmentViewController", bundle: Bundle.main)
        segmentItems = [
            SegmentBarItem(image: nil, title: "Ledger Live"),
            SegmentBarItem(image: nil, title: "Ledger")
        ]
        viewControllers = [
            LedgerKeyPickerContentViewController(type: .ledgerLive,
                                                 deviceId: deviceId,
                                                 bluetoothController: bluetoothController,
                                                 completion: completion),
            LedgerKeyPickerContentViewController(type: .ledger,
                                                 deviceId: deviceId,
                                                 bluetoothController: bluetoothController,
                                                 completion: completion)
        ]
        selectedIndex = 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connect Ledger Wallet"
    }
}

fileprivate enum LedgerKeyType {
    case ledgerLive
    case ledger
}

fileprivate struct KeyAddressInfo {
    var index: Int
    var address: Address
    var name: String?
    var exists: Bool { name != nil }
}

fileprivate class LedgerKeyPickerViewModel {
    let type: LedgerKeyType
    let deviceId: UUID
    let bluetoothController: BluetoothController
    let ledgerController: LedgerController

    var keys = [KeyAddressInfo]()
    var maxItemCount = 100
    var pageSize = 10
    var isLoading = true
    var selectedIndex = -1

    var canLoadMoreAddresses: Bool {
        keys.count < maxItemCount
    }

    lazy var basePathPattern: String = {
        switch type {
        case .ledgerLive: return "m/44'/60'/0'/0/{index}"
        case .ledger: return "m/44'/60'/0'/{index}"
        }
    }()

    var bluetoothIsConnected: Bool {
        bluetoothController.devices.first { $0.peripheral.identifier == deviceId } != nil
    }

    init(type: LedgerKeyType, deviceId: UUID, bluetoothController: BluetoothController) {
        self.type = type
        self.deviceId = deviceId
        self.bluetoothController = bluetoothController
        self.ledgerController = LedgerController(bluetoothController: bluetoothController)
    }

    func generateNextPage(completion: @escaping (Error?) -> Void) {
        guard !Thread.isMainThread else {
            preconditionFailure("should be called on background thread")
        }
        isLoading = true

        do {
            let indexes = (keys.count..<keys.count + pageSize)
            var addresses = [Address]()
            var shouldReturn = false

            for (_, index) in indexes.enumerated() {
                let semaphore = DispatchSemaphore(value: 0)
                let path = basePathPattern.replacingOccurrences(of: "{index}", with: "\(index)")
                ledgerController.getAddress(deviceId: self.deviceId, path: path) { [weak self] addressOrNil in
                    semaphore.signal()
                    guard let address = addressOrNil else {
                        self?.isLoading = false
                        completion("Address Not Found")
                        shouldReturn = true
                        return
                    }
                    addresses.append(address)
                }
                semaphore.wait()
                if shouldReturn {
                    return
                }
            }

            guard addresses.count == indexes.count else { return }

            let infoByAddress = try Dictionary(grouping: KeyInfo.keys(addresses: addresses), by: \.address)

            let nextPageKeys = indexes.enumerated().map { (i, addressIndex) -> KeyAddressInfo in
                let address = addresses[i]
                return KeyAddressInfo(index: addressIndex, address: address, name: infoByAddress[address]?.first?.name)
            }
            keys += nextPageKeys

            isLoading = false
            completion(nil)
        } catch {
            LogService.shared.error("Failed to generate addresses: \(error)")
            completion(error)
        }
    }

    func didSelect(key: KeyAddressInfo) {
        OwnerKeyController.importKey(ledgerDeviceUUID: deviceId,
                                     path: basePathPattern.replacingOccurrences(of: "{index}", with: "\(key.index)"),
                                     address: key.address,
                                     name: "Ledger key #\(key.index + 1)")
    }
}

fileprivate class LedgerKeyPickerContentViewController: UITableViewController {
    private var model: LedgerKeyPickerViewModel!
    private var completion: (() -> Void)!

    let estimatedRowHeight: CGFloat = 58

    var shouldShowLoadMoreButton: Bool {
        model.canLoadMoreAddresses && !model.isLoading
    }

    convenience init(type: LedgerKeyType,
                     deviceId: UUID,
                     bluetoothController: BluetoothController,
                     completion: @escaping () -> Void) {
        self.init()
        self.model = LedgerKeyPickerViewModel(type: type, deviceId: deviceId, bluetoothController: bluetoothController)
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(DerivedKeyTableViewCell.self)
        tableView.registerCell(ButtonTableViewCell.self)
        tableView.registerHeaderFooterView(LoadingFooterView.self)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = estimatedRowHeight

        generateNextPage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.ledgerSelectKey)
    }

    private func generateNextPage() {
        DispatchQueue.global().async {
            self.model.generateNextPage { [weak self] errorOrNil in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    guard self.model.bluetoothIsConnected else {
                        self.navigationController?.popViewController(animated: true)
                        return
                    }
                    if errorOrNil != nil {
                        let alert = UIAlertController(title: "Address Not Found",
                                                      message: "Please open Ethereum App on your Ledger device.",
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func updateWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        shouldShowLoadMoreButton ? model.keys.count + 1 : model.keys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == model.keys.count && shouldShowLoadMoreButton {
            let cell = tableView.dequeueCell(ButtonTableViewCell.self)
            let text = model.keys.count == 0 ? "Retry" : "Load more"
            cell.height = estimatedRowHeight
            cell.setText(text) { [weak self] in
                self?.generateNextPage()
                self?.updateWithDelay()
            }
            return cell
        }

        let key = model.keys[indexPath.row]
        let cell = tableView.dequeueCell(DerivedKeyTableViewCell.self, for: indexPath)
        cell.setLeft("#\(key.index + 1)")
        cell.setAddress(key.address)
        cell.setSelected(isSelected(indexPath))
        cell.setEnabled(!key.exists)

        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        model.didSelect(key: model.keys[indexPath.row])
        completion()
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if model.isLoading {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: LoadingFooterView.reuseID)
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if model.isLoading {
            return estimatedRowHeight
        }
        return 0
    }

    private func isSelected(_ indexPath: IndexPath) -> Bool {
        model.selectedIndex == indexPath.row
    }
}
