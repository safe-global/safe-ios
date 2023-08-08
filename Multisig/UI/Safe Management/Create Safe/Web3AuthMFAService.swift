//
//  Web3AuthMFAService.swift
//  Multisig
//
//  Created by Dirk Jäckel on 08.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import tkey_pkg

// activate MFS by either
// 1. adding the current device as a trusted device or
// 2. Setting a password

class Web3AuthMFAService {

    // if the device share is missing and also no password has been provided
    var shareMissing: Bool
    var finalKey: String?
    private var password: String?

    private var isAlreadyMFA = true
    private let postBoxKey: String
    private let publicAddress: String
    private var thresholdKey: ThresholdKey?
    private var threshold = 0

    static func mfaEnabled(userInfo: [String: Any]) -> Bool {

        // in future version od the SDK there will be an entry called "nonce". If 0, then mfsa is enabled

        // For now we whitelist adresses

        let email = userInfo["email"] as? String

        return email == "bttr.tstr@gmail.com" || email == "ego.other@gmail.com"
    }

    // this activates MFA if not already activated
    func setupPassword(password: String) {

        // check if there is already a password set?

    }

    // this activates MFA if not already activated
    func setupTrustedDevice() {


    }

    // if there is no device share, we need a password to restore the final key
    func inputPassword(password: String) {
        self.password = password
    }



    init(postBoxKey: String, publicAddress: String, password: String? = nil) async throws {

        self.postBoxKey = postBoxKey
        print("---> postboxkey: \(postBoxKey)")
        self.publicAddress = publicAddress
        print("---> publicAddress: \(publicAddress)")
        self.shareMissing = false
        self.password = password

        // TODO look for device share

        if isAlreadyMFA {
            // prepare
            try await setup()
        }

    }

    private func setup() async throws {
        print("---> setup()")
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

        //        Task {
        guard let key_details = try? await thresholdKey.initialize(never_initialize_new_key: false, include_local_metadata_transitions: false) else {
            throw("Failed to get key details")
        }
        //        totalShares = Int(key_details.total_shares)
        threshold = Int(key_details.threshold)
        //        tkeyInitalized = true

        print("---> threshold: \(threshold)")

        if let deviceShare = try? KeychainInterface.fetch(key: "\(publicAddress):device-key") {
            // device share found


            try await thresholdKey.input_share(share: deviceShare, shareType: nil)

        } else {
            // no device share found
            print("---> no device share found")
            //                guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            //                     throw("Failed to reconstruct key. \(key_details.required_shares) more share(s) required. If you have security question share, we suggest you to enter security question PW to recover your account")
            //                }
            //                var shareIndexes = try thresholdKey.get_shares_indexes()
            //                shareIndexes.removeAll(where: {$0 == "1"}) // apparently 1 is the postbox share
            //
            //                guard let share = try? thresholdKey.output_share(shareIndex: shareIndexes[0], shareType: nil) else {
            //                    throw("Failed to output share")
            //                }
            //
            //                guard let _ = try? KeychainInterface.save(item: share, key: "\(publicAddress):device-key") else {
            //                    throw("Failed to save share")
            //                }
            //
            //                guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            //                    throw("Failed to reconstruct key. \(key_details.required_shares) more share(s) required.")
            //                }


            // try await thresholdKey.input_share(share: passwordShare, shareType: nil)




        }
        if let password = password {
            guard let result = try? await SecurityQuestionModule.input_share(threshold_key: thresholdKey, answer: password) else {
                throw("input share failed. Make sure threshold key is initialized")
            }
            print("---> password correct")
            if !result {
                throw("password incorrect")
            }
        }


        guard let reconstructionDetails = try? await thresholdKey.reconstruct() else {
            shareMissing = true
            throw("Failed to reconstruct key with available shares.")
        }
        print("---> key reconstructed.")
        shareMissing = false

        finalKey = reconstructionDetails.key


    }





    //    }



    
}
