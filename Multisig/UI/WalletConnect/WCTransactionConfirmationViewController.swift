//
//  WCTransactionConfirmationViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift
import Kingfisher
import SwiftCryptoTokenFormatter

fileprivate protocol SectionItem {}

class WCTransactionConfirmationViewController: UIViewController {
    @IBOutlet private weak var dappImageView: UIImageView!
    @IBOutlet private weak var dappNameLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var rejectButton: UIButton!
    @IBOutlet private weak var submitButton: UIButton!

    var onReject: (() -> Void)?
    var onSubmit: ((_ nonce: UInt256String, _ safeTxHash: HashString) -> Void)?

    private var transaction: Transaction!
    private var safe: Safe!
    private var minimalNonce: UInt256String!
    private var session: Session!
    private var importedKeysForSafe: [Address]!
    private lazy var trackingParameters: [String: Any] = { ["chain_id": safe.chain!.id!] }()

    enum Section {
        case basic
        case advanced

        enum Basic: SectionItem {
            case safe(UITableViewCell)
            case transaction(UITableViewCell)
            case data(UITableViewCell)
            case advanced(UITableViewCell)
        }

        enum Advanced: SectionItem {
            case nonce(UITableViewCell)
            case safeTxGas(UITableViewCell)
            case edit(UITableViewCell)
        }
    }

    private typealias SectionItems = (section: Section, items: [SectionItem])
    private var sections = [SectionItems]()

    private var isAdvancedOptionsShown = false

    @IBAction private func reject(_ sender: Any) {
        onReject?()
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func submit(_ sender: Any) {
        let owners = (try? KeyInfo.keys(addresses: importedKeysForSafe)) ?? []
        let descriptionText = "You are about to confirm this transaction. This happens off-chain. Please select which owner key to use."
        let vc = ChooseOwnerKeyViewController(owners: owners, descriptionText: descriptionText) {
            [unowned self] keyInfo in

            // dismiss presented ChooseOwnerKeyViewController right after receiving the completion
            dismiss(animated: true) {
                guard let keyInfo = keyInfo else { return }
                sign(keyInfo: keyInfo)
            }
        }

        let navigationController = UINavigationController(rootViewController: vc)
        present(navigationController, animated: true)
    }

    private func sign(keyInfo: KeyInfo) {
        switch keyInfo.keyType {

        case .deviceImported, .deviceGenerated:
            DispatchQueue.global().async { [unowned self] in
                do {
                    let signature = try SafeTransactionSigner().sign(transaction, keyInfo: keyInfo)
                    self.sendConfirmationAndDismiss(keyInfo: keyInfo,
                                                    signature: signature.hexadecimal,
                                                    trackingEvent: .incomingTxConfirmed)
                } catch {
                    DispatchQueue.main.async {
                        App.shared.snackbar.show(
                            error: GSError.error(description: "Could not sign transaction.", error: error))
                    }
                }
            }

        case .walletConnect:
            WalletConnectClientController.shared.sign(transaction: transaction, from: self) { [weak self] signature in
                self?.sendConfirmationAndDismiss(keyInfo: keyInfo,
                                                 signature: signature,
                                                 trackingEvent: .incomingTxConfirmedWalletConnect)
            }

            WalletConnectClientController.openWalletIfInstalled(keyInfo: keyInfo)
        }
    }

    private func sendConfirmationAndDismiss(keyInfo: KeyInfo, signature: String, trackingEvent: TrackingEvent) {
        do {
            try App.shared.clientGatewayService.proposeTransaction(transaction: transaction,
                                                                   sender: AddressString(keyInfo.address),
                                                                   signature: signature,
                                                                   networkId: safe.chain!.id!)
            Tracker.trackEvent(trackingEvent, parameters: trackingParameters)

            DispatchQueue.main.async { [weak self] in
                // dismiss WCTransactionConfirmationViewController
                self?.dismiss(animated: true, completion: nil)
                App.shared.snackbar.show(message: "The transaction is submitted and can be confirmed by other owners. Once it is executed the dapp will get a response with the transaction hash.")
            }

            onSubmit?(transaction.nonce, transaction.safeTxHash)
        } catch {
            DispatchQueue.main.async {
                App.shared.snackbar.show(
                    error: GSError.error(description: "Could not sign transaction.", error: error))
            }
        }
    }

    convenience init(transaction: Transaction,
                     safe: Safe,
                     minimalNonce: UInt256String,
                     topic: String,
                     importedKeysForSafe: [Address]) {
        self.init()
        self.transaction = transaction
        self.safe = safe
        self.minimalNonce = minimalNonce
        self.session = try! Session.from(WCSession.get(topic: topic)!)
        self.importedKeysForSafe = importedKeysForSafe
    }

    // MARK: - ViewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if !session.dAppInfo.peerMeta.icons.isEmpty {
            let imageUrl = session.dAppInfo.peerMeta.icons[0]
            dappImageView.kf.setImage(with: imageUrl, placeholder: UIImage(named: "ico-empty-circle"))
        } else {
            dappImageView.image = UIImage(named: "ico-empty-circle")
        }
        dappNameLabel.text = session.dAppInfo.peerMeta.name
        dappNameLabel.setStyle(.headline)

        rejectButton.setText("Reject", .filledError)
        submitButton.setText("Submit", .filled)

