//
// Created by Dirk Jäckel on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionDetailsViewController: UITableViewController {

    var connection: WebConnection?
    private lazy var relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        formatter.unitsStyle = .full
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .close, target: self, action: #selector(didTapCloseButton))

        tableView.registerCell(ContainerTableViewCell.self)
        tableView.registerCell(DisclosureWithContentCell.self)
        tableView.registerCell(ButtonTableViewCell.self)
        tableView.registerHeaderFooterView(NetworkIndicatorHeaderView.self)
    }

    @objc private func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        6
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueCell(ContainerTableViewCell.self)
            let detailView = ChooseOwnerDetailHeaderView()
            detailView.imageView.image = UIImage(named: "safe-logo")
            cell.setContent(detailView)
            cell.textLabel?.text = "Gnosis Safe"
            if let connection = connection {
                cell.detailTextLabel?.text = relativeDateFormatter.localizedString(for: connection.createdDate!, relativeTo: Date())
            }
            return cell
        } else if indexPath.row > 0 && indexPath.row < 5 {
            let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
            cell.accessoryType = .none
            switch indexPath.row {
            case 1:
                cell.setText("Key")
                let content = MiniAccountAndBalancePiece()
                if let accounts = connection?.accounts {
                    if accounts.count > 0 {
                        let address = accounts[0]
                        let balance = accounts[0].ellipsized()
                        content.setModel(MiniAccountInfoUIModel(address: address, label: NamingPolicy.name(for: address, chainId: "1").name, balance: balance))
                    } else {
                        content.setModel(MiniAccountInfoUIModel(address: Address.zero, label: "Not set"))
                    }
                } else {
                    content.setModel(MiniAccountInfoUIModel(address: Address.zero, label: "Not set"))
                }
                cell.setContent(content)

            case 2:
                cell.setText("Network")
                let content = NetworkIndicator()
                content.textStyle = .primary
                if let connection = connection {
                    let chain = Chain.by(String(connection.chainId!))!
                    content.text = chain.name
                    content.dotColor = chain.backgroundColor
                }
                cell.setContent(content)
            case 3:
                cell.setText("Version")
                let content = UILabel()
                content.setStyle(.primary)
                content.textAlignment = .right
                content.text = "unknown"
                if let peerInfo = connection?.remotePeer as? GnosisSafeWebPeerInfo {
                    content.text = peerInfo.appVersion
                }
                cell.setContent(content)
            case 4:
                cell.setText("Browser")
                let content = UILabel()
                content.setStyle(.primary)
                content.textAlignment = .right
                content.text = "unknown"
                if let peerInfo = connection?.remotePeer as? GnosisSafeWebPeerInfo {
                    content.text = peerInfo.browser
                }
                cell.setContent(content)
            default:
                break
            }
            return cell
        }

        let cell = tableView.dequeueCell(ButtonTableViewCell.self)
        cell.setText("Disconnect") {
            // TODD
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 150
        }
        return 66
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        nil
//    }

//    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        100
//    }
}
