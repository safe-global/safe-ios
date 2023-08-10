//
//  SwitchSafesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 30.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

final class SwitchSafesViewController: UITableViewController {
    var notificationCenter = NotificationCenter.default

    private var chainSafes = Chain.ChainSafes()
    private let addSafeSection = 0

    var onCreateSafe: (() -> ())?
    var onAddSafe: (() -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Switch Safe Accounts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        
        if #unavailable(iOS 15) {
            // explicitly set background color to prevent transparent background in dark mode (iOS 14)
            navigationController?.navigationBar.backgroundColor = .backgroundSecondary
        }
        tableView.register(AddSafeTableViewCell.nib(), forCellReuseIdentifier: "AddSafe")
        tableView.register(SafeEntryTableViewCell.nib(), forCellReuseIdentifier: "SafeEntry")
        tableView.registerHeaderFooterView(NetworkIndicatorHeaderView.self)

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        notificationCenter.addObserver(
            self, selector: #selector(reloadData), name: .selectedSafeChanged, object: nil)
        notificationCenter.addObserver(
            self, selector: #selector(reloadData), name: .selectedSafeUpdated, object: nil)

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.safeSwitch)
    }

    @objc private func reloadData() {
        chainSafes = Chain.chainSafes()
        tableView.reloadData()
    }

    @objc override func closeModal() {
        // this will close this controller when the load Safe Account modal is closed
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        chainSafes.count + 1 /* for Add Safe button */
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == addSafeSection {
            return 1
        } else {
            return chainSafes[section - 1].safes.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == addSafeSection {
            return tableView.dequeueReusableCell(withIdentifier: "AddSafe", for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "SafeEntry", for: indexPath) as! SafeEntryTableViewCell
        let safe = chainSafes[indexPath.section - 1].safes[indexPath.row]
        cell.setName(safe.displayName)
        cell.setProgress(enabled: false)

        switch safe.safeStatus {
        case .deployed:
            cell.setAddress(safe.addressValue)
            cell.setDetail(address: safe.addressValue, prefix: safe.chain!.shortName)

        case .deploying, .indexing:
            cell.setAddress(safe.addressValue, grayscale: true)
            cell.setDetail(text: "Creating in progress...", style: .bodyTertiary)
            cell.setProgress(enabled: true)

        case .deploymentFailed:
            cell.setAddress(safe.addressValue, grayscale: true)
            cell.setDetail(text: "Failed to create", style: .bodyError)
        }

        cell.setSelection(safe.isSelected)
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == addSafeSection ? 54 : 66
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == addSafeSection {
            let alertController = UIAlertController(
                title: nil,
                message: nil,
                preferredStyle: .multiplatformActionSheet)

            let addSafe = UIAlertAction(title: "Load existing Safe Account", style: .default) { [weak self] _ in
                self?.onAddSafe?()
            }

            let createSafe = UIAlertAction(title: "Create new Safe Account", style: .default) { [weak self] _ in
                self?.onCreateSafe?()
            }
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(addSafe)
            alertController.addAction(createSafe)
            alertController.addAction(cancel)
            self.present(alertController, animated: true)
        } else {
            let safe = chainSafes[indexPath.section - 1].safes[indexPath.row]
            if !safe.isSelected {
                safe.select()
                didTapCloseButton()
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != addSafeSection else { return nil }

        let view = tableView.dequeueHeaderFooterView(NetworkIndicatorHeaderView.self)
        let chain = chainSafes[section - 1].chain
        view.text = chain.name
        view.dotColor = chain.backgroundColor
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == addSafeSection ? 0 : NetworkIndicatorHeaderView.height
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section != addSafeSection
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let safe = chainSafes[indexPath.section - 1].safes[indexPath.row]

        var actions = [UIContextualAction]()

        let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            self?.remove(safe: safe)
            completion(true)
        }
        actions.append(deleteAction)

        return UISwipeActionsConfiguration(actions: actions)
    }

    private func remove(safe: Safe) {
        let title = safe.safeStatus == .deployed ?
        "Removing a Safe only removes it from this app. It does not delete the Safe from the blockchain. Funds will not get lost." :
        "Are you sure you want to remove this Safe? The transaction fees will not be returned."
        let alertController = UIAlertController(
            title: nil,
            message: title,
            preferredStyle: .multiplatformActionSheet)

        let remove = UIAlertAction(title: "Remove", style: .destructive) { _ in
            Safe.remove(safe: safe)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        self.present(alertController, animated: true)
    }
}