        tableView.dataSource = self
        tableView.delegate = self

        tableView.registerCell(DetailTransferInfoCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(InfoCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(EditCell.self)

        tableView.estimatedRowHeight = BasicCell.rowHeight
        tableView.separatorStyle = .none

        buildSections()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.walletConnectIncomingTransaction, parameters: trackingParameters)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func buildSections() {
        let advancedSectionItems = !isAdvancedOptionsShown ? [] : [
            Section.Advanced.nonce(infoCell(title: "nonce", value: transaction.nonce.description)),
            Section.Advanced.safeTxGas(infoCell(title: "safeTxGas", value: transaction.safeTxGas.description)),
            Section.Advanced.edit(editCell())
        ]
        sections = [
            (section: .basic, items: [
                Section.Basic.safe(safeCell()),
                Section.Basic.transaction(transactionCell()),
                Section.Basic.data(dataCell()),
                Section.Basic.advanced(advancedCell())
            ]),
            (section: .advanced, items: advancedSectionItems)
        ]
    }

    private func reloadAdvancedSection() {
        buildSections()
        tableView.beginUpdates()
        tableView.reloadRows(at: [IndexPath(row: 3, section: 0)], with: .automatic)
        let advancedRows = [
            IndexPath(row: 0, section: 1), // nonce
            IndexPath(row: 1, section: 1), // safeTxGas
            IndexPath(row: 2, section: 1) // edit
        ]
        if isAdvancedOptionsShown {
            tableView.insertRows(at: advancedRows, with: .bottom)
        } else {
            tableView.deleteRows(at: advancedRows, with: .fade)
        }
        tableView.endUpdates()
    }

    private func safeCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        cell.setAccount(
            address: transaction.safe!.address,
            label: Safe.cachedName(by: transaction.safe!, networkId: safe.chain!.id!)
        )
        cell.selectionStyle = .none
        return cell
    }

    private func transactionCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailTransferInfoCell.self)

        let coin = safe.chain!.nativeCurrency!

        let decimalAmount = BigDecimal(
            Int256(transaction.value.value) * -1,
            Int(coin.decimals)
        )
        let amount = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ","
        )
        let tokenText = "\(amount) \(coin.symbol!)"
        let tokenDetail = amount == "0" ? "\(transaction.data?.data.count ?? 0) Bytes" : nil

        cell.setToken(text: tokenText, style: .secondary)
        cell.setToken(image: coin.logoUrl)
        cell.setDetail(tokenDetail)
        cell.setAddress(transaction.to.address, label: nil, imageUri: nil)
        cell.setOutgoing(true)
        cell.selectionStyle = .none

        return cell
    }

    private func dataCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailExpandableTextCell.self)
        let data = transaction.data?.description ?? ""
        cell.tableView = tableView
        cell.setTitle("data")
        cell.setText(data)
        cell.setCopyText(data)
        cell.setExpandableTitle("\(transaction.data?.data.count ?? 0) Bytes")
        cell.selectionStyle = .none
        return cell
    }

    private func advancedCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self)
        cell.setTitle("Advanced")
        let image = UIImage(systemName: isAdvancedOptionsShown ? "chevron.up" : "chevron.down")!
            .applyingSymbolConfiguration(.init(weight: .bold))!
        cell.setDisclosureImage(image)
        cell.setDisclosureImageTintColor(.secondaryLabel)
        cell.selectedBackgroundView = UIView()
        return cell
    }

    private func infoCell(title: String, value: String) -> UITableViewCell {
        let cell = tableView.dequeueCell(InfoCell.self)
        cell.setTitle(title)
        cell.setInfo(value)
        cell.selectionStyle = .none
        return cell
    }

    private func editCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(EditCell.self)
        cell.onEdit = { [unowned self] in
            self.showEditParameters()
        }
        cell.selectionStyle = .none
        return cell
    }

    private func showEditParameters() {
        let editParamsController = WCEditParametersViewController.create(nonce: transaction.nonce,
                                                                         minimalNonce: minimalNonce,
                                                                         safeTxGas: transaction.safeTxGas,
                                                                         trackingParameters: trackingParameters) {
            [unowned self] nonce, safeTxGas in
            self.transaction.nonce = nonce
            self.transaction.safeTxGas = safeTxGas
            self.transaction.updateSafeTxHash()
            self.buildSections()
            self.tableView.reloadData()
        }
        show(editParamsController, sender: self)
    }
}

extension WCTransactionConfirmationViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Basic.safe(let cell): return cell
        case Section.Basic.transaction(let cell): return cell
        case Section.Basic.data(let cell): return cell
        case Section.Basic.advanced(let cell): return cell
        case Section.Advanced.nonce(let cell): return cell
        case Section.Advanced.safeTxGas(let cell): return cell
        case Section.Advanced.edit(let cell): return cell
        default: return UITableViewCell()
        }
    }
}

extension WCTransactionConfirmationViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section].items[indexPath.row] {

        case Section.Basic.advanced(_):
            tableView.deselectRow(at: indexPath, animated: true)
            isAdvancedOptionsShown.toggle()
            reloadAdvancedSection()

        case Section.Advanced.edit(_):
            showEditParameters()

        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.Basic.advanced(_): return BasicCell.rowHeight
        default: return UITableView.automaticDimension
        }
    }
}
