//
//  ChangeDisplayModeTableViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/6/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class ChangeDisplayModeTableViewController: UITableViewController {
    private let items: [(name: String, style: UIUserInterfaceStyle)] = [("Auto", UIUserInterfaceStyle.unspecified), ("Light", UIUserInterfaceStyle.light), ("Dark", UIUserInterfaceStyle.dark)]

    private var selectedDisplayMode: UIUserInterfaceStyle {
        get {
            App.shared.theme.displayMode
        }
        set {
            App.shared.theme.displayMode = newValue
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Appearance"

        tableView.registerCell(BasicCell.self)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)

        cell.setTitle("\(items[indexPath.row].name)")
        cell.setDisclosureImage(items[indexPath.row].style == selectedDisplayMode ? UIImage(systemName: "checkmark")?.withTintColor(.button) : nil)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedDisplayMode = items[indexPath.row].style
        tableView.reloadData()
    }
}
