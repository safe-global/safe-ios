//
//  AddOwnerKeyViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 26.05.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddOwnerKeyViewController: UITableViewController {
    private let keyTypes: [(type: KeyType, title: String, subtitle: String)] = [
        (.deviceImported, "Import existing key", "Imort an existing key or seed phrase"),
        (.deviceGenerated, "Create New Key", "Create a new key that you can use as owner of your Gnosis Safe ")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Add Owner Key"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(CloseModal.closeModal))

        tableView.registerCell(AddOwnerKeyCell.self)
        tableView.estimatedRowHeight = 90
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .primaryBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.ownerKeysOptions)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keyTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyType = keyTypes[indexPath.row]
        let cell = tableView.dequeueCell(AddOwnerKeyCell.self)
        cell.set(title: keyType.title)
        cell.set(subtitle: keyType.subtitle)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch keyTypes[indexPath.row].type {
        case .deviceImported:
            let controller = OnboardingImportOwnerKeyViewController()
            show(controller, sender: self)
        case .deviceGenerated:
            let controller = OnboardingGenerateKeyViewController()
            show(controller, sender: self)
        case .walletConnect:
            break
        }
    }
}
