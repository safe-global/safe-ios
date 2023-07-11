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
            // Create an account in your system.
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
                    onClose()
                })
            }
                // TODO this need to be tested
        case let passwordCredential as ASPasswordCredential:

            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password

            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                self.showPasswordCredentialAlert(username: username, password: password)
            }

        default:
            break
        }
    }

    //TODO How to test this?
    private func showPasswordCredentialAlert(username: String, password: String) {
        let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
        let alertController = UIAlertController(title: "Keychain Credential Received",
                message: message,
                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        //self.present(alertController, animated: true, completion: nil)
    }

    /// - Tag: did_complete_error
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Most likely the user canceled the authorization request.
        dump(error, name: "Error")
        if error._code != 1001 {
            LogService.shared.error("Error: \(error)")
            App.shared.snackbar.show(message: "Error: \(error)")

        } else {
            LogService.shared.debug("User canceled the authorization request")
            App.shared.snackbar.show(message: "User canceled the authorization request")
        }
    }
}
