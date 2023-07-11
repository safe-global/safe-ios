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

            dump(appleIDCredential, name: "appleIDCredential")
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user

            let token = String(data: appleIDCredential.identityToken!, encoding: .utf8)!
            LogService.shared.debug("Raw JWT token: \(token)")

            let JWT = try? JWTDecode.decode(jwt: token)

            dump(JWT, name: "Decoded JWT")
            let claim = JWT?.claim(name: "sub")
            guard let sub = claim?.string else {
                return
            }
            LogService.shared.debug("Sub: \(sub)")
            LogService.shared.debug("Using Web3Auth verifier called: \(App.configuration.web3auth.appleVerifier)")

            Task {
                let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                        aggregateVerifier: App.configuration.web3auth.appleVerifier,
                        subVerifierDetails: [],
                        network: .CYAN,
                        loglevel: .debug
                )

                let data = try await tdsdk.getAggregateTorusKey(verifier: App.configuration.web3auth.appleVerifier,
                        verifierId: sub,
                        idToken: token,
                        subVerifierDetails: SubVerifierDetails(
                                loginType: .web,
                                loginProvider: .jwt,
                                clientId: "",
                                //clientId: App.configuration.web3auth.appleClientId,
                                verifier: App.configuration.web3auth.appleVerifier,
                                redirectURL: "")
                )



                /// Retrieve the Torus key from the nodes given an already known token. Useful if a custom aggregate login flow is required.
                /// - Parameters:
                ///   - verifier: A verifier is a unique identifier for your OAuth registration on the torus network. The public/private keys generated for a user are scoped to a verifier.
                ///   - verifierId: The unique identifier to publicly represent a user on a verifier. e.g: email, sub etc. other fields can be classified as verifierId,
                ///   - subVerifierDetails: An array of verifiers to be used for the aggregate login flow, with their respective token and verifier name.
                /// - Returns: A promise that resolve with a Dictionary that contain at least `privateKey` and `publicAddress` field..
                /// open func getAggregateTorusKey(verifier: String,
                /// verifierId: String,
                /// idToken: String,
                /// subVerifierDetails: SubVerifierDetails,
                /// userData: [String: Any] = [:]) async throws -> [String: Any] {


//                public struct SubVerifierDetails {
//                    public let loginType: SubVerifierType
//                    public let clientId: String
//                    public let verifier: String
//                    public let loginProvider: LoginProviders
//                    public let redirectURL: String
//                    public let handler: AbstractLoginHandler
//                    public var urlSession: URLSession
//
//                    public enum codingKeys: String, CodingKey {
//                        case clientId
//                        case loginProvider
//                        case subVerifierId
//                    }
//
//                    public init(loginType: SubVerifierType = .web,
//            loginProvider: LoginProviders,
//            clientId: String,
//            verifier: String,
//            redirectURL: String,
//            browserRedirectURL: String? = nil,
//            jwtParams: [String: String] = [:],
//            urlSession: URLSession = URLSession.shared) {
//                        self.loginType = loginType
//                        self.clientId = clientId
//                        self.loginProvider = loginProvider
//                        self.verifier = verifier
//                        self.redirectURL = redirectURL
//                        self.urlSession = urlSession
//                        handler = self.loginProvider.getHandler(loginType: loginType, clientID: self.clientId, redirectURL: self.redirectURL, browserRedirectURL: browserRedirectURL, jwtParams: jwtParams, urlSession: urlSession)
//                    }



                await MainActor.run(body: {
                    dump(data, name: "---> getAggregateTorusKey() result: ")
                    // App.shared.snackbar.show(message: "Private Key: \(data["privateKey"] as? String)")
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
