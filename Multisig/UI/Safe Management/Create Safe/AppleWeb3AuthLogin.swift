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
    /// - Tag: did_complete_authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:

            dump(appleIDCredential, name: "appleIDCredential")
            // Create an account in your system.
            let userIdentifier = appleIDCredential.user
//            let fullName = appleIDCredential.fullName
//            let email = appleIDCredential.email

            let token = String(data: appleIDCredential.identityToken!, encoding: .utf8)!
            print("---> raw token: \(token)")

            let JWT = try? JWTDecode.decode(jwt: token)

            dump(JWT, name: "---> JWT")
            let claim = JWT?.claim(name: "sub")

            dump(claim, name: "--->  claim")

            guard let sub = claim?.string else {
                print("---> sub missing")
                return
            }
            print ("---> sub: \(sub)")
            print ("---> using verifier: \(App.configuration.web3auth.appleVerifier)")



            Task {
                // initializeSDK
                print("---> initializeSDK: ")
                let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                                       aggregateVerifier: App.configuration.web3auth.appleVerifier,
                                       subVerifierDetails: [],
                                       network: .CYAN,
                                       loglevel: .debug
                )

                print("---> Calling getTorusKey() ")

                let data = try await tdsdk.getTorusKey(verifier: App.configuration.web3auth.appleVerifier,
                                                       verifierId: sub,
                                                       idToken: token
                )
                print("---> Calling getTorusKey()  -> DONE")


                //{ data in
                await MainActor.run(body: {
                    dump(data, name: "---> getTorusKey() result: ")
                    App.shared.snackbar.show(message: "Private Key: \(data["privateKey"] as? String)")

                })
            }
            // For the purpose of this demo app, store the `userIdentifier` in the keychain.
//            self.saveUserInKeychain(userIdentifier)

            // For the purpose of this demo app, show the Apple ID credential information in the `ResultViewController`.
            // self.showResultViewController(userIdentifier: userIdentifier, fullName: fullName, email: email)

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
        // Handle error.
    }
}
