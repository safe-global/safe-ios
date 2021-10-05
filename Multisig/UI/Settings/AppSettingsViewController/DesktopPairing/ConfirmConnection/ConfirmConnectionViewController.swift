//
//  ConfirmConnectionViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 08.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

class ConfirmConnectionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var connectButton: UIButton!

    private var dappInfo: Session.ClientMeta!
    private var keys = [KeyInfo]()
    private var selectedKeys = [KeyInfo]() {
        didSet {
            tableView.reloadData()
            connectButton.isEnabled = !selectedKeys.isEmpty
        }
    }

    let supportedKeyTypes = [KeyType.deviceImported, .deviceGenerated, .ledgerNanoX]

    var onConnect: (([KeyInfo]) -> Void)?
    var onCancel: (() -> Void)?

    @IBAction func connect(_ sender: Any) {
        onConnect?(selectedKeys)
    }

    @objc func cancel() {
        onCancel?()
    }

    convenience init(dappInfo: Session.ClientMeta) {
        self.init()
        self.dappInfo = dappInfo
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let keys = try? KeyInfo.all().filter({ supportedKeyTypes.contains($0.keyType) }), !keys.isEmpty else {
            dismiss(animated: true, completion: nil)
            return
        }
        self.keys = keys
        selectedKeys.append(keys[0])

        title = "Pairing Request"

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel", style: .plain, target: self, action: #selector(cancel))

        connectButton.setText("Connect", .filled)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .primaryBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 48

        tableView.registerCell(PairingOwnerKeyCell.self)
        tableView.registerHeaderFooterView(ConfirmConnectionHeaderView.self)
    }
}

extension ConfirmConnectionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        keys.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let keyInfo = keys[indexPath.row]
        let selected = selectedKeys.contains(keyInfo)
        let cell = tableView.dequeueCell(PairingOwnerKeyCell.self, for: indexPath)
        cell.selectionStyle = .none
        cell.configure(keyInfo: keyInfo, selected: selected)
        return cell
    }
}

#warning("TODO: enable multiple keys selection later")
extension ConfirmConnectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let keyInfo = keys[indexPath.row]
        selectedKeys = [keyInfo]
//        if let index = selectedKeys.firstIndex(of: keyInfo) {
//            selectedKeys.remove(at: index)
//        } else {
//            selectedKeys.append(keyInfo)
//        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(ConfirmConnectionHeaderView.self)
        view.setTitle("Connect your Owner Key to\n\(dappInfo.name)")
        view.setImage(url: dappInfo.icons.first)
        return view
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 160
    }
}
