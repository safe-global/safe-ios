//
//  ReviewExecutionViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 11.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit
import Ethereum
import SwiftCryptoTokenFormatter
import SafeWeb3
import Solidity
import WalletConnectSwift
import SafariServices

class ReviewExecutionViewController: ContainerViewController, PasscodeProtecting {

    static let MIN_RELAY_TXS_LEFT = 0

    private var safe: Safe!
    private var chain: Chain!
    private var transaction: SCGModels.TransactionDetails!

    private var controller: TransactionExecutionController!

    private var onClose: () -> Void = { }

    var onSuccess: () -> Void = { }

    private var contentVC: ReviewExecutionContentViewController!

    @IBOutlet weak var ribbonView: RibbonView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var submitButton: ActivityButtonView!

    var closeButton: UIBarButtonItem!

    private var defaultKeyTask: URLSessionTask?
    private var txEstimationTask: URLSessionTask?
    private var sendingTask: URLSessionTask?
    private var relayingTask: URLSessionTask?
    private var remainingRelaysTask: URLSessionTask?
    private var userSelectedSigner = false
    
    private var keystoneSignFlow: KeystoneSignFlow!

    convenience init(safe: Safe,
                     chain: Chain,
                     transaction: SCGModels.TransactionDetails,
                     onClose: @escaping () -> Void,
                     onSuccess: @escaping () -> Void) {
        // create from the nib named as the self's class name
        self.init(namedClass: nil)
        self.safe = safe
        self.chain = chain
        self.transaction = transaction
        self.onClose = onClose
        self.onSuccess = onSuccess
        self.controller = TransactionExecutionController(safe: safe, chain: chain, transaction: transaction, relayerService: App.shared.relayService)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(safe != nil)
        assert(chain != nil)
        assert(transaction != nil)

        title = "Execute"
        navigationItem.backButtonTitle = "Back"
        
        // configure content
        contentVC = ReviewExecutionContentViewController(
            safe: safe,
            chain: chain,
            transaction: transaction)
        contentVC.onTapPaymentMethod = action(#selector(didTapPaymentMethod(_:)))
        contentVC.onTapAccount = action(#selector(didTapAccount(_:)))
        contentVC.onTapFee = action(#selector(didTapFee(_:)))
        contentVC.onTapAdvanced = action(#selector(didTapAdvanced(_:)))
        contentVC.model = ExecutionReviewUIModel(
            transaction: transaction,
            executionOptions: ExecutionOptionsUIModel(
                relayerState: .loading,
                accountState: .loading,
                feeState: .loading
            )
        )
        contentVC.onReload = action(#selector(didTriggerReload(_:)))
        self.viewControllers = [contentVC]
        self.displayChild(at: 0, in: contentView)


        // configure ribbon view
        ribbonView.update(chain: chain)

        // configure submit button
        submitButton.actionTitle = "Submit"
        submitButton.set(rejectionEnabled: false)
        if controller.isValid && (relayingTask?.state != .running && sendingTask?.state != .running) {
            submitButton.state = .normal
        } else {
            submitButton.state = .disabled
        }
        submitButton.onAction = { [weak self] in
            self?.didTapSubmit()
        }

        // configure close button
        closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose(_:)))

        navigationItem.leftBarButtonItem = closeButton

        estimateTransaction()
    }

    func action(_ selector: Selector) -> () -> Void {
        { [weak self] in
            self?.performSelector(onMainThread: selector, with: nil, waitUntilDone: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.reviewExecution)
    }

    @IBAction func didTriggerReload(_ sender: Any) {
        estimateTransaction()
    }

    @IBAction func didTapClose(_ sender: Any) {
        self.onClose()
    }

    @IBAction func didTapPaymentMethod(_ sender: Any) {
        // open payment method selection  
        let choosePaymentVC = ChoosePaymentViewController()
        choosePaymentVC.relaysRemaining = controller.relaysRemaining
        choosePaymentVC.relaysLimit = controller.relaysLimit
        choosePaymentVC.userSelectedSigner = userSelectedSigner
        choosePaymentVC.chooseRelay = { [unowned self] in
            LogService.shared.debug("User selected Relay")
            userSelectedSigner = false

            contentVC.userSelectedSigner = false
            contentVC.reloadData()
            estimateTransaction()
        }
        choosePaymentVC.chooseSigner = { [unowned self] in
            LogService.shared.debug("User selected Signer")
            userSelectedSigner = true
            contentVC.userSelectedSigner = true
            // trigger find key
            findDefaultKey()
            // key doesn't really change but is overlayed with the loading placeholder :-(
            didChangeSelectedKey()
            // refresh ui
            contentVC.reloadData()
        }
        let vc = ViewControllerFactory.pageSheet(viewController: choosePaymentVC, halfScreen: true)
        presentModal(vc)
    }

    @IBAction func didTapAccount(_ sender: Any) {
        let keys = controller.executionKeys()
        let balancesLoader = DefaultAccountBalanceLoader(chain: chain)

        if let tx = controller.ethTransaction {
            balancesLoader.requiredBalance = tx.requiredBalance
        }

        let keyPickerVC = ChooseOwnerKeyViewController(
            owners: keys,
            chainID: controller.chainId,
            titleText: "Select an execution key",
            header: .text(description: "The selected key will be used to execute this transaction."),
            requestsPasscode: false,
            selectedKey: controller.selectedKey?.key,
            balancesLoader: balancesLoader
        )
        keyPickerVC.trackingEvent = .reviewExecutionSelectKey

        // this way of returning the results from the view controller is just because
        // there was already existing code depending on the completion handler.
        // modified with minimum changes to the existing API.
        let completion: (KeyInfo?) -> Void = { [weak self, weak keyPickerVC] selectedKeyInfo in
            guard let self = self, let picker = keyPickerVC else { return }
            let balance = selectedKeyInfo.flatMap { picker.accountBalance(for: $0) }
            let previousKey = self.controller.selectedKey?.key
            // update selection
            if let key = selectedKeyInfo, let balance = balance {
                self.controller.selectedKey = (key, balance)
            } else {
                self.controller.selectedKey = nil
            }
            if selectedKeyInfo != previousKey {
                self.resetErrors()
                Tracker.trackEvent(.reviewExecutionSelectedKeyChanged)
                self.didChangeSelectedKey()
            }

            self.dismiss(animated: true)
        }
        keyPickerVC.completionHandler = completion

        let navigationController = UINavigationController(rootViewController: keyPickerVC)
        present(navigationController, animated: true)
    }

    @IBAction func didTapFee(_ sender: Any) {
        let formModel: FormModel
        var initialValues = UserDefinedTransactionParameters()

        switch controller.ethTransaction {
        case let ethTx as Eth.TransactionLegacy:
            let model = FeeLegacyFormModel(
                nonce: ethTx.nonce,
                minimalNonce: controller.minNonce,
                gas: ethTx.fee.gas,
                gasPriceInWei: ethTx.fee.gasPrice,
                nativeCurrency: chain.nativeCurrency!
            )
            initialValues.nonce = model.nonce
            initialValues.gas = model.gas
            initialValues.gasPrice = model.gasPriceInWei

            formModel = model

        case let ethTx as Eth.TransactionEip1559:
            let model = Fee1559FormModel(
                nonce: ethTx.nonce,
                minimalNonce: controller.minNonce,
                gas: ethTx.fee.gas,
                maxFeePerGasInWei: ethTx.fee.maxFeePerGas,
                maxPriorityFeePerGasInWei: ethTx.fee.maxPriorityFee,
                nativeCurrency: chain.nativeCurrency!
            )
            initialValues.nonce = model.nonce
            initialValues.gas = model.gas
            initialValues.maxFeePerGas = model.maxFeePerGasInWei
            initialValues.maxPriorityFee = model.maxPriorityFeePerGasInWei

            formModel = model

        default:
            if chain.features?.contains("EIP1559") == true {
                formModel = Fee1559FormModel(
                    nonce: nil,
                    gas: nil,
                    maxFeePerGasInWei: nil,
                    maxPriorityFeePerGasInWei: nil,
                    nativeCurrency: chain.nativeCurrency!
                )
            } else {
                formModel = FeeLegacyFormModel(
                    nonce: nil,
                    gas: nil,
                    gasPriceInWei: nil,
                    nativeCurrency: chain.nativeCurrency!
                )
            }
        }

        let formVC = FormViewController(model: formModel) { [weak self] in
            // on close - ignore any changes
            self?.dismiss(animated: true)
        }

        formVC.trackingEvent = .reviewExecutionEditFee

        formVC.onSave = { [weak self, weak formModel] in
            // on save - update the parameters that were changed.
            self?.dismiss(animated: true, completion: {
                guard let self = self, let formModel = formModel else { return }

                // collect the saved values

                var savedValues = UserDefinedTransactionParameters()

                switch formModel {
                case let model as FeeLegacyFormModel:
                    savedValues.nonce = model.nonce
                    savedValues.gas = model.gas
                    savedValues.gasPrice = model.gasPriceInWei

                case let model as Fee1559FormModel:
                    savedValues.nonce = model.nonce
                    savedValues.gas = model.gas
                    savedValues.maxFeePerGas = model.maxFeePerGasInWei
                    savedValues.maxPriorityFee = model.maxPriorityFeePerGasInWei

                default:
                    break
                }

                // compare the initial snapshot and saved snapshot
                // memberwise and remember only those values that changed.

                var changedFieldTrackingIds: [String] = []

                if savedValues.nonce != initialValues.nonce {
                    self.controller.userParameters.nonce = savedValues.nonce

                    changedFieldTrackingIds.append("nonce")
                }

                if savedValues.gas != initialValues.gas {
                    self.controller.userParameters.gas = savedValues.gas

                    changedFieldTrackingIds.append("gasLimit")
                }

                if savedValues.gasPrice != initialValues.gasPrice {
                    self.controller.userParameters.gasPrice = savedValues.gasPrice

                    changedFieldTrackingIds.append("gasPrice")
                }

                if savedValues.maxFeePerGas != initialValues.maxFeePerGas {
                    self.controller.userParameters.maxFeePerGas = savedValues.maxFeePerGas

                    changedFieldTrackingIds.append("maxFee")
                }

                if savedValues.maxPriorityFee != initialValues.maxPriorityFee {
                    self.controller.userParameters.maxPriorityFee = savedValues.maxPriorityFee

                    changedFieldTrackingIds.append("maxPriorityFee")
                }

                // react to changes

                if savedValues != initialValues {
                    self.resetErrors()
                    self.didChangeTransactionParameters()

                    let changedFields = changedFieldTrackingIds.joined(separator: ",")
                    Tracker.trackEvent(.reviewExecutionFieldEdited, parameters: ["fields": changedFields])
                }
            })
        }

        formVC.navigationItem.title = "Edit transaction fee"
        let ribbon = RibbonViewController(rootViewController: formVC)
        let nav = UINavigationController(rootViewController: ribbon)
        present(nav, animated: true, completion: nil)
    }

    @IBAction func didTapAdvanced(_ sender: Any) {
        let advancedVC = AdvancedTransactionDetailsViewController(transaction, chain: chain)
        let ribbon = RibbonViewController(rootViewController: advancedVC)
        advancedVC.trackingEvent = .reviewExecutionAdvanced
        show(ribbon, sender: self)
    }

    func didTapSubmit() {
        self.submitButton.state = .loading

        if AppConfiguration.FeatureToggles.securityCenter {
            self.sign()
        } else {
            authenticate(options: [.useForConfirmation]) { [weak self] success in
                guard let self = self else { return }
                if success {
                    if self.controller.relaysRemaining > ReviewExecutionViewController.MIN_RELAY_TXS_LEFT && !self.userSelectedSigner {
                        Tracker.trackEvent(.relayUserExecTxPaymentRelay)
                        // No need to sign when relaying
                        self.submit()
                    } else {
                        self.sign()
                    }
                }
            }
        }
    }

    func estimateTransaction() {
        txEstimationTask?.cancel()
        resetErrors()

        contentVC.model?.executionOptions.feeState = .loading

        let task = controller.estimate { [weak self] in
            guard let self = self else { return }
            self.didChangeEstimation()
            if self.chain.isSupported(feature: .relayingMobile) {
                self.getRemainingRelays()
            } else {
                self.didLoadPaymentData()
            }
        }

        txEstimationTask = task
    }

    func getRemainingRelays() {
        switch(contentVC.model?.executionOptions.relayerState) {
        case .loading, .filled:
            let task = controller.getRemainingRelays { [weak self] remaining, limit in
                guard let self = self else { return }
                self.didLoadPaymentData()
            }
            remainingRelaysTask = task
        default:
            controller.relaysRemaining = 0
            controller.relaysLimit = 0
            didLoadPaymentData()
        }
    }

    func didLoadPaymentData() {
        if controller.relaysRemaining > ReviewExecutionViewController.MIN_RELAY_TXS_LEFT && !self.userSelectedSigner && safe.chain!.isSupported(feature: .relayingMobile) {
            contentVC.model?.executionOptions.relayerState = .filled(RelayerInfoUIModel(remainingRelays: controller.relaysRemaining, limit: controller.relaysLimit))
        } else {
            // if we haven't search default
            if !didSearchDefaultKey && controller.selectedKey == nil {
                userSelectedSigner = true
                findDefaultKey()
            }
        }
        validate()
        contentVC.didEndReloading()
    }

    var didSearchDefaultKey: Bool = false

    func findDefaultKey() {
        resetErrors()
        defaultKeyTask?.cancel()

        self.contentVC.model?.executionOptions.accountState = .loading

        let previousKey = self.controller.selectedKey?.key

        let task = controller.findDefaultKey { [weak self] in
            guard let self = self else { return }
            self.didSearchDefaultKey = true
            if previousKey != self.controller.selectedKey?.key {
                self.didChangeSelectedKey()
            }
        }

        self.defaultKeyTask = task
    }

    func didChangeSelectedKey() {
        if let selection = controller.selectedKey {
            let model = MiniAccountInfoUIModel(
                prefix: self.chain.shortName,
                address: selection.key.address,
                label: selection.key.name,
                imageUri: nil,
                badge: selection.key.keyType.badgeName,
                balance: selection.balance.displayAmount
            )
            self.contentVC.model?.executionOptions.accountState = .filled(model)

            // re-estimate if the key changed.
            estimateTransaction()
        } else {
            contentVC.model?.executionOptions.accountState = .empty
        }

        validate()
    }

    func didChangeTransactionParameters() {
        didChangeEstimation()
    }

    func didChangeEstimation() {
        if let tx = controller.ethTransaction {

            let feeInWei = tx.totalFee

            let nativeCoinDecimals = chain.nativeCurrency!.decimals
            let nativeCoinSymbol = chain.nativeCurrency!.symbol!

            let decimalAmount = BigDecimal(Int256(feeInWei.big()), Int(nativeCoinDecimals))
            let value = TokenFormatter().string(
                from: decimalAmount,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: false
            )

            let tokenAmount: String = "\(value) \(nativeCoinSymbol)"

            let model = EstimatedFeeUIModel(
                tokenAmount: tokenAmount,
                fiatAmount: nil)

            contentVC.model?.executionOptions.feeState = .loaded(model)
        } else {
            contentVC.model?.executionOptions.feeState = .empty
        }
    }

    func resetErrors() {
        controller.errorMessage = nil
        contentVC?.model?.errorMessage = nil
    }

    func validate() {
        controller.validate()
        contentVC?.model?.errorMessage = controller.errorMessage
        if controller.isValid {
            submitButton.state = .normal
        } else {
            submitButton.state = .disabled
        }
    }

    func sign() {
        guard let keyInfo = controller.selectedKey?.key else {
            return
        }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated, .web3AuthApple, .web3AuthGoogle:
            do {
                let txHash = controller.hashForSigning()

                guard let pk = try keyInfo.privateKey() else {
                    App.shared.snackbar.show(message: "Private key not available")
                    return
                }
                let signature = try pk._store.sign(hash: Array(txHash))

                try controller.update(signature: signature)
            } catch {
                let gsError = GSError.error(description: "Signing failed", error: error)
                App.shared.snackbar.show(error: gsError)
                return
            }
            submit()

        case .walletConnect:
            guard let clientTx = controller.walletConnectTransaction() else {
                let gsError = GSError.error(description: "Unsupported transaction type")
                App.shared.snackbar.show(error: gsError)
                return
            }

            let sendTxVC = SendTransactionToWalletViewController(
                transaction: clientTx,
                keyInfo: keyInfo,
                chain: chain
            )

            sendTxVC.onSuccess = { [weak self] txHashData in
                guard let self = self else { return }
                self.controller.didSubmitTransaction(txHash: Eth.Hash(txHashData))
                self.didSubmitSuccess()
            }

            let vc = ViewControllerFactory.pageSheet(viewController: sendTxVC, halfScreen: true)
            present(vc, animated: true)

        case .ledgerNanoX:
            let rawTransaction = controller.preimageForSigning()
            let chainId = controller.intChainId
            let isLegacy = controller.isLegacyTx

            let request = SignRequest(title: "Sign Transaction",
                                      tracking: ["action" : "signTx"],
                                      signer: keyInfo,
                                      payload: .rawTx(data: rawTransaction, chainId: chainId, isLegacy: isLegacy))

            let vc = LedgerSignerViewController(request: request)

            vc.txCompletion = { [weak self] signature in
                guard let self = self else { return }

                do {
                    try self.controller.update(signature: (UInt(signature.v), Array(signature.r), Array(signature.s)))
                } catch {
                    let gsError = GSError.error(description: "Signing failed", error: error)
                    App.shared.snackbar.show(error: gsError)
                    return
                }

                self.submit()
            }

            present(vc, animated: true, completion: nil)
            
        case .keystone:
            let isLegacy = controller.isLegacyTx
            
            let signInfo = KeystoneSignInfo(
                signData: controller.preimageForSigning().toHexString(),
                chain: chain,
                keyInfo: keyInfo,
                signType: isLegacy ? .transaction : .typedTransaction
            )
            let signCompletion = { [unowned self] (success: Bool) in
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                }
                keystoneSignFlow = nil
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                return
            }
            
            keystoneSignFlow = signFlow
            keystoneSignFlow.signCompletion = { [weak self] unmarshaledSignature in
                do {
                    try self?.controller.update(signature: (UInt(unmarshaledSignature.v), Array(unmarshaledSignature.r), Array(unmarshaledSignature.s)))
                    self?.submit()
                } catch {
                    App.shared.snackbar.show(error: GSError.error(description: "Signing failed", error: error))
                }
            }
            present(flow: keystoneSignFlow)
        }
    }

    func submit() {
        sendingTask?.cancel()
        relayingTask?.cancel()

        if controller.relaysRemaining > ReviewExecutionViewController.MIN_RELAY_TXS_LEFT && !self.userSelectedSigner {
            relayingTask = controller.relay(completion: { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    self.submitButton.state = .normal
                    Tracker.trackEvent(.relayUserFailure)
                    self.didSubmitFailed(error)

                case .success:
                    Tracker.trackEvent(.relayUserSuccess)
                    self.didSubmitSuccess()
                }
            })
        } else {
            sendingTask = controller.send(completion: { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    self.submitButton.state = .normal
                    Tracker.trackEvent(.executeFailure, parameters: [
                        "chain_id": self.controller.chainId
                    ])
                    self.didSubmitFailed(error)

                case .success:
                    self.didSubmitSuccess()
                }
            })
        }
    }

