import Foundation
import CustomAuth
import UIKit

class GoogleWeb3AuthLoginModel {
    let notificationCenter = NotificationCenter.default
    static let schemePostfix = "://"
    var authorizationComplete: () -> Void
    var keyGenerationComplete: ((_ key: String, _ email: String?) -> Void)

    init(authorizationComplete: @escaping () -> Void, keyGenerationComplete: @escaping ((_ key: String, _ email: String?) -> Void)) {
        self.authorizationComplete = authorizationComplete
        self.keyGenerationComplete = keyGenerationComplete

        notificationCenter.addObserver(self, selector: #selector(handleAuthorizationComplete), name: NSNotification.Name("TSDSDKCallbackNotification"), object: nil)
    }

    func loginWithCustomAuth() {
        Task {
            let sub = SubVerifierDetails(loginType: .installed,
                                         loginProvider: .google,
                                         clientId: App.configuration.web3auth.googleClientId,
                                         verifier: App.configuration.web3auth.googleVerifier,
                                         redirectURL: App.configuration.web3auth.redirectScheme + GoogleWeb3AuthLoginModel.schemePostfix
            )
            let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                                   aggregateVerifier: App.configuration.web3auth.googleVerifier,
                                   subVerifierDetails: [sub],
                                   network: .CYAN
            )

            let data = try await tdsdk.triggerLogin(browserType: .asWebAuthSession)
            await MainActor.run(body: {
                let key = data["privateKey"] as? String
                let userInfo = data["userInfo"] as? Dictionary ?? [:] as Dictionary
                let email = userInfo["email"] as? String ?? "email withheld"

                keyGenerationComplete(key!, email)
            })
        }
    }

    @objc
    func handleAuthorizationComplete() {
        authorizationComplete()
    }
}
