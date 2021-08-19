//
//  SelectLedgerDeviceViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

protocol SelectLedgerDeviceDelegate: AnyObject {
    func selectLedgerDeviceViewController(_ controller: SelectLedgerDeviceViewController,
                                          didSelectDevice deviceId: UUID,
                                          bluetoothController: BluetoothController)
}

class SelectLedgerDeviceViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {
    private let bluetoothController = BluetoothController()

    /// If a Bluetooth device is not found within the time limit, we show empty results page
    private let searchTimeLimit: TimeInterval = 20
    private var searchTimer: Timer?
    private var completion: () -> Void = {}

    override var isEmpty: Bool { bluetoothController.devices.isEmpty }

    weak var delegate: SelectLedgerDeviceDelegate?

    convenience init(completion: @escaping () -> Void) {
        self.init(namedClass: Self.superclass())
        self.completion = completion
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
        delegate?.selectLedgerDeviceViewController(
            self, didSelectDevice: device.peripheral.identifier, bluetoothController: bluetoothController)        
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
