import Foundation
import CustomAuth
import UIKit

class LoginModel: ObservableObject {
    @Published var loggedIn: Bool = false
    @Published var isLoading = false
    @Published var navigationTitle: String = ""
    @Published var userData: [String: Any]!

    var onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    
    func setup() async {
        await MainActor.run(body: {
            isLoading = true
            navigationTitle = "Loading"
        })
        await MainActor.run(body: {
            if self.userData != nil {
                loggedIn = true
            }
            isLoading = false
            navigationTitle = loggedIn ? "UserInfo" : "SignIn"
        })
    }

    func loginWithCustomAuth(caller: UIViewController) {
        Task {
            let sub = SubVerifierDetails(loginType: .web,
                                         loginProvider: .google,
                                         clientId: "443535743496-p5quu0qi2c81ceq42dgubmjgmhokovq5.apps.googleusercontent.com", // web
                                         verifier: "google-web-prod-mainnet",
                                         redirectURL: "https://safe-wallet-web.staging.5afe.dev/web3auth/"

            )
            let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                                   aggregateVerifier: "google-web-prod-mainnet",
                                   subVerifierDetails: [sub],
                                   network: .CYAN,
                                   loglevel: .debug
            )
            let data = try await tdsdk.triggerLogin(controller: caller)
            await MainActor.run(body: {
                self.userData = data
                dump(data, name: "Data ")
                loggedIn = true

                onClose()
                caller.closeModal()
            })
        }
    }

}
