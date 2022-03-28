//
//  WCIncomingTransactionRequestViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift
import Kingfisher
import SwiftCryptoTokenFormatter
import Version

fileprivate protocol SectionItem {}

class WCIncomingTransactionRequestViewController: UIViewController {
    @IBOutlet private weak var dappImageView: UIImageView!
    @IBOutlet private weak var dappNameLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var rejectButton: UIButton!
    @IBOutlet private weak var submitButton: UIButton!

    var onReject: (() -> Void)?
    var onSubmit: ((_ nonce: UInt256String, _ safeTxHash: HashString) -> Void)?

    private var transaction: Transaction!
    private var safe: Safe!
    private var keyInfo: KeyInfo?
    private var minimalNonce: UInt256!
    private var session: Session!
    private var importedKeysForSafe: [Address]!
    private var ledgerController: LedgerController?
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
        let vc = ChooseOwnerKeyViewController(
            owners: owners,
            chainID: safe.chain!.id,
            header: .text(description: descriptionText)
        ) {
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
        self.keyInfo = keyInfo

        switch keyInfo.keyType {

        case .deviceImported, .deviceGenerated:
            DispatchQueue.global().async { [unowned self] in
                do {
                    let signature = try SafeTransactionSigner().sign(transaction, keyInfo: keyInfo)
                    self.sendConfirmationAndDismiss(signature: signature.hexadecimal,
                                                    trackingEvent: .incomingTxConfirmed)
                } catch {
                    DispatchQueue.main.async {
                        App.shared.snackbar.show(
                            error: GSError.error(description: "Could not sign transaction.", error: error))
                    }
                }
            }

        case .walletConnect:
            signWithWalletConnect(transaction, keyInfo: keyInfo)

        case .ledgerNanoX:
            let request = SignRequest(title: "Confirm Incoming Transaction",
                                      tracking: ["action" : "wc_incoming_confirm"],
                                      signer: keyInfo,
                                      hexToSign: transaction.safeTxHash.description)
            let vc = LedgerSignerViewController(request: request)
            present(vc, animated: true, completion: nil)

            vc.completion = { [weak self] signature in
                DispatchQueue.global().async {
                    self?.sendConfirmationAndDismiss(signature: signature, trackingEvent: .incomingTxConfirmedLedger)
                }
            }
        }
    }

    private func signWithWalletConnect(_ transaction: Transaction, keyInfo: KeyInfo) {
        guard presentedViewController == nil else { return }
        
        let vc = SignatureRequestToWalletViewController(transaction, keyInfo: keyInfo, chain: safe.chain!)
        vc.onSuccess = { [weak self, weak vc] signature in
            vc?.dismiss(animated: true) {
                DispatchQueue.global().async {
                    let connection = WebConnectionController.shared.walletConnection(keyInfo: keyInfo).first
                    let walletName = connection?.remotePeer?.name ?? "Unknown"
                    self?.sendConfirmationAndDismiss(
                        signature: signature,
                        trackingEvent: .incomingTxConfirmedWalletConnect,
                        trackingParameters: Tracker.parametersWithWalletName(walletName, parameters: self?.trackingParameters)
                    )
                }
            }
        }
        vc.onCancel = { [weak vc] in
            vc?.dismiss(animated: true)
        }
        present(vc, animated: true)
    }

    private func sendConfirmationAndDismiss(signature: String, trackingEvent: TrackingEvent, trackingParameters: [String: Any]? = nil) {
        guard let keyInfo = keyInfo else { return }

        DispatchQueue.main.async { [weak self] in
            // block buttons
            self?.submitButton.isEnabled = false
            self?.rejectButton.isEnabled = false
        }

        do {
            try App.shared.clientGatewayService.proposeTransaction(transaction: transaction,
                                                                   sender: AddressString(keyInfo.address),
                                                                   signature: signature,
                                                                   chainId: safe.chain!.id!)
            Tracker.trackEvent(trackingEvent, parameters: trackingParameters)

            DispatchQueue.main.async { [weak self] in
                // dismiss WCTransactionConfirmationViewController
                self?.dismiss(animated: true, completion: nil)
                App.shared.snackbar.show(message: "The transaction is submitted and can be confirmed by other owners.")
            }

            onSubmit?(transaction.nonce, transaction.safeTxHash)
        } catch {
            DispatchQueue.main.async { [weak self] in
                // unblock buttons
                self?.submitButton.isEnabled = true
                self?.rejectButton.isEnabled = true

                App.shared.snackbar.show(
                    error: GSError.error(description: "Could not sign transaction.", error: error))
            }
        }
    }

