//
//  DappsViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 19.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class DappsViewController: UITableViewController {
    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var sections = [SectionItems]()

    enum Section {
        case walletConnect(String)
        case dapp(String)

        enum WalletConnect: SectionItem {
            case activeSession(String)
            case noSessions(String)
        }

        enum Dapp: SectionItem {
            case name(String)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
        addWCButton()
        updateSections()
    }

    private func configureTableView() {
        tableView.backgroundColor = .gnoWhite
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.registerCell(BasicCell.self)
    }

    private func addWCButton() {
        let button = UIButton()
        button.setImage(UIImage(named: "wc-button"), for: .normal)
        button.addTarget(self, action: #selector(scan), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func updateSections() {
        sections = [
            (section: .walletConnect("WalletConnect"), items: [Section.WalletConnect.noSessions("No active sessions")])
        ]
    }

    @objc private func scan() {
        let vc = QRCodeScannerViewController()
        vc.scannedValueValidator = { value in
            guard value.starts(with: "wc:") else {
                return .failure(GSError.InvalidWalletConnectQRCode())
            }
            return .success(value)
        }
        vc.modalPresentationStyle = .overFullScreen
        vc.delegate = self
        vc.setup()
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]

        switch item {
        case Section.WalletConnect.noSessions(let name):
            return basicCell(name: name, indexPath: indexPath, withDisclosure: false, canSelect: false)

        default:
            return UITableViewCell()
        }
    }

    #warning("Move to extension")
    private func basicCell(name: String,
                           indexPath: IndexPath,
                           withDisclosure: Bool = true,
                           canSelect: Bool = true) -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        if !withDisclosure {
            cell.setDisclosureImage(nil)
        }
        if !canSelect {
            cell.selectionStyle = .none
        }
        return cell
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.walletConnect(let name):
            view.setName(name)

        case Section.dapp(let name):
            view.setName(name)
        }

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

}

extension DappsViewController: QRCodeScannerViewControllerDelegate {
    func scannerViewControllerDidScan(_ code: String) {
        do {
            try WalletConnectController.shared.connect(url: code)
            dismiss(animated: true, completion: nil)
        } catch {
            App.shared.snackbar.show(message: error.localizedDescription)
        }
    }

    func scannerViewControllerDidCancel() {
        dismiss(animated: true, completion: nil)
    }
}
