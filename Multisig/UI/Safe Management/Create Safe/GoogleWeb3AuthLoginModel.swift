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
            let sub = SubVerifierDetails(
                loginType: .installed,
                loginProvider: .google,
                clientId: App.configuration.protected[.WEB3AUTH_GOOGLE_CLIENT_ID],
                verifier: App.configuration.protected[.WEB3AUTH_GOOGLE_VERIFIER_SUB],
                redirectURL: App.configuration.protected[.WEB3AUTH_REDIRECT_SCHEME] + GoogleWeb3AuthLoginModel.schemePostfix
            )
            let tdsdk = CustomAuth(aggregateVerifierType: .singleIdVerifier,
                                   aggregateVerifier: App.configuration.protected[.WEB3AUTH_GOOGLE_VERIFIER_AGGREGATE],
                                   subVerifierDetails: [sub],
                                   network: .CYAN,
                                   enableOneKey: true
            )

            do {
                let data = try await tdsdk.triggerLogin(browserType: .asWebAuthSession)
                
                await MainActor.run(body: { [weak self] in
                    guard let self = self else { return }
                    let key = data["privateKey"] as? String
                    let userInfo = data["userInfo"] as? [String: Any] ?? [:]
                    let email = userInfo["email"] as? String ?? "email withheld"

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
