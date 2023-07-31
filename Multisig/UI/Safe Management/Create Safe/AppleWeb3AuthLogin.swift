import Foundation
import AuthenticationServices
import CustomAuth
import JWTDecode
import UIKit

class AppleWeb3AuthLogin: NSObject {
    var authorizationComplete: () -> Void
    var keyGenerationComplete: ((_ key: String?, _ email: String?, _ error: Error?) -> Void)

    init(
        authorizationComplete: @escaping () -> Void,
        keyGenerationComplete: @escaping ((_ key: String?, _ email: String?, _ error: Error?) -> Void)
    ) {
        self.authorizationComplete = authorizationComplete
        self.keyGenerationComplete = keyGenerationComplete
    }
}

extension AppleWeb3AuthLogin: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        authorizationComplete()
        
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let userIdentifier = appleIDCredential.user

            let token = String(data: appleIDCredential.identityToken!, encoding: .utf8)!
            let JWT = try? JWTDecode.decode(jwt: token)
            let subClaim = JWT?.claim(name: "sub")
            guard let sub = subClaim?.string else {
                return
            }
            let emailClaim = JWT?.claim(name: "email")
            let email = emailClaim?.string ?? "email address withheld"

            Task {
                let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                        aggregateVerifier: App.configuration.web3auth.appleVerifier,
                        subVerifierDetails: [],
                        network: .CYAN
                )

                do {
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
                        let key = data["privateKey"] as? String
                        if let key = key {
                            keyGenerationComplete(key, email, nil)
                        } else {
                            let error = GSError.Web3AuthGenericError(underlyingError: "No key generated/found")
                            keyGenerationComplete(nil, nil, error)
                        }
                    })
                } catch {
                    await MainActor.run(body: {
                        keyGenerationComplete(nil, nil, error)
                    })
                }

                
            }
        default:
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

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
                case .canceled: App.shared.snackbar.show(message: "The user canceled the authorization attempt.")
                case .failed: App.shared.snackbar.show(message: "The authorization attempt failed.")
                case .invalidResponse: App.shared.snackbar.show(message: "The authorization request received an invalid response.")
                case .notHandled: App.shared.snackbar.show(message: "The authorization request was not handled.")
                case .unknown: App.shared.snackbar.show(message: "The authorization attempt failed for an unknown reason.")
                default: App.shared.snackbar.show(message: "The authorization attempt failed for an unknown reason.")
            }
        } else {
            App.shared.snackbar.show(message: "Unexpected error received")
        }
    }
}
