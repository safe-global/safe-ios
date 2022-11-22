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
}
