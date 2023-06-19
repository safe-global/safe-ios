//
//  ReviewSafeTransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 4/25/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Version
import SwiftCryptoTokenFormatter

fileprivate protocol SectionItem {}

class ReviewSafeTransactionViewController: UIViewController {
    @IBOutlet internal weak var tableView: UITableView!
    @IBOutlet private weak var retryButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var estimationFailedLabel: UILabel!
    @IBOutlet private weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var estimationFailedDescriptionLabel: UILabel!
    @IBOutlet private weak var estimationFailedView: UIView!
    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet weak var confirmButtonView: ActivityButtonView!
    @IBOutlet weak var ribbonView: RibbonView!

    private var currentDataTask: URLSessionTask?
    private var keystoneSignFlow: KeystoneSignFlow!
    var trackingEvent: TrackingEvent = .assetsTransferReview

    var safe: Safe!
    var nonce: UInt256String?
    var safeTxGas: UInt256String?
    var minimalNonce: UInt256String?

    var transactionPreview: SCGModels.TrasactionPreview?
    var shouldLoadTransactionPreview: Bool = false

    enum SectionItem {
        case header(UITableViewCell)
        case safeInfo(UITableViewCell)
        case valueChange(UITableViewCell)
        case data(UITableViewCell)
        case transactionType(UITableViewCell)
        case advanced(UITableViewCell)
    }

    var sectionItems = [SectionItem]()

    convenience init(safe: Safe) {
        self.init(namedClass: ReviewSafeTransactionViewController.self)
        self.safe = safe
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(safe != nil)

        navigationItem.title = "Review"
        navigationItem.backButtonTitle = "Back"


        retryButton.setText("Retry", .filled)
        descriptionLabel.setStyle(.footnote)

        tableView.registerCell(BorderedInnerTableCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(ValueChangeTableViewCell.self)
        tableView.registerCell(DetailExpandableTextCell.self)

        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.tableFooterView = UIView()

        ribbonView.update(chain: safe.chain)
        loadData()

        confirmButtonView.actionTitle = "Submit"
        confirmButtonView.state = .normal
        confirmButtonView.set(rejectionEnabled: false)
        
        confirmButtonView.onAction = { [weak self] in
            self?.didConfirm()
        }
    }

    func didConfirm() {
        let keys = KeyInfo.owners(safe: self.safe)
        if keys.isEmpty {
            let addOwnerVC = AddOwnerFirstViewController()
            addOwnerVC.onSuccess = { [weak self] in
                self?.dismiss(animated: true) {
                    guard let self = self else { return }
                    // check if we actually added an owner and not some irrelevant key
                    guard !KeyInfo.owners(safe: self.safe).isEmpty else { return }
                    self.didConfirm()
                }
            }
            let nav = ViewControllerFactory.modal(viewController: addOwnerVC)
            presentModal(nav)
            return
        }

        let descriptionText = "An owner key will be used to confirm this transaction."
        let vc = ChooseOwnerKeyViewController(
            owners: keys,
            chainID: self.safe.chain!.id,
            header: .text(description: descriptionText)
        ) { [weak self] keyInfo in
            guard let `self` = self else { return }
            self.dismiss(animated: true) {
                if let info = keyInfo {
                    self.startConfirm()
                    self.sign(info)
                }
            }
        }

        let navigationController = UINavigationController(rootViewController: vc)
        self.presentModal(navigationController)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TooltipSource.hideAll()
    }

    @IBAction func retryButtonTouched(_ sender: Any) {
        loadData()
    }

    private func loadData() {
        guard
            let tx = createTransaction(),
            let chainId = tx.chainId,
            let safeAddress = tx.safe?.address
        else { return }

        startLoading()
        currentDataTask?.cancel()

        currentDataTask = App.shared.clientGatewayService.asyncTransactionEstimation(
            chainId: chainId,
            safeAddress: safeAddress,
            to: tx.to.address,
            value: tx.value.value,
            data: tx.data?.data,
            operation: tx.operation
        ) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .failure(let error):
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    if (error as NSError).code == URLError.cancelled.rawValue &&
                        (error as NSError).domain == NSURLErrorDomain {
                        return
                    }
                    self.showError(GSError.error(description: "Failed to create transaction", error: error))
                }
            case .success(let estimationResult):
                self.minimalNonce = estimationResult.currentNonce
                self.nonce = estimationResult.recommendedNonce

                if let contractVersion = self.safe.contractVersion,
                   let version = Version(contractVersion),
                   version >= Version(1, 3, 0) {
                    self.safeTxGas = nil
                } else if let estimatedSafeTxGas = UInt256(estimationResult.safeTxGas) {
                    self.safeTxGas = UInt256String(estimatedSafeTxGas)
                }

                if self.shouldLoadTransactionPreview, let transaction = self.createTransaction() {
                    self.transactionPreview = nil

                    self.currentDataTask = App.shared.clientGatewayService.asyncPreviewTransaction(
                        transaction: transaction,
                        sender: AddressString(self.safe.addressValue),
                        chainId: self.safe.chain!.id!
                    ) { result in
                        DispatchQueue.main.async {
                            switch result {
                            case .success(let response):
                                self.transactionPreview = response
                                self.onSuccess()
                            case .failure(let error):
                                if (error as NSError).code == URLError.cancelled.rawValue &&
                                    (error as NSError).domain == NSURLErrorDomain {
                                    return
                                }
                                self.showError(GSError.error(description: "Failed to create transaction", error: error))
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.onSuccess()
                    }
                }
            }
        }
    }

