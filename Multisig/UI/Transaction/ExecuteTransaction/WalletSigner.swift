//
//  WalletSigner.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.11.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

import WalletConnectSwift
import Ethereum

protocol SignSource: AnyObject {
    // tx execution

    // private key dependencies
    var selectedKey: (key: KeyInfo, balance: AccountBalanceUIModel)? { get }
    func hashForSigning() -> Data

    // private key, ledger
    func update(signature: (v: UInt, r: [UInt8], s: [UInt8])) throws
    func submit()

    // wallet connect dependencies
    func walletConnectTransaction() -> Client.Transaction?
    var chain: Chain! { get }
    func didSubmitTransaction(txHash: Eth.Hash)
    func didSubmitSuccess()

    // wallet connect, ledger
    // implemented by UIViewController
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)

    // ledger dependencies, keystone
    func preimageForSigning() -> Data
    var intChainId: Int { get }
    var isLegacyTx: Bool { get }

    // keystone dependencies
    var keystoneSignFlow: KeystoneSignFlow! { get set }

    // implemented by extension
    func present(flow: UIFlow, dismissableOnSwipe: Bool)
}

import Solidity

protocol SafeSignSource: AnyObject {
    // safe creation
    var uiModel: CreateSafeFormUIModel { get }

    func submit()
    func walletConnectTransaction() -> Client.Transaction?

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    var chain: Chain? { get }

    var keystoneSignFlow: KeystoneSignFlow! { get set }
    func present(flow: UIFlow, dismissableOnSwipe: Bool)

}

protocol WCSignSource: AnyObject {
    var chain: Chain! { get }
    var keyInfo: KeyInfo! { get }
    var keystoneSignFlow: KeystoneSignFlow! { get set }
    var transaction: EthTransaction! { get set }

    func submit()
    func walletConnectTransaction() -> Client.Transaction?
    func didSubmitFailed(_ error: Error?)
    func didSubmitTransaction(txHash: Eth.Hash)
    func didSubmitSuccess()
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func present(flow: UIFlow, dismissableOnSwipe: Bool)

}

protocol WCSignReqSource: AnyObject {
    var chain: Chain? { get }
    var request: WebConnectionSignatureRequest! { get }
    var keyInfo: KeyInfo? { get }
    var keystoneSignFlow: KeystoneSignFlow! { get set }

    func confirm(signature: Data, trackingParameters: [String: Any]?)
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func present(flow: UIFlow, dismissableOnSwipe: Bool)

}

protocol RejectionTxSource: AnyObject {
    var rejectionTransaction: Transaction { get set }
    var safe: Safe! { get }
    var keyInfo: KeyInfo? { get set }
    func rejectAndCloseController(signature: String)
    var presentedViewController: UIViewController? { get }
    var keystoneSignFlow: KeystoneSignFlow! { get set }
    func endLoading()
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func present(flow: UIFlow, dismissableOnSwipe: Bool)
}

protocol PushMsgSource: AnyObject {
    var keyInfo: KeyInfo { get }
    var keystoneSignFlow: KeystoneSignFlow! { get set }
    var presenter: UIViewController? { get }
}

class WalletSigner {

    enum SignError: Error {
        case privateKeyNotAvailable
    }

    fileprivate func signTxWithLocalWallet(_ controller: SignSource, _ keyInfo: KeyInfo) {
        do {
            let txHash = controller.hashForSigning()

            guard let pk = try keyInfo.privateKey() else {
                throw SignError.privateKeyNotAvailable
            }

            let signature = try pk._store.sign(hash: Array(txHash))

            try controller.update(signature: signature)

            controller.submit()
        } catch SignError.privateKeyNotAvailable {
            App.shared.snackbar.show(message: "Private key not available")
        } catch {
            let gsError = GSError.error(description: "Signing failed", error: error)
            App.shared.snackbar.show(error: gsError)
        }
    }

