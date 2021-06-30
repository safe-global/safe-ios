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

    private var networkSafes = Network.NetworkSafes()
    private let addSafeSection = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Switch Safes"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        tableView.register(AddSafeTableViewCell.nib(), forCellReuseIdentifier: "AddSafe")
        tableView.register(SafeEntryTableViewCell.nib(), forCellReuseIdentifier: "SafeEntry")
        tableView.registerHeaderFooterView(BasicHeaderView.self)

        notificationCenter.addObserver(
            self, selector: #selector(reloadData), name: .selectedSafeChanged, object: nil)
        notificationCenter.addObserver(
            self, selector: #selector(reloadData), name: .selectedSafeUpdated, object: nil)

        reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.safeSwitch)
    }

    @objc private func reloadData() {
        networkSafes = Network.networkSafes()
        tableView.reloadData()
    }

    @objc override func closeModal() {
        // this will close this controller when the load safe modal is closed
        presentingViewController?.dismiss(animated: true, completion: nil)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        networkSafes.count + 1 /* for Add Safe button */
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == addSafeSection {
            return 1
        } else {
            return networkSafes[section - 1].safes.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == addSafeSection {
            return tableView.dequeueReusableCell(withIdentifier: "AddSafe", for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "SafeEntry", for: indexPath) as! SafeEntryTableViewCell
        let safe = networkSafes[indexPath.section - 1].safes[indexPath.row]
        cell.setName(safe.displayName)
        cell.setAddress(safe.addressValue)
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
            let vc = EnterSafeAddressViewController()
            vc.completion = { [weak self] in
                self?.didTapCloseButton()
            }
            show(vc, sender: self)
        } else {
            let safe = networkSafes[indexPath.section - 1].safes[indexPath.row]
            if !safe.isSelected {
                safe.select()
                didTapCloseButton()
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != addSafeSection else { return nil }
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(networkSafes[section - 1].network.chainName!)
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == addSafeSection ? 0 : BasicHeaderView.headerHeight
    }
}
