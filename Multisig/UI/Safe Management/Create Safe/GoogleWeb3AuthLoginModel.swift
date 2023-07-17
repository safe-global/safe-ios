import Foundation
import CustomAuth
import UIKit

class GoogleWeb3AuthLoginModel {
    var onClose: ((_ key: String?, _ email: String?) -> Void)

    init(onClose: @escaping ((_ key: String?, _ email: String?) -> Void)) {
        self.onClose = onClose
    }

    static func handle(url: URL) -> Bool {
        if url.absoluteString.starts(with: App.configuration.web3auth.redirectUrl) {
            CustomAuth.handle(url: url)
            return true
        }
        return false
    }

    func loginWithCustomAuth(caller: UIViewController) {
        Task {
            let sub = SubVerifierDetails(loginType: .installed,
                                         loginProvider: .google,
                                         clientId: App.configuration.web3auth.googleClientId,
                                         verifier: App.configuration.web3auth.googleVerifier,
                                         redirectURL: App.configuration.web3auth.redirectUrl
            )
            let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                                   aggregateVerifier: App.configuration.web3auth.googleVerifier,
                                   subVerifierDetails: [sub],
                                   network: .CYAN
            )
            let data = try await tdsdk.triggerLogin(controller: caller)
            await MainActor.run(body: {
                let key = data["privateKey"] as? String
                let userInfo = data["userInfo"] as? Dictionary ?? [:] as Dictionary
                let email = userInfo["email"] as? String ?? "email withheld"

                onClose(key, email)
                caller.closeModal()
            })
        }
    }
}
