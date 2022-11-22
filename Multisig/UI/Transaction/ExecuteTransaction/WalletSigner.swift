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

class WalletSigner {

    func signTransaction(controller: SignSource) {
        guard let keyInfo = controller.selectedKey?.key else {
            return
        }

        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated:
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
            controller.submit()

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

}
