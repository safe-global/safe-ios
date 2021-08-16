//
//  SelectLedgerDeviceViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectLedgerDeviceViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    private let bluetoothController = BluetoothController()
    private lazy var ledgerController = { LedgerController(bluetoothController: bluetoothController) }()

    /// If a Bluetooth device is not found within the time limit, we show empty results page
    private let searchTimeLimit: TimeInterval = 20
    private var searchTimer: Timer?

    override var isEmpty: Bool { bluetoothController.devices.isEmpty }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Connect Ledger Wallet"

        bluetoothController.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerCell(BasicCell.self)
        tableView.rowHeight = BasicCell.rowHeight
        tableView.sectionHeaderHeight = 100
        tableView.backgroundColor = .primaryBackground

        loadingView.set(title: "Searching for Ledger Nano X devices")

        emptyView.setText("No Ledger Nano X device found. Please make sure your Ledger Nano X is unlocked, Bluetooth is enabled, and the Ethereum app is installed and opened.")
        emptyView.setImage(UIImage(named: "enable-ledger")!)
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
        ledgerController.getAddress(deviceId: device.peripheral.identifier, at: 0) { [weak self] ledgerInfoOrNil in
            guard let ledgerInfo = ledgerInfoOrNil else {
                let alert = UIAlertController(title: "Address Not Found", message: "Please open Ethereum App on your Ledger device.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            OwnerKeyController.importKey(ledgerDeviceUUID: device.peripheral.identifier,
                                         path: ledgerInfo.path,
                                         address: ledgerInfo.address,
                                         name: ledgerInfo.name)
            self?.dismiss(animated: true, completion: nil)
        }
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
        App.shared.snackbar.show(error: error)
    }

    func bluetoothControllerDidDiscover(device: BluetoothDevice) {
        onSuccess()
    }

    func bluetoothControllerDidDisconnect(device: BluetoothDevice, error: DetailedLocalizedError?) {
        onSuccess()
        if let error = error {
            App.shared.snackbar.show(error: error)
        }
    }
}