    fileprivate func signSafeCreationTxWithLocalWallet(_ controller: SafeSignSource, _ keyInfo: KeyInfo) {
        do {
            let txHash = controller.uiModel.transaction.hashForSigning().storage.storage

            guard let pk = try keyInfo.privateKey() else {
                App.shared.snackbar.show(message: "Private key not available")
                return
            }
            let signature = try pk._store.sign(hash: Array(txHash))

            try controller.uiModel.transaction.updateSignature(
                v: Sol.UInt256(signature.v),
                r: Sol.UInt256(Data(signature.r)),
                s: Sol.UInt256(Data(signature.s))
            )
        } catch {
            let gsError = GSError.error(description: "Signing failed", error: error)
            App.shared.snackbar.show(error: gsError)
            return
        }
        controller.submit()
    }


    fileprivate func signWCSendTxWithLocalWallet(_ controller: WCSignSource) {
        do {
            let txHash = controller.transaction.hashForSigning().storage.storage

            guard let pk = try controller.keyInfo.privateKey() else {
                App.shared.snackbar.show(message: "Private key not available")
                return
            }
            let signature = try pk._store.sign(hash: Array(txHash))

            try controller.transaction.updateSignature(
                v: Sol.UInt256(signature.v),
                r: Sol.UInt256(Data(signature.r)),
                s: Sol.UInt256(Data(signature.s))
            )
        } catch {
            let gsError = GSError.error(description: "Signing failed", error: error)
            App.shared.snackbar.show(error: gsError)
            return
        }

        controller.submit()
    }

    fileprivate func signMessageWithLocalWallet(_ keyInfo: KeyInfo, _ controller: WCSignReqSource) {
        do {
            guard let pk = try keyInfo.privateKey() else {
                App.shared.snackbar.show(message: "Private key not available")
                return
            }
            let preimage = "\u{19}Ethereum Signed Message:\n\(controller.request.message.count)".data(using: .utf8)! + controller.request.message
            let signatureParts = try pk._store.sign(message: preimage.bytes)
            let signature = Data(signatureParts.r) + Data(signatureParts.s) + Data([UInt8(signatureParts.v)])
            controller.confirm(signature:  signature, trackingParameters: nil)
        } catch {
            App.shared.snackbar.show(message: "Failed to sign: \(error.localizedDescription)")
        }
    }

    // used directly for delegate key signing; and for remote notif registration
    func signHash(pk: PrivateKey, hash: Data) throws -> Signature {
        try pk.sign(hash: hash)
    }

    func signTransaction(controller: SignSource) {
        guard let keyInfo = controller.selectedKey?.key else {
            return
        }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            signTxWithLocalWallet(controller, keyInfo)

        case .walletConnect:
            guard let clientTx = controller.walletConnectTransaction() else {
                let gsError = GSError.error(description: "Unsupported transaction type")
                App.shared.snackbar.show(error: gsError)
                return
            }

            let sendTxVC = SendTransactionToWalletViewController(
                transaction: clientTx,
                keyInfo: keyInfo,
                chain: controller.chain
            )

            sendTxVC.onSuccess = { [weak controller] txHashData in
                guard let controller = controller else { return }
                controller.didSubmitTransaction(txHash: Eth.Hash(txHashData))
                controller.didSubmitSuccess()
            }

            let vc = ViewControllerFactory.pageSheet(viewController: sendTxVC, halfScreen: true)
            controller.present(vc, animated: true, completion: nil)

        case .ledgerNanoX:
            // NOTE: not supported for transaction execution!
            let rawTransaction = controller.preimageForSigning()
            let chainId = controller.intChainId
            let isLegacy = controller.isLegacyTx

            let request = SignRequest(title: "Sign Transaction",
                                      tracking: ["action" : "signTx"],
                                      signer: keyInfo,
                                      payload: .rawTx(data: rawTransaction, chainId: chainId, isLegacy: isLegacy))

            let vc = LedgerSignerViewController(request: request)

            vc.txCompletion = { [weak controller] signature in
                guard let controller = controller else { return }

                do {
                    try controller.update(signature: (UInt(signature.v), Array(signature.r), Array(signature.s)))
                } catch {
                    let gsError = GSError.error(description: "Signing failed", error: error)
                    App.shared.snackbar.show(error: gsError)
                    return
                }

                controller.submit()
            }

            controller.present(vc, animated: true, completion: nil)

        case .keystone:
            let isLegacy = controller.isLegacyTx

            let signInfo = KeystoneSignInfo(
                signData: controller.preimageForSigning().toHexString(),
                chain: controller.chain,
                keyInfo: keyInfo,
                signType: isLegacy ? .transaction : .typedTransaction
            )
            let signCompletion = { [unowned controller] (success: Bool) in
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                }
                controller.keystoneSignFlow = nil
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                return
            }

