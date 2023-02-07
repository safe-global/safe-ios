//
//  FeatureToggleTableViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.01.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit

class FeatureToggleTableViewController: UITableViewController {

    enum RowID {
        case securityCenter
        case halt
    }

    var rows: [RowID] = [.securityCenter, .halt]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Toggles"

        tableView.registerCell(SwitchDetailedTableViewCell.self)
        tableView.registerCell(ButtonTableViewCell.self)

        tableView.backgroundColor = .backgroundPrimary
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let rowID = rows[indexPath.row]
        switch rowID {
        case .securityCenter:
            let cell = tableView.dequeueCell(SwitchDetailedTableViewCell.self, for: indexPath)
            cell.text = "Security v2"
            cell.detailText = "This will switch passcode functionality to use the new key security infrastructure."
            cell.setOn(AppConfiguration.FeatureToggles.securityCenter, animated: false)

            return cell

        case .halt:
            let cell = tableView.dequeueCell(ButtonTableViewCell.self, for: indexPath)

            cell.setText("Shtudown the app") {
                exit(0)
            }

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let rowID = rows[indexPath.row]
        switch rowID {
        case .securityCenter:
            AppConfiguration.FeatureToggles.securityCenter.toggle()
            let cell = tableView.cellForRow(at: indexPath) as! SwitchDetailedTableViewCell
            cell.setOn(AppConfiguration.FeatureToggles.securityCenter)

        default:
            break
        }
    }
    
}
