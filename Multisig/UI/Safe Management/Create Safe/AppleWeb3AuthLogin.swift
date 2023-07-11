import Foundation
import AuthenticationServices
import CustomAuth
import JWTDecode
import UIKit

class AppleWeb3AuthLogin: NSObject {
    var onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
}

extension AppleWeb3AuthLogin: ASAuthorizationControllerDelegate {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIDCredential.user

            let token = String(data: appleIDCredential.identityToken!, encoding: .utf8)!
            let JWT = try? JWTDecode.decode(jwt: token)
            let claim = JWT?.claim(name: "sub")
            guard let sub = claim?.string else {
                return
            }

            Task {
                let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                        aggregateVerifier: App.configuration.web3auth.appleVerifier,
                        subVerifierDetails: [],
                        network: .CYAN
                )

                let data = try await tdsdk.getAggregateTorusKey(verifier: App.configuration.web3auth.appleVerifier,
                        verifierId: sub,
                        idToken: token,
                        subVerifierDetails: SubVerifierDetails(
                                loginType: .installed,
                                loginProvider: .jwt,
                                clientId: "",
                                verifier: App.configuration.web3auth.appleSubVerifier,
                                redirectURL: "")
                )

                await MainActor.run(body: {
                    App.shared.snackbar.show(message: "Private Key: \(data["privateKey"] as? String)")
                    // TODO pass private key to the next screen
                    onClose()
                })
            }
        default:
            LogService.shared.debug("AppleId authorization failed")
            App.shared.snackbar.show(message: "AppleId authorization failed")
            break
        }
    }

    private func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                message: message,
                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
    }

    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Most likely the user canceled the authorization request.
        if error._code != 1001 {
            LogService.shared.error("Error: \(error)")
            App.shared.snackbar.show(message: "Error: \(error)")

        } else {
            LogService.shared.debug("User canceled the authorization request")
            App.shared.snackbar.show(message: "User canceled the authorization request")
        }
    }
}
