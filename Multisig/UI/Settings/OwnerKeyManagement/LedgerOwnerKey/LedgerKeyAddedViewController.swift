//
//  LedgerKeyAddedViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.10.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class LedgerKeyAddedViewController: AccountActionCompletedViewController {
    convenience init() {
        self.init(namedClass: AccountActionCompletedViewController.self)
    }

    override func viewDidLoad() {
        titleText = "Connect Ledger Nano X"
        headerText = "Owner Key added"

        assert(accountName != nil)
        assert(accountAddress != nil)

        descriptionText = "\(accountName ?? "Key") can't receive push notificaitons without your confirmation.\n\nYou can change this at any time in App Settings - Owner Keys - Key Details."

        primaryActionName = "Confirm to receive push notifications"
        secondaryActionName = "Skip"

        super.viewDidLoad()
    }

    override func primaryAction(_ sender: Any) {
        // Start Add Delegate flow with the selected account address


        #warning("TODO: tracking?")
        completion()
    }

    override func secondaryAction(_ sender: Any) {
        // doing nothing because user skipped
        #warning("TODO: tracking?")
        completion()
    }
}

class AddDelegateKeyController {

    let ownerAddress: Address
    let completionHandler: () -> Void


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
        let hashString = delegatePrivateKey.address.hexadecimal + time
        let hashToSign = EthHasher.hash(hashString)

        // 3. sign message with ledger key
        sign(message: hashToSign) { [weak self] signResult in
            guard let self = self else { return }

            switch signResult {
            // 3.1. on success, create delegate on backend
            case .success(let signatureData):

                // 4. send message and signature to the backend
                self.sendToBackend { [weak self] sendResult in
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
            throw "Owner key not found for delegate key"
        }
        return keyInfo
    }

    // sign and call back with signature or fail with error (incl. cancelled error)
    func sign(message: Data, completion: @escaping (Result<Data, Error>) -> Void) {
    }


    func sendToBackend(completion: @escaping (Result<Void, Error>) -> Void) {
        // send async request to backend
        // call completion
    }

    func abortProcess(error: Error) {

    }

    func completeProcess() {
        completionHandler()
    }
}