    private func onSuccess() {
        DispatchQueue.main.async {
            self.endLoading()
            self.bindData()
        }
    }

    private func showError(_ error: DetailedLocalizedError) {
        App.shared.snackbar.show(error: error)
        loadingActivityIndicator.isHidden = true
        loadingActivityIndicator.stopAnimating()
        contentContainerView.isHidden = true
        estimationFailedView.isHidden = false
    }

    private func startLoading() {
        loadingActivityIndicator.isHidden = false
        loadingActivityIndicator.startAnimating()
        contentContainerView.isHidden = true
    }

    private func endLoading() {
        loadingActivityIndicator.isHidden = true
        loadingActivityIndicator.stopAnimating()
        contentContainerView.isHidden = false
    }

    private func startConfirm() {
        self.confirmButtonView.state = .loading
    }

    private func endConfirm() {
        self.confirmButtonView.state = .normal
    }

    private func sign(_ keyInfo: KeyInfo) {
        guard let transaction = createTransaction(),
              let safeTxHash = transaction.safeTxHash?.description else {
            preconditionFailure("Unexpected Error")
        }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated, .web3AuthApple, .web3AuthGoogle:
            Wallet.shared.sign(transaction, keyInfo: keyInfo) { [unowned self] result in
                do {
                    let signature = try result.get()
                    proposeTransaction(transaction: transaction, keyInfo: keyInfo, signature: signature.hexadecimal)

                } catch {
                    App.shared.snackbar.show(error: GSError.error(description: "Failed to confirm transaction",
                                                                  error: error))
                    endConfirm()
                }
            }

        case .walletConnect:
            let signVC = SignatureRequestToWalletViewController(transaction, keyInfo: keyInfo, chain: safe.chain!)
            signVC.onSuccess = { [weak self] signature in
                self?.proposeTransaction(transaction: transaction, keyInfo: keyInfo, signature: signature)
            }
            signVC.onCancel = { [weak self] in
                self?.endConfirm()
            }
            let vc = ViewControllerFactory.pageSheet(viewController: signVC, halfScreen: true)
            presentModal(vc)

        case .ledgerNanoX:
            let request = SignRequest(title: "Confirm Transaction",
                                      tracking: ["action" : "confirm"],
                                      signer: keyInfo,
                                      hexToSign: safeTxHash)
            let vc = LedgerSignerViewController(request: request)

            presentModal(vc)

            vc.completion = { [weak self] signature in
                self?.proposeTransaction(transaction: transaction, keyInfo: keyInfo, signature: signature)
            }

            vc.onClose = { [weak self] in
                self?.endConfirm()
            }
            
        case .keystone:
            let signInfo = KeystoneSignInfo(
                signData: transaction.safeTxHash.hash.toHexString(),
                chain: safe.chain,
                keyInfo: keyInfo,
                signType: .personalMessage
            )
            let signCompletion = { [unowned self] (success: Bool) in
                keystoneSignFlow = nil
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                    endConfirm()
                }
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                endConfirm()
                return
            }
            
