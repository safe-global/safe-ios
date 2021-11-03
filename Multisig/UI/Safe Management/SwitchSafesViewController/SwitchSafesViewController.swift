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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Switch Safes"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))
        tableView.register(AddSafeTableViewCell.nib(), forCellReuseIdentifier: "AddSafe")
        tableView.register(SafeEntryTableViewCell.nib(), forCellReuseIdentifier: "SafeEntry")
        tableView.registerHeaderFooterView(NetworkIndicatorHeaderView.self)

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
        // this will close this controller when the load safe modal is closed
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
            let selectNetworkVC = SelectNetworkViewController()
            selectNetworkVC.screenTitle = "Load Gnosis Safe"
            selectNetworkVC.descriptionText = "Select network on which your Safe was created:"
            selectNetworkVC.completion = { [weak self] chain  in
                let vc = EnterSafeAddressViewController()
                vc.chain = chain
                let ribbon = RibbonViewController(rootViewController: vc)
                ribbon.chain = vc.chain
                vc.completion = { self?.didTapCloseButton() }
                self?.show(ribbon, sender: self)
            }

            show(selectNetworkVC, sender: self)
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
}