    convenience init(transaction: Transaction,
                     safe: Safe,
                     topic: String,
                     importedKeysForSafe: [Address]) {
        self.init()
        self.transaction = transaction
        self.safe = safe
        self.minimalNonce = safe.nonce!
        self.session = try! Session.from(WCSession.get(topic: topic)!)
        self.importedKeysForSafe = importedKeysForSafe
    }

    // MARK: - ViewController life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = nil

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
        var advancedSectionItems = [SectionItem]()
        if isAdvancedOptionsShown {
            advancedSectionItems.append(
                Section.Advanced.nonce(infoCell(title: "Safe nonce", value: transaction.nonce.description))
            )

            let version = Version(safe.contractVersion!)!
            if version < Version(1, 3, 0) {
                advancedSectionItems.append(
                    Section.Advanced.safeTxGas(infoCell(title: "SafeTxGas", value: transaction.safeTxGas.description))
                )
            }

            advancedSectionItems.append(
                Section.Advanced.edit(editCell())
            )
        }
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

        var advancedRows = [IndexPath]()
        let version = Version(safe.contractVersion!)!
        let advancedRowsCount = version < Version(1, 3, 0) ? 3 : 2

        for index in 0..<advancedRowsCount {
            advancedRows.append(IndexPath(row: index, section: 1))
        }

        if isAdvancedOptionsShown {
            tableView.insertRows(at: advancedRows, with: .bottom)
        } else {
            tableView.deleteRows(at: advancedRows, with: .fade)
        }
        tableView.endUpdates()
    }

    private func safeCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        let chain = safe.chain!
        let address = transaction.safe!.address
        cell.setAccount(
            address: address,
            label: Safe.cachedName(by: transaction.safe!, chainId: safe.chain!.id!),
            title: "Connected safe",
            browseURL: chain.browserURL(address: address.checksummed),
            prefix: chain.shortName
        )
        cell.selectionStyle = .none
        return cell
    }

    private func transactionCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailTransferInfoCell.self)
        let chain = safe.chain!

        let coin = chain.nativeCurrency!
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
        let (addressName, _) = NamingPolicy.name(for: transaction.to.address,
                                                    info: nil,
                                                    chainId: safe.chain!.id!)

        cell.setToken(text: tokenText, style: .secondary)
        cell.setToken(image: coin.logoUrl)
        cell.setDetail(tokenDetail)

        cell.setAddress(transaction.to.address,
                        label: addressName,
                        imageUri: nil,
                        browseURL: chain.browserURL(address: transaction.to.address.checksummed),
                        prefix: chain.shortName)
        cell.setOutgoing(true)
        cell.selectionStyle = .none

        return cell
    }

    private func dataCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailExpandableTextCell.self)
        let data = transaction.data?.description ?? ""
        cell.tableView = tableView
        cell.setTitle("Data")
        cell.setText(data)
        cell.setCopyText(data)
        cell.setExpandableTitle("\(transaction.data?.data.count ?? 0) Bytes")
        cell.selectionStyle = .none
        return cell
    }

    private func advancedCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self)
        cell.setTitle("Advanced")
        cell.setIcon(nil)
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
        let safeTxGas = transaction.safeVersion! >= Version(1, 3, 0) ? nil : transaction.safeTxGas
        let editParamsController = AdvancedParametersViewController(nonce: transaction.nonce,
                                                                    minimalNonce: minimalNonce,
                                                                    safeTxGas: safeTxGas,
                                                                    trackingEvent: .walletConnectEditParameters) {
            [unowned self] nonce, safeTxGas in
            self.transaction.nonce = nonce
            if let safeTxGas = safeTxGas {
                self.transaction.safeTxGas = safeTxGas
            }
            self.transaction.updateSafeTxHash()
            self.buildSections()
            self.tableView.reloadData()
        }
        let navController = UINavigationController(rootViewController: editParamsController)
        present(navController, animated: true, completion: nil)
    }
}

extension WCIncomingTransactionRequestViewController: UITableViewDataSource {
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

extension WCIncomingTransactionRequestViewController: UITableViewDelegate {
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
