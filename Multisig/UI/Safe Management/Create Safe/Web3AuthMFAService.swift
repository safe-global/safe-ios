//
//  Web3AuthMFAService.swift
//  Multisig
//
//  Created by Dirk Jäckel on 08.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import tkey_pkg

class Web3AuthMFAService {

    // if the device share is missing and also no password has been provided
    var shareMissing: Bool
    var finalKey: String?
    private var password: String?

    private let keychainInterface: KeychainInterface!
    private var isAlreadyMFA = true
    private let postBoxKey: String
    private let publicAddress: String
    private var thresholdKey: ThresholdKey
    private var threshold = 0
    private let question = "PASSWORD"

    static func mfaEnabled(userInfo: [String: Any]) -> Bool {
        // TODO: in future version od the SDK there will be an entry called "nonce". If 0, then mfa is enabled

        // For now we whitelist adresses
        let email = userInfo["email"] as? String

        return email == "bttr.tstr@gmail.com" || email == "ego.other@gmail.com" || email == "dirk@safe.global"
    }

    func setupPassword(password: String) async throws {
        let _ = try await SecurityQuestionModule.generate_new_share(threshold_key: thresholdKey, questions: question, answer: password)
        LogService.shared.debug("---> password set for the first time")
    }

    /// this is used to unlock the key. Can also be done in init()
    func inputPassword(password: String) async throws {
        self.password = password

        // password given
        guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: password) else {
            throw("input share failed. Make sure threshold key is initialized")
        }

        LogService.shared.debug("---> password correct")
        if !result {
            throw("password incorrect")
        }
    }

    func changePassword(oldPassword: String, newPassword: String) async throws {
        // password given
        guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: oldPassword) else {
            throw("input share failed. Make sure threshold key is initialized")
        }
        if !result {
            throw("old password incorrect")
        } else {
            LogService.shared.debug("---> old password correct")
        }

        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true

            throw("Failed to reconstruct key. More share(s) required.")
        }
        LogService.shared.debug("---> key reconstructed: \(reconstructionDetails)")

        let changeResult = try await SecurityQuestionModule.change_question_and_answer(threshold_key: thresholdKey, questions: question, answer: newPassword)

        if changeResult {
            LogService.shared.debug("---> password changed")
        } else {
            LogService.shared.debug("---> password not changed")
        }
    }

    func recoverDeviceShare(password: String? = nil) async throws {
        if let password = password {
            LogService.shared.debug("---> password: \(password)")
            guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: password) else {
                LogService.shared.debug("---> password input share failed. Make sure threshold key is initialized")
                throw("password input share failed. Make sure threshold key is initialized")
            }
            if !result {
                LogService.shared.debug("---> password incorrect")
                throw("password incorrect")
            } else {
                LogService.shared.debug("---> password correct")
            }
        }
        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true
            throw("Failed to reconstruct key. more share(s) required.")
        }

        guard let _ = try? await thresholdKey.generate_new_share() else {
            throw("Failed create new share")
        }

        var shareIndexes = try thresholdKey.get_shares_indexes()
        shareIndexes.removeAll(where: {$0 == "1"}) // apparently 1 is the postboxkey share

        guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[shareIndexes.count], shareType: nil) else {
            throw("Failed to output share")
        }
        guard let _ = try? keychainInterface.save(item: share, key: "\(publicAddress):device-key") else {
            throw("Failed to save share")
        }

        LogService.shared.debug("---> Recovery complete")
    }


    /// Instantiate a Web3AuthMFAService object.
    /// If the postboxkey was not yet migrated it will be migrated to MFA.
    /// Even if the flag `initialize` is not given. Unfortunately we cannot detect reliably if a key is SFA or MFA.
    /// And calling ThresholdKey.initialize() will convert it.
    ///
    /// - Parameters:
    ///   - postBoxKey: Key returned by CustomAuth
    ///   - publicAddress: Used as a key to store the shares in the KeyChain
    ///   - password: If given used as one share (optional)
    ///   - initialize: If given, init() assumes it is called on a postBoxKey that is still on SFA.
    ///
    /// - Returns: `Web3AuthMFAService`
    ///
    /// - Throws: `RuntimeError`, indicates the setup failed. Password wrong, not enough shares to recover key, etc.
    init(postBoxKey: String,
         publicAddress: String,
         password: String? = nil, // if not nil, use to create a password share on initialize otherwise used to unlock the key
         keychainInterface: KeychainInterface = SimpleKeychainInterface(identifier: "web3auth.tkey-ios") // "web3auth.tkey-ios" "global.safe.tkey-ios"
    ) async throws {

        self.keychainInterface = keychainInterface
        self.postBoxKey = postBoxKey
        LogService.shared.debug("---> postboxkey: \(postBoxKey)")
        self.publicAddress = publicAddress
        LogService.shared.debug("---> publicAddress: \(publicAddress)")
        self.shareMissing = false
        self.password = password

        guard let storage_layer = try? StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2) else {
            throw("Failed to create storage layer")
        }

        guard let service_provider = try? ServiceProvider(enable_logging: true, postbox_key: postBoxKey) else {
            throw("Failed to create service provider")
        }

        guard let thresholdKey = try? ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false) else {
            throw("Failed to create threshold key")
        }

        self.thresholdKey = thresholdKey
    }

    func initialReconstruct() async throws {

        // This is the first time initialize is called on a threshold key derived by this postbox key. That means a device share is created automatically.
        // We must save this device share to the keychain if this is a trudted device. Otherwise we do not save it.
        // we must add the password share if we're given a password

        LogService.shared.debug("---> initialSetup()")

        guard let key_details = try? await thresholdKey.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false) else {
            throw("Failed to get key details")
        }

        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true
            throw("Failed to reconstruct key. \(key_details.required_shares) more share(s) required.") // this should not happen when using initialsetup on an SFA-Key
        }

        var shareIndexes = try thresholdKey.get_shares_indexes()
        shareIndexes.removeAll(where: {$0 == "1"}) // apparently 1 is the postboxkey share

        guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[0], shareType: nil) else {
            throw("Failed to output share")
        }
        guard let _ = try? keychainInterface.save(item: share, key: "\(publicAddress):device-key") else {
            throw("Failed to save share")
        }

        if let password = password {
            let question = "what's your password?"
            let _ = try await SecurityQuestionModule.generate_new_share(threshold_key: thresholdKey, questions: question, answer: password)
            LogService.shared.debug("---> password correct or set for the first time")
        }
    }

    /// set up a key to be used as an MFA key
    func reconstruct() async throws {
        LogService.shared.debug("---> setup()")

        // Find device share in Keychain
        let deviceShare = try? keychainInterface.fetch(key: "\(publicAddress):device-key")

        guard let key_details = try? await thresholdKey.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false) else {
            throw("Failed to get key details")
        }
        threshold = Int(key_details.threshold)
        LogService.shared.debug("---> threshold: \(threshold)")

        if let deviceShare = deviceShare {
            // device share found
            LogService.shared.debug("---> device share found")
            try await thresholdKey.input_share(share: deviceShare, shareType: nil)
        }

        if let password = password {
            // password given
            guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: password) else {
                throw("input share failed. Make sure threshold key is initialized")
            }

            LogService.shared.debug("---> password correct")
            if !result {
                throw("password incorrect")
            }
        }

        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true
            throw("Failed to reconstruct key with available shares.")
        }
        LogService.shared.debug("---> key reconstructed.")
        shareMissing = false

        finalKey = reconstructionDetails.key
    }
}
