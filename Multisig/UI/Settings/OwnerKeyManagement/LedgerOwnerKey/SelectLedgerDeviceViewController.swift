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
        loadingView.set(backgroundColor: .white)

        emptyView.setText("No Ledger Nano X device found. Please make sure your Ledger Nano X is unlocked, Bluetooth is enabled, and the Ethereum app is installed and opened.")
        emptyView.setImage(UIImage(named: "enable-ledger")!)
    }

    override func reloadData() {
        super.reloadData()

        bluetoothController.scan()
    }

    // MARK: - Table view data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bluetoothController.devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = bluetoothController.devices[indexPath.row]
        let cell = tableView.dequeueCell(BasicCell.self)
        cell.setTitle(device.name)
        return cell
    }


    // MARK: - Table view delegate

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
    func bluetoothControllerDidReceive(response: Data, device: BluetoothDevice) {
        // do noth
    }

    func bluetoothControllerDidFailToConnectBluetooth(error: Error) {
        onSuccess()
    }

    func bluetoothControllerDidDiscover(device: BluetoothDevice) {
        onSuccess()
    }

    func bluetoothControllerDidDisconnect(device: BluetoothDevice, error: Error?) {
        onSuccess()
    }

    func bluetoothControllerDataToSend(device: BluetoothDevice) -> Data? {
        nil
    }
}
