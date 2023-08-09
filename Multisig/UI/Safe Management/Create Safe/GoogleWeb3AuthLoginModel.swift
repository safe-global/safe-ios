import Foundation
import CustomAuth
import UIKit

class GoogleWeb3AuthLoginModel {
    let notificationCenter = NotificationCenter.default
    static let schemePostfix = "://"
    var authorizationComplete: (() -> Void)!
    var keyGenerationComplete: ((_ key: String?, _ email: String?, _ error: Error?) -> Void?)!

    init() {
        notificationCenter.addObserver(self, selector: #selector(handleAuthorizationComplete), name: NSNotification.Name("TSDSDKCallbackNotification"), object: nil)
    }

    func loginWithCustomAuth() {
        Task {
            let sub = SubVerifierDetails(loginType: .installed,
                                         loginProvider: .google,
                                         clientId: "500572929132-57dbeqrtq84m5oibve186vfmdd6p5rmh.apps.googleusercontent.com",
                                         verifier: "google-sub-bttr-500572929132",
                                         redirectURL: "com.googleusercontent.apps.500572929132-57dbeqrtq84m5oibve186vfmdd6p5rmh://"

            )
            let tdsdk = CustomAuth(aggregateVerifierType: .singleIdVerifier,
                                   aggregateVerifier: "google-aggregate-bttr",
                                   subVerifierDetails: [sub],
                                   network: .CYAN,
                                   enableOneKey: true
            )

            do {
                let data = try await tdsdk.triggerLogin(browserType: .asWebAuthSession)
                
                await MainActor.run(body: { [weak self] in
                    guard let self = self else { return }
                    let key = data["privateKey"] as? String
                    let publicAddress = data["publicAddress"] as? String
                    let userInfo = data["userInfo"] as? [String: Any] ?? [:]
                    let email = userInfo["email"] as? String ?? "email withheld"

//                    if Web3AuthMFAService.mfaEnabled(userInfo: userInfo) {
//                        Task {
//                            do {
//                                // we assume the device share is available. Otherwise the password is needed
//                                let web3authService = try await Web3AuthMFAService(postBoxKey: key!, publicAddress: publicAddress!)
//                                LogService.shared.debug("---> init succesful")
//                                try await web3authService.reconstruct()
//                                try await web3authService.changePassword(oldPassword: "foobar23", newPassword: "foobar23")
//                                let finalKey = web3authService.finalKey
//                                LogService.shared.debug("---> finalKey: \(finalKey)")
//
////                                try await web3authService.inputPassword(password: "foobar23")
//
//                                
////                                try await web3authService.changePassword(oldPassword: "foobar23", newPassword: "foobar2342")
////                                LogService.shared.debug("---> First password change completed")
////                                try await web3authService.changePassword(oldPassword: "foobar2342", newPassword: "foobar23")
////                                LogService.shared.debug("---> Second password change completed")
//
//                                self.keyGenerationComplete(finalKey!, email + "_mfa", nil)
//                            } catch {
//                                LogService.shared.error("---> error: \(error)")
//                                do {
//                                    let web3authService = try await Web3AuthMFAService(postBoxKey: key!, publicAddress: publicAddress!)
//                                    LogService.shared.debug("---> init succesful")
//                                    try await web3authService.recoverDeviceShare(password: "foobar23")
//                                    LogService.shared.debug("---> Recovery succesful")
//                                } catch {
//                                    LogService.shared.debug("---> Recovery failed")
//                                }
//                                await MainActor.run(body: { [weak self] in
//                                    self?.keyGenerationComplete(nil, nil, error)
//                                })
//                            }
//                        }
//                    } else {
//                        Task {
//                            do {
//                                let web3authService = try await Web3AuthMFAService(postBoxKey: key!, publicAddress: publicAddress!, password: "foobar2342")
//                                try await web3authService.initialReconstruct()
//                                let finalKey = web3authService.finalKey
//                                print ("---> finalKey: \(finalKey)")
//                                self.keyGenerationComplete(finalKey!, email + "_mfa", nil)
//                            } catch {
//                                LogService.shared.error("---> error: \(error)")
//                                await MainActor.run(body: { [weak self] in
//                                    self?.keyGenerationComplete(nil, nil, error)
//                                })
//                            }
//                        }
//
//                        //self.keyGenerationComplete(key!, email, nil)
//                    }
                    self.keyGenerationComplete(key!, email, nil)
                })
            } catch {
                await MainActor.run(body: { [weak self] in
                    self?.keyGenerationComplete(nil, nil, error)
                })
            }
        }
    }

    @objc
    func handleAuthorizationComplete() {
        authorizationComplete()
        notificationCenter.removeObserver(self)
    }
}