    func didSubmitFailed(_ error: Error?) {
        let gsError = GSError.error(description: "Submitting failed", error: error)
        App.shared.snackbar.show(error: gsError)
    }

    func didSubmitSuccess() {
        let txHash = self.controller.ethTransaction?.hash ?? .init()
        LogService.shared.debug("Submitted tx: \(txHash.storage.storage.toHexStringWithPrefix())")
        Tracker.trackEvent(.userTransactionExecuteSubmitted)

        let successVC = SuccessViewController(
            titleText: "Your transaction is submitted!",
            bodyText: "It normally takes some time for a transaction to be executed.",
            primaryAction: "View transaction details",
            secondaryAction: nil
        )

        var trackingEvent: TrackingEvent? = nil
        var trackingParameters: [String: Any]? = nil
        if let key = self.controller.selectedKey?.key {
            trackingEvent = .successTxSigner
            // track key type
            trackingParameters = TrackingEvent.keyTypeParameters(key, parameters: ["source": "tx_details"])
        } else if !userSelectedSigner {
            trackingEvent = .successTxRelay
        }
        successVC.setTrackingData(trackingEvent: trackingEvent, trackingParams: trackingParameters)

        successVC.onDone = { [weak self] _ in
            guard let self = self else { return }
            self.onSuccess()
        }

        self.show(successVC, sender: self)
    }

    func presentModal(_ vc: UIViewController) {
        present(vc, animated: true) {
            TooltipSource.hideAll()
        }
    }
}
