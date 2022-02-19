//
// Created by Dirk Jäckel on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WebConnectionDetailsViewController: UITableViewController, WebConnectionObserver {

    var connection: WebConnection!
    var peer: GnosisSafeWebPeerInfo!
    var chain: Chain!
    var key: KeyInfo?
    var rows: [RowType] = []

    enum RowType {
        case header
        case key
        case network
        case version
        case browser
        case description
        case expirationDate
        case button
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connection Details"

        tableView.registerCell(ContainerTableViewCell.self)
        tableView.registerCell(DisclosureWithContentCell.self)
        tableView.registerCell(ButtonTableViewCell.self)

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66

        assert(connection.remotePeer != nil)
        assert(connection.remotePeer is GnosisSafeWebPeerInfo)
        peer = connection.remotePeer as? GnosisSafeWebPeerInfo

        chain = connection.chainId.map(String.init).map(Chain.by(_:)) ?? Chain.mainnetChain()
        key = try? connection.accounts.first.flatMap(KeyInfo.firstKey(address:))

        WebConnectionController.shared.attach(observer: self, to: connection)

        reloadData()
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.webConnectionDetails)
    }

    func reloadData() {
        rows = [.header, .key, .network]
        if peer.appVersion != nil && peer.browser != nil {
            rows.append(contentsOf: [.version, .browser])
        } else {
            rows.append(.description)
        }
        rows.append(.expirationDate)
        rows.append(.button)
        tableView.reloadData()
    }

    func didUpdate(connection: WebConnection) {
        self.connection = connection
        reloadData()
        if connection.status == .final {
            dismiss(animated: true, completion: nil)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < rows.count else { return UITableViewCell() }
        switch rows[indexPath.row] {
        case .header:
            let cell = tableView.dequeueCell(ContainerTableViewCell.self)

            cell.selectionStyle = .none

            let detailView = ChooseOwnerDetailHeaderView()
            detailView.stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            detailView.setNeedsUpdateConstraints()

            detailView.imageView.setImage(
                url: peer.icons.first,
                placeholder: UIImage(named: "connection-placeholder"),
                failedImage: UIImage(named: "connection-placeholder"))

            detailView.textLabel.text = peer.name
            detailView.detailTextLabel.text = connection.createdDate?.timeAgo()

            cell.setContent(detailView)

            return cell

        case .key:
            let cell = contentCell()
            cell.setText("Key")

            if let key = key {
                let content = MiniAccountAndBalancePiece()
                let shortAddress = key.address.ellipsized()
                let info = NamingPolicy.name(for: key.address, chainId: chain.id!)
                let model = MiniAccountInfoUIModel(
                    prefix: chain.shortName,
                    address: key.address,
                    label: info.name,
                    imageUri: info.imageUri,
                    badge: key.keyType.imageName,
                    balance: shortAddress
                )
                content.setModel(model)
                cell.setContent(content)

            } else {
                cell.setContent(textView("Not Set"))
            }
            return cell

        case .network:
            let cell = contentCell()
            cell.setText("Network")
            let content = NetworkIndicator()
            content.textStyle = .primary
            content.text = chain.name
            content.dotColor = chain.backgroundColor
            cell.setContent(content)
            return cell

        case .version:
            let cell = contentCell()
            cell.setText("Version")
            let text = peer.appVersion ?? "Unknown"
            cell.setContent(textView(text))
            return cell

        case .browser:
            let cell = contentCell()
            cell.setText("Browser")
            let text = peer.browser ?? "Unknown"
            cell.setContent(textView(text))
            return cell

        case .description:
            let cell = contentCell()
            cell.setText("Description")
            let text = peer.description ?? "Unknown"
            cell.setContent(textView(text))
            return cell

        case .expirationDate:
            let cell = contentCell()
            cell.setText("Expires at")
            let text: String
            if let date = connection.expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short
                text = formatter.string(from: date)
            } else {
                text = "Not set"
            }
            cell.setContent(textView(text))
            return cell

        case .button:
            let cell = tableView.dequeueCell(ButtonTableViewCell.self)
            cell.selectionStyle = .none
            cell.height = 56
            cell.padding = 16
            cell.backgroundColor = .clear
            cell.setText("Disconnect", style: .filledError) { [unowned self] in
                let alertController = DisconnectionConfirmationController.create(connection: connection)
                self.present(alertController, animated: true)
            }
            return cell
        }
    }

    func contentCell() -> DisclosureWithContentCell {
        let cell = tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.selectionStyle = .none
        cell.accessoryType = .none
        return cell
    }

    func textView(_ text: String?) -> UIView {
        let label = UILabel()
        label.textAlignment = .right
        label.setStyle(.secondary)
        label.text = text
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < rows.count else { return }
        switch rows[indexPath.row] {
        case .expirationDate:
            openExpirationDateEditor()

        default:
            break
        }
    }

    func openExpirationDateEditor() {
        let datePickerVC = DatePickerViewController()
        datePickerVC.date = connection.expirationDate
        datePickerVC.minimum = Date()

        datePickerVC.onConfirm = { [unowned datePickerVC, unowned self] in
            dismiss(animated: true) {
                if let date = datePickerVC.date {
                    connection.expirationDate = date
                    WebConnectionController.shared.save(connection)
                }
            }
        }

        let vc = ViewControllerFactory.modal(viewController: datePickerVC, halfScreen: true)
        present(vc, animated: true)
    }
}
