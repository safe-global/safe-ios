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

    private let keychainService: SecureStore!
    private var isAlreadyMFA = true
    private let postBoxKey: String
    private let publicAddress: String
    private var thresholdKey: ThresholdKey
    private var threshold = 0
    private let question = "PASSWORD"

    static func mfaEnabled(userInfo: [String: Any]) -> Bool {
        // TODO: in future version of the SDK there will be an entry called "nonce". If nonce == 0, then mfa is enabled

        // For now we whitelist adresses
        let email = userInfo["email"] as? String

        return email == "ego.other@gmail.com" || email == "dirk@safe.global"
    }

    func setupPassword(password: String) async throws {
        let _ = try await SecurityQuestionModule.generate_new_share(threshold_key: thresholdKey, questions: question, answer: password)
    }

    /// this is used to unlock the key. Can also be done in init()
    func inputPassword(password: String) async throws {
        self.password = password

        guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: password) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "input share failed. Make sure threshold key is initialized")
        }
        if !result {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "password incorrect")
        }
    }

    func changePassword(oldPassword: String, newPassword: String) async throws {
        // password given
        guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: oldPassword) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "input share failed. Make sure threshold key is initialized")
        }
        if !result {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "old password incorrect")
        }

        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true

            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to reconstruct key. More share(s) required.")
        }

        let changeResult = try await SecurityQuestionModule.change_question_and_answer(threshold_key: thresholdKey, questions: question, answer: newPassword)
        if !changeResult {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Password not changed")
        }
    }

    /// This is used on a new device after the user logged in with their social login and we detect, that we cannot
    /// recreate the final key because we're missing the device share. We need to ask the user for their password
    /// to recreate the device share and reconstruct the final key
    func recreateDeviceShare(password: String? = nil) async throws {
        if let password = password {
            guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: password) else {
                throw GSError.Web3AuthKeyReconstructionError(underlyingError: "password input share failed. Make sure threshold key is initialized")
            }
            if !result {
                throw GSError.Web3AuthKeyReconstructionError(underlyingError: "password incorrect")
            }
        }
        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to reconstruct key. more share(s) required.")
        }

        guard let generateShareStoreResult = try? await thresholdKey.generate_new_share() else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed create new share")
        }

        guard let share = try? thresholdKey.output_share(shareIndex: generateShareStoreResult.hex, shareType: nil) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to output share")
        }

        guard let _ = try? keychainService.save(data: Data(share.utf8), forKey: "\(publicAddress):device-key") else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to save share")
        }
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
         keychainService: SecureStore = KeychainService(identifier: "global.safe.tkey-ios") // "web3auth.tkey-ios"
    ) async throws {

        self.keychainService = keychainService
        self.postBoxKey = postBoxKey
        self.publicAddress = publicAddress
        self.shareMissing = false
        self.password = password

        guard let storage_layer = try? StorageLayer(enable_logging: true, host_url: "https://metadata.tor.us", server_time_offset: 2) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to create storage layer")
        }

        guard let service_provider = try? ServiceProvider(enable_logging: true, postbox_key: postBoxKey) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to create service provider")
        }

        guard let thresholdKey = try? ThresholdKey(
            storage_layer: storage_layer,
            service_provider: service_provider,
            enable_logging: true,
            manual_sync: false) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to create threshold key")
        }

        self.thresholdKey = thresholdKey
    }

    func initialReconstruct() async throws {

        // This is the first time initialize is called on a threshold key derived by this postbox key. That means a device share is created automatically.
        // We must save this device share to the keychain if this is a trudted device. Otherwise we do not save it.
        // we must add the password share if we're given a password

        guard let key_details = try? await thresholdKey.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false) else {
            throw RuntimeError("Failed to get key details")
        }

        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to reconstruct key. \(key_details.required_shares) more share(s) required.") // this should not happen when using initialsetup on an SFA-Key
        }

        var shareIndexes = try thresholdKey.get_shares_indexes()
        shareIndexes.removeAll(where: {$0 == "1"}) // apparently 1 is the postboxkey share

        guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[0], shareType: nil) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to output share")
        }
        guard let _ = try? keychainService.save(data: Data(share.utf8), forKey: "\(publicAddress):device-key") else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to save share")
        }

        if let password = password {
            let _ = try await SecurityQuestionModule.generate_new_share(threshold_key: thresholdKey, questions: question, answer: password)
        }
    }

    /// set up a key to be used as an MFA key
    func reconstruct() async throws {
        // Find device share in Keychain
        let deviceShare = try? keychainService.data(forKey: "\(publicAddress):device-key")

        guard let key_details = try? await thresholdKey.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false) else {
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to get key details")
        }
        threshold = Int(key_details.threshold)

        if let deviceShare = deviceShare {
            let deviceShareString = String(decoding: deviceShare, as: UTF8.self)
            do {
                try await thresholdKey.input_share(share: deviceShareString, shareType: nil)
            } catch {
                throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to input device share")
            }
        }

        if let password = password {
            // password given
            guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: password) else {
                throw GSError.Web3AuthKeyReconstructionError(underlyingError: "input share failed. Make sure threshold key is initialized")
            }
            if !result {
                throw GSError.Web3AuthKeyReconstructionError(underlyingError: "password incorrect")
            }
        }

        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true
            throw GSError.Web3AuthKeyReconstructionError(underlyingError: "Failed to reconstruct key with available shares.")
        }
        shareMissing = false

        finalKey = reconstructionDetails.key
    }
}
