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
                        network: .CYAN,
                        enableOneKey: true
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
                    
                    await MainActor.run(body: { [weak self] in
                        guard let self = self else { return }
                        let key = data["privateKey"] as? String
                        if let key = key {
                            self.keyGenerationComplete(key, email, nil)
                        } else {
                            let error = GSError.Web3AuthGenericError(underlyingError: "No key generated/found")
                            self.keyGenerationComplete(nil, nil, error)
                        }
                    })
                } catch {
                    await MainActor.run(body: { [weak self] in
                        self?.keyGenerationComplete(nil, nil, error)
                    })
                }
            }
        default:
            keyGenerationComplete(nil, nil, "Apple ID authorization failed (missing credentials)")
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        keyGenerationComplete(nil, nil, humanReadableError(error))
    }
    
    func humanReadableError(_ error: Error) -> String {
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled: return "The user canceled the authorization attempt."
            case .failed: return "The authorization attempt failed."
            case .invalidResponse: return "The authorization request received an invalid response."
            case .notHandled: return "The authorization request was not handled."
            case .unknown: return "The authorization attempt failed for an unknown reason."
            default: return "The authorization attempt failed for an unknown reason."
            }
        } else {
            return "Unexpected error received"
        }
    }
}
