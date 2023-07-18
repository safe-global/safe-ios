//
//  SelectLedgerDeviceViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectLedgerDeviceViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

#if targetEnvironment(simulator)
    private let bluetoothController = SimulatedBluetoothController()
#else
    private let bluetoothController = BluetoothController()
#endif

    /// If a Bluetooth device is not found within the time limit, we show empty results page
    private let searchTimeLimit: TimeInterval = 20
    private var searchTimer: Timer?
    private var trackingParameters: [String: Any]!
    private var showsCloseButton: Bool!
    private var navTitle: String!

    override var isEmpty: Bool { bluetoothController.devices.isEmpty }

    var completion: (UUID, BaseBluetoothController) -> Void = { _, _ in }
    var onClose: (() -> Void)?

    convenience init(trackingParameters: [String: Any],
                     title: String,
                     showsCloseButton: Bool) {
        self.init(namedClass: Self.superclass())
        self.trackingParameters = trackingParameters
        self.navTitle = title
        self.showsCloseButton = showsCloseButton
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = navTitle
        if showsCloseButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(CloseModal.closeModal))
        }

        bluetoothController.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(BasicCell.self)
        tableView.rowHeight = BasicCell.rowHeight
        tableView.sectionHeaderHeight = 100
        tableView.backgroundColor = .backgroundPrimary
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        loadingView.set(title: "Searching for Ledger Nano X devices")

        emptyView.setTitle("No Ledger Nano X device found. Please make sure your Ledger Nano X is unlocked, Bluetooth is enabled, and the Ethereum app is installed and opened.")
        emptyView.setImage(UIImage(named: "enable-ledger")!)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Tracker.trackEvent(.ledgerSelectDevice, parameters: trackingParameters)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onClose?()
    }

    override func reloadData() {
        super.reloadData()

        bluetoothController.scan()
        searchTimer = Timer.scheduledTimer(withTimeInterval: searchTimeLimit, repeats: false) { [weak self] _ in
            self?.bluetoothController.stopScan()
            self?.onSuccess()
        }
    }

    override func onSuccess() {
        super.onSuccess()
        searchTimer?.invalidate()
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bluetoothController.devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = bluetoothController.devices[indexPath.row]
        let cell = tableView.basicCell(name: device.name, indexPath: indexPath)
        return cell
    }

    // MARK: - Table view delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let device = bluetoothController.devices[indexPath.row]
        completion(device.identifier, bluetoothController)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !isEmpty {
            let tableHeaderView = TableHeaderView()
            tableHeaderView.set("Select your device")
            return tableHeaderView
        }
        return nil
    }
}

extension SelectLedgerDeviceViewController: BluetoothControllerDelegate {
    func bluetoothControllerDidFailToConnectBluetooth(error: DetailedLocalizedError) {
        onSuccess()
        if error is GSError.BluetoothIsNotAuthorized {
            let alertVC = UIAlertController(title: nil,
                                            message: "Please enable Bluetooth in App Settings",
                                            preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            let settings = UIAlertAction(title: "Settings", style: .default) { _ in
                let url = URL(string: UIApplication.openSettingsURLString)!
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
            }
            alertVC.addAction(cancel)
            alertVC.addAction(settings)
            present(alertVC, animated: true, completion: nil)
        }
    }

    func bluetoothControllerDidDiscover(device: BaseBluetoothDevice) {
        onSuccess()
    }

    func bluetoothControllerDidDisconnect(device: BaseBluetoothDevice, error: DetailedLocalizedError?) {
        onSuccess()
    }
}
