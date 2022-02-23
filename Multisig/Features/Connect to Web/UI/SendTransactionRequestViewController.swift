//
// Created by Dmitry Bespalov on 18.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit
import Ethereum
import Solidity
import WalletConnectSwift
import JsonRpc2

class SendTransactionRequestViewController: WebConnectionContainerViewController, WebConnectionRequestObserver {

    var controller: WebConnectionController!
    var connection: WebConnection!
    var request: WebConnectionSendTransactionRequest!

    private var transaction: EthTransaction!

    private var contentVC: SendTransactionContentViewController!
    private var balanceLoader: DefaultAccountBalanceLoader!
    private var estimationController: TransactionEstimationController!
    private var wcConnector: WCWalletConnectionController!

    private var fee: UInt256?
    private var balance: UInt256?
    private var error: Error?
    private var minNonce: Sol.UInt64 = 0
    private var userParameters = UserDefinedTransactionParameters()
    private var chain: Chain!
    private var keyInfo: KeyInfo!

    convenience init() {
        self.init(namedClass: WebConnectionContainerViewController.self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Execute Transaction Request"

        chain = controller.chain(for: request)!
        keyInfo = try! KeyInfo.firstKey(address: connection.accounts.first!)

        transaction = request.transaction

        balanceLoader = DefaultAccountBalanceLoader(chain: chain)
        let rpcUri = chain.authenticatedRpcUrl.absoluteString
        estimationController = TransactionEstimationController(rpcUri: rpcUri, chain: chain)

        ribbonView.update(chain: chain)

        if let peer = connection.remotePeer {
            headerView.textLabel.text = peer.name
            headerView.detailTextLabel.text = peer.url.host
            let placeholder = UIImage(named: "connection-placeholder")
            headerView.imageView.setImage(url: peer.icons.first, placeholder: placeholder, failedImage: placeholder)
        } else {
            headerView.isHidden = true
        }

        actionPanelView.setConfirmText("Submit")

        controller.attach(observer: self, to: request)

        contentVC = SendTransactionContentViewController()
        viewControllers = [contentVC]
        displayChild(at: 0, in: contentView)

        contentVC.onTapFee = { [unowned self] in
            openFeeEditor()
        }

        reloadData()
        loadBalance()
        estimate()
    }

    deinit {
        controller.detach(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.trackEvent(.webConnectionSendRequest)
    }

    func didUpdate(request: WebConnectionRequest) {
        if request.status == .success || request.status == .failed {
            onFinish()
        }
    }

    override func didCancel() {
        didReject()
    }

    override func didReject() {
        controller.respond(request: request, errorCode: WebConnectionRequest.ErrorCode.requestRejected.rawValue, message: "User rejected to send transaction.")
        Tracker.trackEvent(.webConnectionSendRequestRejected)
    }

    override func didConfirm() {
        userDidSubmit()
        Tracker.trackEvent(.webConnectionSendRequestConfirmed,
                           parameters: TrackingEvent.keyTypeParameters(keyInfo))
    }

    func reloadData() {
        fee = transaction.totalFee.big()
        contentVC.reloadData(transaction: transaction,
                             keyInfo: keyInfo,
                             chain: chain,
                             balance: balance,
                             fee: fee,
                             error: error?.localizedDescription)
    }

    // load balance for the selected account.
    func loadBalance() {
        guard let keyInfo = try? KeyInfo.firstKey(address: connection.accounts.first!) else { return }
        _ = balanceLoader.loadBalances(for: [keyInfo]) { [weak self] result in
            guard let self = self else { return }
            do {
                let model = try result.get()
                self.balance = model.first?.amount?.big()
                self.reloadData()
            } catch {
                LogService.shared.error("Failed to load balance: \(error)")
            }
        }
    }

    func estimate() {
        self.error = nil
        _ = estimationController.estimateTransactionWithRpc(tx: transaction) { [weak self] result in
            guard let self = self else { return }
            do {
                let results = try result.get()

                let gas = try results.gas.get()
                let _ = try results.ethCall.get()
                let gasPrice = try results.gasPrice.get()
                let txCount = try results.transactionCount.get()
                self.minNonce = txCount
                self.transaction.update(gas: gas, transactionCount: txCount, baseFee: gasPrice)
            } catch {
                LogService.shared.error("Error estimating transaction: \(error)")
                self.error = error
            }
            self.updateEthTransactionWithUserValues()
            self.reloadData()
        }
    }

    // modifying estimation - copy from the review execution (form)
    func openFeeEditor() {
        let formModel: FormModel
        var initialValues = UserDefinedTransactionParameters()

        switch transaction {
        case let ethTx as Eth.TransactionLegacy:
            let model = FeeLegacyFormModel(
                nonce: ethTx.nonce,
                minimalNonce: minNonce,
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
                minimalNonce: minNonce,
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
                    self.userParameters.nonce = savedValues.nonce

                    changedFieldTrackingIds.append("nonce")
                }

                if savedValues.gas != initialValues.gas {
                    self.userParameters.gas = savedValues.gas

                    changedFieldTrackingIds.append("gasLimit")
                }

                if savedValues.gasPrice != initialValues.gasPrice {
                    self.userParameters.gasPrice = savedValues.gasPrice

                    changedFieldTrackingIds.append("gasPrice")
                }

                if savedValues.maxFeePerGas != initialValues.maxFeePerGas {
                    self.userParameters.maxFeePerGas = savedValues.maxFeePerGas

                    changedFieldTrackingIds.append("maxFee")
                }

                if savedValues.maxPriorityFee != initialValues.maxPriorityFee {
                    self.userParameters.maxPriorityFee = savedValues.maxPriorityFee

                    changedFieldTrackingIds.append("maxPriorityFee")
                }

                // react to changes

                if savedValues != initialValues {
                    self.error = nil
                    self.updateEthTransactionWithUserValues()
                    self.estimate()

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

    func updateEthTransactionWithUserValues() {
        // take the values only if they were set by user (not nil)
        switch transaction {
        case var ethTx as Eth.TransactionLegacy:
            ethTx.fee.gas = userParameters.gas ?? ethTx.fee.gas
            ethTx.fee.gasPrice = userParameters.gasPrice ?? ethTx.fee.gasPrice
            ethTx.nonce = userParameters.nonce ?? ethTx.nonce

            self.transaction = ethTx
            reloadData()

        case var ethTx as Eth.TransactionEip1559:
            ethTx.fee.gas = userParameters.gas ?? ethTx.fee.gas
            ethTx.fee.maxFeePerGas = userParameters.maxFeePerGas ?? ethTx.fee.maxFeePerGas
            ethTx.fee.maxPriorityFee = userParameters.maxPriorityFee ?? ethTx.fee.maxPriorityFee
            ethTx.nonce = userParameters.nonce ?? ethTx.nonce

            self.transaction = ethTx
            reloadData()

        default:
            break
        }
    }

    func userDidSubmit() {
        // request passcode if needed and sign
        if App.shared.auth.isPasscodeSetAndAvailable && AppSettings.passcodeOptions.contains(.useForConfirmation) {
            self.actionPanelView.setConfirmEnabled(false)

            let passcodeVC = EnterPasscodeViewController()
            passcodeVC.passcodeCompletion = { [weak self] success in
                self?.dismiss(animated: true) {
                    guard let `self` = self else { return }

                    if success {
                        self.sign()
                    }

                    self.actionPanelView.setConfirmEnabled(true)
                }
            }
            let nav = UINavigationController(rootViewController: passcodeVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        } else {
            sign()
        }
    }

    func sign() {
        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let txHash = transaction.hashForSigning().storage.storage

                guard let pk = try keyInfo.privateKey() else {
                    App.shared.snackbar.show(message: "Private key not available")
                    return
                }
                let signature = try pk._store.sign(hash: Array(txHash))

                try transaction.updateSignature(
                    v: Sol.UInt256(signature.v),
                    r: Sol.UInt256(Data(signature.r)),
                    s: Sol.UInt256(Data(signature.s))
                )
            } catch {
                let gsError = GSError.error(description: "Signing failed", error: error)
                App.shared.snackbar.show(error: gsError)
                return
            }
            submit()

        case .walletConnect:
            guard let clientTx = walletConnectTransaction() else {
                let gsError = GSError.error(description: "Unsupported transaction type")
                App.shared.snackbar.show(error: gsError)
                return
            }

            wcConnector = WCWalletConnectionController()
            wcConnector.connect(keyInfo: keyInfo, from: self) { [weak self] success in
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
                    guard let self = self else { return }

                    defer { self.wcConnector = nil }

                    guard success else {
                        return
                    }

                    let wcVC = WCPendingConfirmationViewController(
                        clientTx,
                        keyInfo: self.keyInfo,
                        title: "Sign Transaction"
                    )

                    wcVC.send { [weak self] txHash in
                        guard let self = self else { return }
                        assert(Thread.isMainThread)

                        if let hexHash = txHash {
                            self.didSubmitTransaction(txHash: Eth.Hash(Data(hex: hexHash)))
                            self.didSubmitSuccess()
                        } else {
                            self.didSubmitFailed(nil)
                        }
                    }

                    self.present(wcVC, animated: true)
                }
            }

        case .ledgerNanoX:
            let rawTransaction = transaction.preImageForSigning()
            let chainId = Int(chain.id!)!
            let isLegacy = transaction is Eth.TransactionLegacy

            let request = SignRequest(title: "Sign Transaction",
                                      tracking: ["action" : "signTx"],
                                      signer: keyInfo,
                                      payload: .rawTx(data: rawTransaction, chainId: chainId, isLegacy: isLegacy))

            let vc = LedgerSignerViewController(request: request)

            vc.txCompletion = { [weak self] signature in
                guard let self = self else { return }

                do {
                    try self.transaction.updateSignature(
                        v: Sol.UInt256(UInt(signature.v)),
                        r: Sol.UInt256(Data(Array(signature.r))),
                        s: Sol.UInt256(Data(Array(signature.s)))
                    )
                } catch {
                    let gsError = GSError.error(description: "Signing failed", error: error)
                    App.shared.snackbar.show(error: gsError)
                    return
                }

                self.submit()
            }

            present(vc, animated: true, completion: nil)
        }
    }

    func walletConnectTransaction() -> Client.Transaction? {
        guard let ethTransaction = transaction else {
            return nil
        }
        let clientTx: Client.Transaction

        // NOTE: only legacy parameters seem to work with current wallets.
        switch ethTransaction {
        case let tx as Eth.TransactionLegacy:
            let rpcTx = EthRpc1.TransactionLegacy(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.gasPrice?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: nil,
                accessList: nil,
                chainId: nil,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )

        case let tx as Eth.TransactionEip2930:
            let rpcTx = EthRpc1.Transaction2930(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.gasPrice?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: nil,
                accessList: nil,
                chainId: nil,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )

        case let tx as Eth.TransactionEip1559:
            let rpcTx = EthRpc1.Transaction1559(tx)
            clientTx = .init(
                from: rpcTx.from!.hex,
                to: rpcTx.to?.hex,
                data: rpcTx.input.hex,
                gas: rpcTx.gas?.hex,
                gasPrice: rpcTx.maxFeePerGas?.hex,
                value: rpcTx.value.hex,
                nonce: rpcTx.nonce?.hex,
                type: nil,
                accessList: nil,
                chainId: nil,
                maxPriorityFeePerGas: nil,
                maxFeePerGas: nil
            )
        default:
            return nil
        }

        return clientTx
    }


    func submit() {
        self.actionPanelView.setConfirmEnabled(false)

        let _ = send(completion: { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.actionPanelView.setConfirmEnabled(true)
                self.didSubmitFailed(error)

            case .success:
                self.didSubmitSuccess()
            }
        })
    }

    func send(completion: @escaping (Result<Void, Error>) -> Void) -> URLSessionTask? {
        guard let tx = self.transaction else { return nil }

        let rawTransaction = tx.rawTransaction()

        let sendRawTxMethod = EthRpc1.eth_sendRawTransaction(transaction: rawTransaction)

        let request: JsonRpc2.Request

        do {
            request = try sendRawTxMethod.request(id: .int(1))
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        let client = estimationController.rpcClient

        let task = client.send(request: request) { [weak self] response in
            guard let self = self else { return }

            guard let response = response else {
                let error = TransactionExecutionError(code: -4, message: "No response from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            if let error = response.error {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            guard let result = response.result else {
                let error = TransactionExecutionError(code: -5, message: "No result from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            let txHash: EthRpc1.Data
            do {
                txHash = try sendRawTxMethod.result(from: result)
            } catch {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            DispatchQueue.main.async {
                self.didSubmitTransaction(txHash: Eth.Hash(txHash.storage))
                completion(.success(()))
            }
        }
        return task
    }

    func didSubmitTransaction(txHash: Eth.Hash) {
        self.transaction.hash = txHash
    }

    func didSubmitFailed(_ error: Error?) {
        let gsError = GSError.error(description: "Submitting failed", error: error)
        App.shared.snackbar.show(error: gsError)

        Tracker.trackEvent(.executeFailure, parameters: [
            "chainId": self.chain.id!
        ])
    }

    func didSubmitSuccess() {
        let txHash = self.transaction.hash ?? .init()
        LogService.shared.debug("Submitted tx: \(txHash.storage.storage.toHexStringWithPrefix())")

        let result = DataString(txHash.storage.storage)
        controller.respond(request: request, with: result)
    }

}
