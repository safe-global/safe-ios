//
//  SelectLedgerDeviceViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 04.08.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class SelectLedgerDeviceViewController: UITableViewController {
    private var state: State = .searching

    enum State {
        case searching
        case devicesFound
        case notFound
    }

    override func viewDidLoad() {
        super.viewDidLoad()


    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tableHeaderView = TableHeaderView()
        switch state {
        case .searching:
            tableHeaderView.set("Searching for Ledger Nano X devices")
        case .devicesFound:
            tableHeaderView.set("Select your device")
        case .notFound:
            return nil
        }
        return tableHeaderView
    }
}
