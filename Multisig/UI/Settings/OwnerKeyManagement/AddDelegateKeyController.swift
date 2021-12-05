//
//  AddDelegateKeyController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 29.11.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AddDelegateKeyController {

    weak var presenter: UIViewController?
    var clientGatewayService = App.shared.clientGatewayService

    private let ownerAddress: Address
    private let completionHandler: () -> Void

    init(ownerAddress: Address, completion: @escaping () -> Void) {
        self.ownerAddress = ownerAddress
        self.completionHandler = completion
    }

    func start() {
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

        // 3. sign message with ledger key
        sign(message: hashToSign) { [weak self] signResult in
            guard let self = self else { return }

            switch signResult {
            // 3.1. on success, create delegate on backend
            case .success(let signatureData):

                // 4. send message and signature to the backend
                self.sendToBackend(
                    delegateAddress: delegatePrivateKey.address,
                    signature: signatureData
                ) { [weak self] sendResult in
                    guard let self = self else { return }

                    switch sendResult {
                    // 4.1. on success, store the delegate key association
                    //             and the delegate key in the keychain
                    case .success:
                        // store the delegate key association to the ledger key in the database

                        // get the ledger key info
                        let keyInfo: KeyInfo
                        do {
                            keyInfo = try self.loadKeyInfo()
                        } catch {
                            self.abortProcess(error: error)
                            return
                        }

                        // modify to set delegate address
                        keyInfo.delegateAddressString = delegatePrivateKey.address.checksummed

                        // store the delegate key in keychain
                        do {
                            // create or update the key in the keychain
                            try delegatePrivateKey.save()

                            // save the database modifications
                            keyInfo.save()
                        } catch {
                            // at this point, we registered delegate in the backend, will ignore that because
                            // the delegate can be overriden in the future attempts.

                            // however, we rollback the database changes to the KeyInfo
                            keyInfo.rollback()
                        }

                        // post notification so that UI state can be updated
                        NotificationCenter.default.post(name: .ownerKeyUpdated, object: nil)

                        // trigger push notification registration
                        App.shared.notificationHandler.signingKeyUpdated()

                        self.completeProcess()
                        break

                    // 4.2. on error - show to the user, abort, close/completion
                    case .failure(let error):
                        self.abortProcess(error: error)
                        break
                    }
                }

                break

            // 3.2. on error, show erro to the user, abort&complete
            case .failure(let error):
                self.abortProcess(error: error)
                break
            }
        }
    }

    func loadKeyInfo() throws -> KeyInfo {
        // get the ledger key info
        let keyOrNil = try KeyInfo.firstKey(address: self.ownerAddress)

        guard let keyInfo = keyOrNil else {
            throw GSError.OwnerKeyNotFoundForDelegate()
        }
        return keyInfo
    }

    // sign and call back with signature or fail with error (incl. cancelled error)
    func sign(message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
        // get ledger key info
        let keyInfo: KeyInfo
        do {
            keyInfo = try self.loadKeyInfo()
        } catch {
            completion(.failure(error))
            return
        }

        let title = "Confirm Push Notifications"
        let hexMessage = message.toHexStringWithPrefix()
        switch keyInfo.keyType {
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
            let vc = WCPendingConfirmationViewController(hexMessage, keyInfo: keyInfo, title: title)

            presenter?.present(vc, animated: true, completion: nil)

            var isSuccess: Bool = false

            vc.onClose = {
                if !isSuccess {
                    completion(.failure(GSError.AddDelegateKeyCancelled()))
                }
            }

            vc.sign() { signature in
                isSuccess = true
                completion(.success(Data(hex: signature)))
            }

        default:
            completion(.failure(GSError.UnrecognizedKeyTypeForDelegate()))
        }
    }

    func sendToBackend(delegateAddress: Address, signature: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        // to synchronize multiple async processes, we use DispatchGroup
        let group = DispatchGroup()

        Chain.all.forEach { chain in
            // trigger request
            group.enter()
            clientGatewayService.asyncCreateDelegate(safe: nil,
                    owner: ownerAddress,
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

    func abortProcess(error: Error) {
        Tracker.trackEvent(.addDelegateKeyFailed)
        DispatchQueue.main.async { [weak self] in
            App.shared.snackbar.show(message: error.localizedDescription)
            self?.completionHandler()
        }
    }

    func completeProcess() {
        Tracker.trackEvent(.addDelegateKeySuccess)
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler()
        }
    }
}
