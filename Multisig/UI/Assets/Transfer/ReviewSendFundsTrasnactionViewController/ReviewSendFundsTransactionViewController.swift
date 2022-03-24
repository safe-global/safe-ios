//
//  ReviewSendFundsTransactionViewController.swift
//  Multisig
//
//  Created by Moaaz on 12/23/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Version
import SwiftCryptoTokenFormatter

fileprivate protocol SectionItem {}

class ReviewSendFundsTransactionViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var retryButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var estimationFailedLabel: UILabel!
    @IBOutlet private weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var estimationFailedDescriptionLabel: UILabel!
    @IBOutlet private weak var estimationFailedView: UIView!
    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var confirmButtonView: ActivityButtonView!

    private var currentDataTask: URLSessionTask?
    var address: Address!
    var amount: BigDecimal!
    var formattedAmount: String {
        TokenFormatter().string(from: amount, shortFormat: false)
    }
    var safe: Safe!
    var tokenBalance: TokenBalance!
    var nonce: UInt256String!
    var safeTxGas: UInt256String?
    var minimalNonce: UInt256String?

    enum SectionItem {
        case trasnfer(UITableViewCell)
        case advanced(UITableViewCell)
    }

    private var sectionItems = [SectionItem]()

    convenience init(safe: Safe,
                     address: Address,
                     tokenBalance: TokenBalance,
                     amount: BigDecimal) {
        self.init(namedClass: ReviewSendFundsTransactionViewController.self)
        self.safe = safe
        self.address = address
        self.amount = amount
        self.tokenBalance = tokenBalance
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        assert(address != nil)
        assert(amount != nil)
        assert(safe != nil)
        assert(tokenBalance != nil)

        navigationItem.title = "Review"
        navigationItem.backButtonTitle = "Back"
        
        retryButton.setText("Retry", .filled)
        descriptionLabel.setStyle(.footnote2)

        tableView.registerCell(ReviewSendFundsTransactionHeaderTableViewCell.self)
        tableView.registerCell(EditAdvancedParametersUITableViewCell.self)

        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension

        loadData()
        confirmButtonView.state = .normal
        confirmButtonView.onClick = { [weak self] in
            guard let `self` = self else { return }
            let descriptionText = "An owner key will be used to confirm this transaction."
            let vc = ChooseOwnerKeyViewController(
                owners: KeyInfo.owners(safe: self.safe),
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

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        view.addGestureRecognizer(tapRecognizer)
    }

    @objc private func didTapBackground() {
        TooltipSource.hideAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.assetsTransferReview)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        TooltipSource.hideAll()
    }

    @IBAction func retryButtonTouched(_ sender: Any) {
        loadData()
    }

    private func loadData() {
        startLoading()
        currentDataTask?.cancel()
        currentDataTask = App.shared.clientGatewayService.asyncTransactionEstimation(chainId: safe.chain!.id!,
                                                                   safeAddress: safe.addressValue,
                                                                   to: address,
                                                                   value: 0,
                                                                   data: nil,
                                                                   operation: .call) { [weak self] result in
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

                DispatchQueue.main.async {
                    self.endLoading()
                    self.bindData()
                }
            }
        }
    }

    func showError(_ error: DetailedLocalizedError) {
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
        guard let transaction = Transaction(safe: safe,
                                            toAddress: address,
                                            tokenAddress: Address(stringLiteral: tokenBalance.address),
                                            amount: UInt256String(amount.value),
                                            safeTxGas: safeTxGas,
                                            nonce: nonce),
              let safeTxHash = transaction.safeTxHash?.description else {
            preconditionFailure("Unexpected Error")
        }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let signature = try SafeTransactionSigner().sign(transaction, keyInfo: keyInfo)
                confirm(transaction: transaction, keyInfo: keyInfo, signature: signature.hexadecimal)
            } catch {
                App.shared.snackbar.show(error: GSError.error(description: "Failed to confirm transaction", error: error))
            }

        case .walletConnect:
            let vc = SignatureRequestToWalletViewController(transaction, keyInfo: keyInfo, chain: safe.chain!)
            vc.onSuccess = { [weak self, weak vc] signature in
                vc?.dismiss(animated: true) {
                    self?.confirm(transaction: transaction, keyInfo: keyInfo, signature: signature)
                }
            }
            vc.onCancel = { [weak self, weak vc] in
                vc?.dismiss(animated: true) {
                    self?.endConfirm()
                }
            }
            presentModal(vc)

        case .ledgerNanoX:
            let request = SignRequest(title: "Confirm Transaction",
                                      tracking: ["action" : "confirm"],
                                      signer: keyInfo,
                                      hexToSign: safeTxHash)
            let vc = LedgerSignerViewController(request: request)

            presentModal(vc)

            vc.completion = { [weak self] signature in
                self?.confirm(transaction: transaction, keyInfo: keyInfo, signature: signature)
            }

            vc.onClose = { [weak self] in
                self?.endConfirm()
            }
        }
    }

    func presentModal(_ vc: UIViewController) {
        present(vc, animated: true) {
            TooltipSource.hideAll()
        }
    }

    private func confirm(transaction: Transaction, keyInfo: KeyInfo, signature: String) {
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
                        self.showTransactionSucess(transaction: transaction)
                    }
                }
            }
        }
    }

    private func bindData() {
        sectionItems = [SectionItem.trasnfer(trasnferCell()), SectionItem.advanced(parametersCell())]
        tableView.reloadData()
    }

    private func trasnferCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(ReviewSendFundsTransactionHeaderTableViewCell.self)
        let prefix = safe.chain!.shortName
        cell.setFromAddress(safe.addressValue, label: safe.name, prefix: prefix)
        let (name, imageURL) = NamingPolicy.name(for: address, info: nil, chainId: safe.chain!.id!)
        cell.setToAddress(address, label: name, imageUri: imageURL, prefix: prefix)
        cell.setToken(amount: formattedAmount,
                      symbol: tokenBalance.symbol,
                      fiatBalance:  "",
                      image: tokenBalance.imageURL)

        return cell
    }

    private func parametersCell() -> UITableViewCell {
        let cell = tableView.dequeueCell(EditAdvancedParametersUITableViewCell.self)
        cell.tableView = tableView
        cell.set(nonce: nonce.description)
        cell.set(safeTxGas: safeTxGas?.description)
        cell.onEdit = { [unowned self] in
            self.showEditParameters()
        }

        return cell
    }

    private func showEditParameters() {
        guard let nonce = nonce,
              let minimalNonce = minimalNonce else { return }


        let vc = AdvancedParametersViewController(nonce: nonce,
                                                  minimalNonce: minimalNonce.value,
                                                  safeTxGas: safeTxGas,
                                                  trackingEvent: .assetsTransferAdvancedParams) { [weak self] nonce, safeTxGas in
            guard let `self` = self else { return }
            self.nonce = nonce
            self.safeTxGas = safeTxGas
            self.bindData()
        }
        let ribbon = RibbonViewController(rootViewController: vc)

        presentModal(ViewControllerFactory.modal(viewController: ribbon))
    }
    
    private func showTransactionSucess(transaction: SCGModels.TransactionDetails) {
        let token = tokenBalance.symbol

        let title = "Your transaction is queued!"
        let body = "Your request to send \(formattedAmount) \(token) is submitted and needs to be confirmed by other owners."
        let done = "View details"

        let successVC = TransactionSuccessViewController(
            titleText: title,
            bodyText: body,
            doneTitle: done,
            trackingEvent: .assetsTransferSuccess)

        successVC.onDone = { [weak self] in
            guard let self = self else { return }

            
            self.dismiss(animated: true) {
                NotificationCenter.default.post(
                    name: .initiateTxNotificationReceived,
                    object: self,
                    userInfo: ["transactionDetails": transaction])
            }
        }

        show(successVC, sender: self)
    }
}

extension ReviewSendFundsTransactionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sectionItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sectionItems[indexPath.row]
        switch item {
        case SectionItem.trasnfer(let cell): return cell
        case SectionItem.advanced(let cell): return cell
        }
    }
}