            controller.keystoneSignFlow = signFlow
            controller.keystoneSignFlow.signCompletion = { [weak controller] unmarshaledSignature in
                do {
                    try controller?.update(signature: (UInt(unmarshaledSignature.v), Array(unmarshaledSignature.r), Array(unmarshaledSignature.s)))
                    controller?.submit()
                } catch {
                    App.shared.snackbar.show(error: GSError.error(description: "Signing failed", error: error))
                }
            }
            controller.present(flow: controller.keystoneSignFlow, dismissableOnSwipe: true)
        }
    }

    func signSafeCreation(controller: SafeSignSource) {
        guard let keyInfo = controller.uiModel.selectedKey else { return }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            signSafeCreationTxWithLocalWallet(controller, keyInfo)

        case .walletConnect:
            guard let clientTx = controller.walletConnectTransaction() else {
                let gsError = GSError.error(description: "Unsupported transaction type")
                App.shared.snackbar.show(error: gsError)
                return
            }

            let sendTxVC = SendTransactionToWalletViewController(
                transaction: clientTx,
                keyInfo: keyInfo,
                chain: controller.uiModel.chain
            )
            sendTxVC.onSuccess = { [weak controller] txHashData in
                guard let controller = controller else { return }
                controller.uiModel.didSubmitTransaction(txHash: Eth.Hash(txHashData))
                controller.uiModel.didSubmitSuccess()
            }
            let vc = ViewControllerFactory.pageSheet(viewController: sendTxVC, halfScreen: true)
            controller.present(vc, animated: true, completion: nil)

        case .ledgerNanoX:
            let rawTransaction = controller.uiModel.transaction.preImageForSigning()
            let chainId = Int(controller.uiModel.chain.id!)!
            let isLegacy = controller.uiModel.transaction is Eth.TransactionLegacy

            let request = SignRequest(title: "Sign Transaction",
                                      tracking: ["action" : "signTx"],
                                      signer: keyInfo,
                                      payload: .rawTx(data: rawTransaction, chainId: chainId, isLegacy: isLegacy))

            let vc = LedgerSignerViewController(request: request)

            vc.txCompletion = { [weak controller] signature in
                guard let controller = controller else { return }

                do {
                    try controller.uiModel.transaction.updateSignature(
                        v: Sol.UInt256(UInt(signature.v)),
                        r: Sol.UInt256(Data(Array(signature.r))),
                        s: Sol.UInt256(Data(Array(signature.s)))
                    )
                } catch {
                    let gsError = GSError.error(description: "Signing failed", error: error)
                    App.shared.snackbar.show(error: gsError)
                    return
                }

                controller.submit()
            }

            controller.present(vc, animated: true, completion: nil)

        case .keystone:
            let isLegacy = controller.uiModel.transaction is Eth.TransactionLegacy

            let signInfo = KeystoneSignInfo(
                signData: controller.uiModel.transaction.preImageForSigning().toHexString(),
                chain: controller.chain,
                keyInfo: keyInfo,
                signType: isLegacy ? .transaction : .typedTransaction
            )
            let signCompletion = { [unowned controller] (success: Bool) in
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                }
                controller.keystoneSignFlow = nil
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                return
            }

            controller.keystoneSignFlow = signFlow
            controller.keystoneSignFlow.signCompletion = { [weak controller] unmarshaledSignature in
                do {
                    try controller?.uiModel.transaction.updateSignature(
                        v: Sol.UInt256(UInt(unmarshaledSignature.v)),
                        r: Sol.UInt256(Data(Array(unmarshaledSignature.r))),
                        s: Sol.UInt256(Data(Array(unmarshaledSignature.s)))
                    )
                    controller?.submit()
                } catch {
                    App.shared.snackbar.show(error: GSError.error(description: "Signing failed", error: error))
                }
            }
            controller.present(flow: controller.keystoneSignFlow, dismissableOnSwipe: true)
        }
    }


    func signWC(controller: WCSignSource) {
        switch controller.keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            signWCSendTxWithLocalWallet(controller)

        case .walletConnect:
            guard let clientTx = controller.walletConnectTransaction() else {
                let gsError = GSError.error(description: "Unsupported transaction type")
                App.shared.snackbar.show(error: gsError)
                return
            }

            let sendTxVC = SendTransactionToWalletViewController(
                transaction: clientTx,
                keyInfo: controller.keyInfo,
                chain: controller.chain ?? Chain.mainnetChain()
            )
            sendTxVC.onCancel = { [weak controller] in
                controller?.didSubmitFailed(nil)
            }
            sendTxVC.onSuccess = { [weak controller] txHashData in
                guard let controller = controller else { return }
                controller.didSubmitTransaction(txHash: Eth.Hash(txHashData))
                controller.didSubmitSuccess()
            }
            let vc = ViewControllerFactory.pageSheet(viewController: sendTxVC, halfScreen: true)
            controller.present(vc, animated: true, completion: nil)

        case .ledgerNanoX:
            let rawTransaction = controller.transaction.preImageForSigning()
            let chainId = Int(controller.chain.id!)!
            let isLegacy = controller.transaction is Eth.TransactionLegacy

            let request = SignRequest(title: "Sign Transaction",
                                      tracking: ["action" : "signTx"],
                                      signer: controller.keyInfo,
                                      payload: .rawTx(data: rawTransaction, chainId: chainId, isLegacy: isLegacy))

            let vc = LedgerSignerViewController(request: request)

            vc.txCompletion = { [weak controller] signature in
                guard let controller = controller else { return }

                do {
                    try controller.transaction.updateSignature(
                        v: Sol.UInt256(UInt(signature.v)),
                        r: Sol.UInt256(Data(Array(signature.r))),
                        s: Sol.UInt256(Data(Array(signature.s)))
                    )
                } catch {
                    let gsError = GSError.error(description: "Signing failed", error: error)
                    App.shared.snackbar.show(error: gsError)
                    return
                }

                controller.submit()
            }

            controller.present(vc, animated: true, completion: nil)

        case .keystone:
            let isLegacy = controller.transaction is Eth.TransactionLegacy

            let signInfo = KeystoneSignInfo(
                signData: controller.transaction.preImageForSigning().toHexString(),
                chain: controller.chain,
                keyInfo: controller.keyInfo,
                signType: isLegacy ? .transaction : .typedTransaction
            )
            let signCompletion = { [unowned controller] (success: Bool) in
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                }
                controller.keystoneSignFlow = nil
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                return
            }

            controller.keystoneSignFlow = signFlow
            controller.keystoneSignFlow.signCompletion = { [weak controller] unmarshaledSignature in
                do {
                    try controller?.transaction.updateSignature(
                        v: Sol.UInt256(UInt(unmarshaledSignature.v)),
                        r: Sol.UInt256(Data(Array(unmarshaledSignature.r))),
                        s: Sol.UInt256(Data(Array(unmarshaledSignature.s)))
                    )
                    controller?.submit()
                } catch {
                    App.shared.snackbar.show(error: GSError.error(description: "Signing failed", error: error))
                }
            }
            controller.present(flow: controller.keystoneSignFlow, dismissableOnSwipe: false)
        }
    }

    // Sign calculates an Ethereum ECDSA signature for:
    // keccack256("\x19Ethereum Signed Message:\n" + len(message) + message))

    func signWCSignReq(controller: WCSignReqSource) {
        guard let keyInfo = controller.keyInfo else {
            return
        }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            signMessageWithLocalWallet(keyInfo, controller)

        case .walletConnect:
            let hexMessage = controller.request.message.toHexStringWithPrefix()

            let signVC = SignatureRequestToWalletViewController(hexMessage, keyInfo: keyInfo, chain: controller.chain ?? Chain.mainnetChain())
            signVC.onSuccess = { [weak controller] signature in
                let signatureData = Data(hex: signature)
                controller?.confirm(signature: signatureData, trackingParameters: nil)
            }
            let vc = ViewControllerFactory.pageSheet(viewController: signVC, halfScreen: true)
            controller.present(vc, animated: true, completion: nil)

        case .ledgerNanoX:
            let hexToSign = controller.request.message.toHexStringWithPrefix()

            let request = SignRequest(title: "Sign Message",
                                      tracking: ["action": "signMessage"],
                                      signer: keyInfo,
                                      hexToSign: hexToSign)

            let ledgerSignerVC = LedgerSignerViewController(request: request)

            controller.present(ledgerSignerVC, animated: true, completion: nil)

            ledgerSignerVC.completion = { [weak controller] hexSignature in
                // subtracting 4 from the v component of the signature in order to convert it to the ethereum signature
                var signature = Data(hex: hexSignature)
                assert(signature.count == 65)
                signature[64] -= 4
                controller?.confirm(signature: signature, trackingParameters: nil)
            }

        case .keystone:
            let signInfo = KeystoneSignInfo(
                signData: controller.request.message.toHexString(),
                chain: controller.chain,
                keyInfo: keyInfo,
                signType: .personalMessage
            )
            let signCompletion = { [unowned controller] (success: Bool) in
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                }
                controller.keystoneSignFlow = nil
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                return
            }

            controller.keystoneSignFlow = signFlow
            controller.keystoneSignFlow.signCompletion = { [weak controller] unmarshaledSignature in
                if let signature = SECP256K1.marshalSignature(v: Data([unmarshaledSignature.v]), r: unmarshaledSignature.r, s: unmarshaledSignature.s) {
                    controller?.confirm(signature: signature, trackingParameters: nil)
                }
            }
            controller.present(flow: controller.keystoneSignFlow, dismissableOnSwipe: true)
        }
    }

    func rejectTransaction(_ keyInfo: KeyInfo, controller: RejectionTxSource) {
        controller.keyInfo = keyInfo

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let signature = try SafeTransactionSigner().sign(controller.rejectionTransaction, keyInfo: keyInfo)
                controller.rejectAndCloseController(signature: signature.hexadecimal)
            } catch {
                App.shared.snackbar.show(message: "Failed to Reject transaction")
            }

        case .walletConnect:
            rejectWithWalletConnect(controller.rejectionTransaction, keyInfo: keyInfo, controller: controller)

        case .ledgerNanoX:
            let request = SignRequest(title: "Reject Transaction",
                                      tracking: ["action" : "reject"],
                                      signer: keyInfo,
                                      hexToSign: controller.rejectionTransaction.safeTxHash.description)
            let vc = LedgerSignerViewController(request: request)
            controller.present(vc, animated: true, completion: nil)

            vc.completion = { [weak controller] signature in
                controller?.rejectAndCloseController(signature: signature)
            }
            vc.onClose = { [weak controller] in
                controller?.endLoading()
            }
        case .keystone:
            let signInfo = KeystoneSignInfo(
                signData: controller.rejectionTransaction.safeTxHash.hash.toHexString(),
                chain: controller.safe.chain,
                keyInfo: keyInfo,
                signType: .personalMessage
            )
            let signCompletion = { [unowned controller] (success: Bool) in
                controller.keystoneSignFlow = nil
                if !success {
                    App.shared.snackbar.show(error: GSError.KeystoneSignFailed())
                    controller.endLoading()
                }
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion) else {
                App.shared.snackbar.show(error: GSError.KeystoneStartSignFailed())
                controller.endLoading()
                return
            }

            controller.keystoneSignFlow = signFlow
            controller.keystoneSignFlow.signCompletion = { [weak controller] unmarshaledSignature in
                controller?.rejectAndCloseController(signature: unmarshaledSignature.safeSignature)
            }
            controller.present(flow: controller.keystoneSignFlow, dismissableOnSwipe: true)
        }
    }

    func rejectWithWalletConnect(_ transaction: Transaction, keyInfo: KeyInfo, controller: RejectionTxSource) {
        guard controller.presentedViewController == nil else { return }

        let signVC = SignatureRequestToWalletViewController(transaction, keyInfo: keyInfo, chain: controller.safe.chain!)
        signVC.onSuccess = { [weak controller] signature in
            DispatchQueue.main.async {
                controller?.rejectAndCloseController(signature: signature)
            }
        }
        signVC.onCancel = { [weak controller] in
            controller?.endLoading()
        }
        let vc = ViewControllerFactory.pageSheet(viewController: signVC, halfScreen: true)
        controller.present(vc, animated: true, completion: nil)
    }

    func signPushMessage(controller: PushMsgSource, message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        let title = "Confirm Push Notifications"
        let hexMessage = message.toHexStringWithPrefix()
        let chain = try? Safe.getSelected()?.chain ?? Chain.mainnetChain()
        switch controller.keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
            do {
                let signature = try SafeTransactionSigner().sign(hash: HashString(hex: hexMessage), keyInfo: controller.keyInfo)
                completion(.success(Data(hex: signature.hexadecimal)))
            } catch {
                completion(.failure(GSError.AddDelegateKeyCancelled()))
            }
        case .ledgerNanoX:
            let request = SignRequest(title: title,
                                      tracking: ["action": "confirm_push"],
                                      signer: controller.keyInfo,
                                      hexToSign: hexMessage)

            let vc = LedgerSignerViewController(request: request)

            controller.presenter?.present(vc, animated: true, completion: nil)

            var isSuccess: Bool = false

            vc.completion = { signature in
                isSuccess = true
                completion(.success(Data(hex: signature)))
            }

            vc.onClose = {
                if !isSuccess {
                    completion(.failure(GSError.AddDelegateKeyCancelled()))
                }
            }

        case .walletConnect:
            let signVC = SignatureRequestToWalletViewController(hexMessage, keyInfo: controller.keyInfo, chain: chain!)
            signVC.requiresChainIdMatch = false
            var isSuccess: Bool = false
            signVC.onSuccess = { signature in
                isSuccess = true
                completion(.success(Data(hex: signature)))
            }
            signVC.onCancel = {
                if !isSuccess {
                    completion(.failure(GSError.AddDelegateKeyCancelled()))
                }
            }
            let vc = ViewControllerFactory.pageSheet(viewController: signVC, halfScreen: true)
            controller.presenter?.present(vc, animated: true)
        case .keystone:
            let signInfo = KeystoneSignInfo(
                signData: hexMessage,
                chain: chain,
                keyInfo: controller.keyInfo,
                signType: .personalMessage
            )
            let signCompletion = { [unowned controller] (success: Bool) in
                controller.keystoneSignFlow = nil
                if !success {
                    completion(.failure(GSError.AddDelegateKeyCancelled()))
                }
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion),
                  let presenter = controller.presenter else {
                completion(.failure(GSError.AddDelegateTimedOut()))
                return
            }

            controller.keystoneSignFlow = signFlow
            controller.keystoneSignFlow.signCompletion = { unmarshaledSignature in
                completion(.success(Data(hex: unmarshaledSignature.safeSignature)))
            }

            presenter.present(flow: controller.keystoneSignFlow, dismissableOnSwipe: true)
        }
    }

}
