//
//  PairedBrowsersViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 07.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class PairedBrowsersViewController: UITableViewController {    

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Paired Browsers"

        tableView.backgroundColor = .primaryBackground
        tableView.registerHeaderFooterView(PairedBrowsersHeaderView.self)
        tableView.sectionHeaderHeight = UITableView.automaticDimension
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell()
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(PairedBrowsersHeaderView.self)
        view.onScan = {
            print("Did scan")
        }
        return view
    }
}
