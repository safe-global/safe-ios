//
//  AddDelegateKeyController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 29.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class DelegateKeyController {

    weak var presenter: UIViewController?
    private var clientGatewayService = App.shared.clientGatewayService
    private var keystoneSignFlow: KeystoneSignFlow!

    private let keyInfo: KeyInfo
    private let completionHandler: () -> Void

    init(ownerAddress: Address, completion: @escaping () -> Void) throws {
        guard let keyOrNil = try KeyInfo.firstKey(address: ownerAddress) else {
            throw GSError.OwnerKeyNotFoundForDelegate()
        }

        self.keyInfo = keyOrNil
        self.completionHandler = completion
    }

    func createDelegate() {
        // 1. generate a delegate key
        // 16 bit = 12 words
        let delegateSeed = Data.randomBytes(length: 16)!
        let delegateMnemonic = BIP39.generateMnemonicsFromEntropy(entropy: delegateSeed)!
        let delegatePrivateKey = try! PrivateKey(mnemonic: delegateMnemonic, pathIndex: 0)

        // 2. create 'create delegate' message
            // keccak(address + str(int(current_epoch // 3600)))
        let time = String(describing: Int(Date().timeIntervalSince1970) / 3600)
        let messageToSign = delegatePrivateKey.address.checksummed + time
        let hashToSign = EthHasher.hash(messageToSign)

        // 3. sign message with key
        sign(message: hashToSign) { [weak self] signResult in
            guard let self = self else { return }

            switch signResult {
            // 3.1. on success, create delegate on backend
            case .success(let signatureData):
                // 4. send message and signature to the backend
                self.createOnBackEnd(
                    delegateAddress: delegatePrivateKey.address,
                    signature: signatureData
                ) { [weak self] sendResult in
                    guard let self = self else { return }
                    switch sendResult {
                    // 4.1. on success, store the delegate key association
                    //             and the delegate key in the keychain
                    case .success:
                        // store the delegate key association to the key in the database

                        // modify to set delegate address
                        self.keyInfo.delegateAddressString = delegatePrivateKey.address.checksummed

                        // store the delegate key in keychain
                        do {
                            // create or update the key in the keychain
                            try delegatePrivateKey.save(protectionClass: .data)

                            // save the database modifications
                            self.keyInfo.save()

                            // post notification so that UI state can be updated
                            NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)

                            // trigger push notification registration
                            App.shared.notificationHandler.signingKeyUpdated()

                            Tracker.trackEvent(.addDelegateKeySuccess)
                        } catch {
                            // at this point, we registered delegate in the backend, will ignore that because
                            // the delegate can be overriden in the future attempts.

                            // however, we rollback the database changes to the KeyInfo
                            self.keyInfo.rollback()
                        }

                        self.completionHandler()
                        break

                    // 4.2. on error - show to the user, abort, close/completion
                    case .failure(let error):
                        self.abortProcess(error: error, trackingEvent: .addDelegateKeyFailed)
                        break
                    }
                }
            // 3.2. on error, show error to the user, abort&complete
            case .failure(let error):
                self.abortProcess(error: error, trackingEvent: .addDelegateKeyFailed)
            }
        }
    }

    func deleteDelegate() {
        keyInfo.delegatePrivateKey() { [unowned self] result in
            do {
                guard let delegateKey = try result.get() else {
                    throw GSError.PrivateKeyFetchError(reason: "Delegate key not found")
                }

                let time = String(describing: Int(Date().timeIntervalSince1970) / 3600)
                let messageToSign = delegateKey.address.checksummed + time
                let hashToSign = EthHasher.hash(messageToSign)
                let signature = try delegateKey.sign(hash: hashToSign)

                self.deleteOnBackEnd(delegateAddress: delegateKey.address,
                                     signature: signature.hexadecimal
                ) { [weak self] sendResult in
                    guard let self = self else { return }
                    switch sendResult {
                    case .success:
                        do {
                            self.keyInfo.delegateAddressString = nil
                            try delegateKey.remove(protectionClass: .data)
                            self.keyInfo.save()
                            NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)
                            App.shared.notificationHandler.signingKeyUpdated()

                            Tracker.trackEvent(.deleteDelegateKeySuccess)
                        } catch {
                            self.keyInfo.rollback()
                        }

                        self.completionHandler()
                    case .failure(let error):
                        self.abortProcess(error: error, trackingEvent: .deleteDelegateKeyFailed)
                    }
                }
            } catch {
                self.abortProcess(error: error, trackingEvent: .deleteDelegateKeyFailed)
            }
        }
    }

    // sign and call back with signature or fail with error (incl. cancelled error)
    private func sign(message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        let title = "Confirm Push Notifications"
        let hexMessage = message.toHexStringWithPrefix()
        let chain = try? Safe.getSelected()?.chain ?? Chain.mainnetChain()
        switch keyInfo.keyType {
        case .deviceImported, .deviceGenerated, .web3AuthApple, .web3AuthGoogle:
            guard let message = try? HashString(hex: hexMessage) else {
                completion(.failure(GSError.AddDelegateKeyCancelled()))
                return
            }
            Wallet.shared.sign(hash: message, keyInfo: keyInfo) { result in
                do {
                    let signature = try result.get()
                    completion(.success(Data(hex: signature.hexadecimal)))
                } catch {
                    completion(.failure(GSError.AddDelegateKeyCancelled()))
                }
            }
        case .ledgerNanoX:
            let request = SignRequest(title: title,
                                      tracking: ["action": "confirm_push"],
                                      signer: keyInfo,
                                      hexToSign: hexMessage)

            let vc = LedgerSignerViewController(request: request)

            presenter?.present(vc, animated: true, completion: nil)

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
            let signVC = SignatureRequestToWalletViewController(hexMessage, keyInfo: keyInfo, chain: chain!)
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
            presenter?.present(vc, animated: true)
        case .keystone:
            let signInfo = KeystoneSignInfo(
                signData: message.toHexString(),
                chain: chain,
                keyInfo: keyInfo,
                signType: .personalMessage
            )
            let signCompletion = { [unowned self] (success: Bool) in
                keystoneSignFlow = nil
                if !success {
                    completion(.failure(GSError.AddDelegateKeyCancelled()))
                }
            }
            guard let signFlow = KeystoneSignFlow(signInfo: signInfo, completion: signCompletion),
                    let presenter = presenter else {
                completion(.failure(GSError.AddDelegateTimedOut()))
                return
            }

            keystoneSignFlow = signFlow
            keystoneSignFlow.signCompletion = { unmarshaledSignature in
                completion(.success(Data(hex: unmarshaledSignature.safeSignature)))
            }

            presenter.present(flow: keystoneSignFlow)
        }
    }

    func createOnBackEnd(delegateAddress: Address, signature: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        // to synchronize multiple async processes, we use DispatchGroup
        let group = DispatchGroup()

        Chain.all.forEach { chain in
            // trigger request
            group.enter()
            clientGatewayService.asyncCreateDelegate(safe: nil,
                                                     owner: keyInfo.address,
                                                     delegate: delegateAddress,
                                                     signature: signature,
                                                     label: "iOS Device Delegate",
                                                     chainId: chain.id!) { result in
                group.leave()
            }
        }

        // We use 60 seconds because it's a URLRequest's default timeout and
        // we expect all requests to finish before that
        let createDelegateRequestTimeoutInSeconds = 60 // one minute
        let timeoutResult = group.wait(timeout: .now() + .seconds(createDelegateRequestTimeoutInSeconds))

        switch timeoutResult {
        case .success:
            completion(.success(()))
        case .timedOut:
            completion(.failure(GSError.AddDelegateTimedOut()))
        }
    }

    func deleteOnBackEnd(delegateAddress: Address, signature: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // to synchronize multiple async processes, we use DispatchGroup
        let group = DispatchGroup()

        Chain.all.forEach { chain in
            // trigger request
            group.enter()
            clientGatewayService.asyncDeleteDelegate(owner: keyInfo.address,
                                                     delegate: delegateAddress,
                                                     signature: signature,
                                                     chainId: chain.id!) { result in
                group.leave()
            }
        }

        // We use 60 seconds because it's a URLRequest's default timeout and
        // we expect all requests to finish before that
        let createDelegateRequestTimeoutInSeconds = 60 // one minute
        let timeoutResult = group.wait(timeout: .now() + .seconds(createDelegateRequestTimeoutInSeconds))

        switch timeoutResult {
        case .success:
            completion(.success(()))
        case .timedOut:
            completion(.failure(GSError.DeleteDelegateTimedOut()))
        }
    }

    func abortProcess(error: Error, trackingEvent: TrackingEvent) {
        Tracker.trackEvent(trackingEvent)
        DispatchQueue.main.async { [weak self] in
            App.shared.snackbar.show(message: error.localizedDescription)
            self?.completionHandler()
        }
    }
}
