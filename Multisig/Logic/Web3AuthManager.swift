//
//  Web3AuthManager.swift
//  Multisig
//
//  Created by Mouaz on 6/10/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import CustomAuth
class Web3AuthManager {
    static let shared = Web3AuthManager()

    private init() { }

    //    func loginGoogle() async {
//        let sub = SubVerifierDetails(loginType: .web,
//                                     loginProvider: .google,
//                                     clientId: "221898609709-obfn3p63741l5333093430j3qeiinaa8.apps.googleusercontent.com",
//                                     verifier: "google-lrc",
//                                     redirectURL: "tdsdk://tdsdk/oauthCallback",
//                                     browserRedirectURL: "https://scripts.toruswallet.io/redirect.html")
//
//        let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin, aggregateVerifier: "google-lrc", subVerifierDetails: [sub], network: .TESTNET)
//        do {
//            try await tdsdk.triggerLogin()
//        } catch {
//
//        }
//    }
//
//    func loginApple() async {
//        let sub = SubVerifierDetails(loginType: .web,
//                                     loginProvider: .apple,
//                                     clientId: "m1Q0gvDfOyZsJCZ3cucSQEe9XMvl9d9L",
//                                     verifier: "torus-auth0-apple-lrc",
//                                     redirectURL: "tdsdk://tdsdk/oauthCallback",
//                                     jwtParams: ["domain": "torus-test.auth0.com"])
//
//        let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin, aggregateVerifier: "torus-auth0-apple-lrc", subVerifierDetails: [sub], network: .TESTNET)
//        do {
//            try await tdsdk.triggerLogin()
//        } catch {
//
//        }
//    }
}
