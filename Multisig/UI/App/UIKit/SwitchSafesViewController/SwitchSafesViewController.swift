//
//  SwitchSafesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

final class SwitchSafesViewController: UITableViewController {

    private var safes = [Safe]()
    private let addSafeRowIndex = 0

    private lazy var closeButton: UIBarButtonItem = {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular, scale: .large)
        let buttonImage = UIImage(systemName: "xmark")?.applyingSymbolConfiguration(symbolConfig)
        let button = UIBarButtonItem(image: buttonImage, style: .plain, target: self, action: #selector(didTapCloseButton))
        button.tintColor = .gnoMediumGrey
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Switch Safes"
        navigationItem.leftBarButtonItem = closeButton
        tableView.register(AddSafeTableViewCell.nib(), forCellReuseIdentifier: "AddSafe")
        tableView.register(SafeEntryTableViewCell.nib(), forCellReuseIdentifier: "SafeEntry")
        reloadData()
    }

    private func reloadData() {
        do {
            safes = try Safe.getAll()
            tableView.reloadData()
        } catch {
            // TODO: snackbar
            LogService.shared.error("SwitchSafesViewController: Failed to fetch list of safes: \(error)")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        safes.count + 1 /* for Add Safe button */
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == addSafeRowIndex {
            return tableView.dequeueReusableCell(withIdentifier: "AddSafe", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SafeEntry", for: indexPath) as! SafeEntryTableViewCell
            let safe = safes[indexPath.row - 1]
            cell.setName(safe.displayName)
            cell.setAddress(safe.addressValue)
            cell.setSelection(safe.isSelected)
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.row == addSafeRowIndex ? 54 : 66
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == addSafeRowIndex {
            // TODO add safe flow
        } else {
            let safe = safes[indexPath.row - 1]
            if !safe.isSelected {
                safe.select()
                didTapCloseButton()
            }
        }
    }

    @objc func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}