            keystoneSignFlow = signFlow
            keystoneSignFlow.signCompletion = { [weak self] unmarshaledSignature in
                self?.proposeTransaction(transaction: transaction, keyInfo: keyInfo, signature: unmarshaledSignature.safeSignature)
            }
            present(flow: keystoneSignFlow)
        }
    }

    func presentModal(_ vc: UIViewController) {
        present(vc, animated: true) {
            TooltipSource.hideAll()
        }
    }

    func createTransaction() -> Transaction? {
        nil
    }

    private func proposeTransaction(transaction: Transaction, keyInfo: KeyInfo, signature: String) {
        currentDataTask = App.shared.clientGatewayService.asyncProposeTransaction(transaction: transaction,
                                                                                  sender: AddressString(keyInfo.address),
                                                                                  signature: signature,
                                                                                  chainId: safe.chain!.id!) { result in
            // NOTE: sometimes the data of the transaction list is not
            // updated right away, we'll give a moment for the backend
            // to catch up before finishing with this request.
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.endConfirm()
                    switch result {
                    case .failure(let error):
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            return
                        }
                        App.shared.snackbar.show(error: GSError.error(description: "Failed to create transaction", error: error))
                    case .success(let transaction):
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                        self.onSuccess(transaction: transaction)
                    }
                }
            }
        }
    }

    func bindData() {
        createSections()
        tableView.reloadData()
    }

    func createSections() {
        sectionItems = [SectionItem.header(headerCell()), SectionItem.advanced(parametersCell())]
    }

    func headerCell() -> UITableViewCell {
        assertionFailure()
        return UITableViewCell()
    }

    func safeInfoCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self)
        cell.setAccount(address: safe.addressValue,
                        label: safe.name,
                        title: "Safe Account details",
                        copyEnabled: false,
                        browseURL: nil,
                        prefix: safe.chain!.shortName,
                        titleStyle: .headlineSecondary)
        cell.selectionStyle = .none
        return cell
    }

    func parametersCell() -> UITableViewCell {
        let tableCell = tableView.dequeueCell(BorderedInnerTableCell.self)

        tableCell.selectionStyle = .none
        tableCell.verticalSpacing = 16

        tableCell.tableView.registerCell(DisclosureWithContentCell.self)

        let cell = tableCell.tableView.dequeueCell(DisclosureWithContentCell.self)
        cell.setText("Advanced parameters")
        cell.selectionStyle = .none
        cell.setContent(nil)

        tableCell.setCells([cell])
        tableCell.onCellTap = { [unowned self] _ in
            Tracker.trackEvent(.userClaimReviewPar)
            self.showEditParameters()
        }

        return tableCell
    }

    func dataCell() -> UITableViewCell {
        guard let transaction = createTransaction() else { return UITableViewCell() }

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

    private func showEditParameters() {
        guard let nonce = nonce,
              let minimalNonce = minimalNonce else { return }

        let vc = AdvancedParametersViewController(nonce: nonce,
                                                  minimalNonce: minimalNonce.value,
                                                  safeTxGas: safeTxGas,
                                                  trackingEvent: getTrackingEvent()) { [weak self] nonce, safeTxGas in
            guard let `self` = self else { return }
            self.nonce = nonce
            self.safeTxGas = safeTxGas
            self.bindData()
        }
        let ribbon = RibbonViewController(rootViewController: vc)

        presentModal(ViewControllerFactory.modal(viewController: ribbon))
    }

    // Please override in subclasses
    func getTrackingEvent() -> TrackingEvent {
        .assetsTransferAdvancedParams
    }

    func onSuccess(transaction: SCGModels.TransactionDetails) {
        
    }
}

extension ReviewSafeTransactionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sectionItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sectionItems[indexPath.row]
        switch item {
        case SectionItem.header(let cell): return cell
        case SectionItem.safeInfo(let cell): return cell
        case SectionItem.advanced(let cell): return cell
        case SectionItem.valueChange(let cell): return cell
        case SectionItem.data(let cell): return cell
        default: return UITableViewCell()
        }
    }
}
