import Foundation
import CustomAuth

class LoginModel: ObservableObject {
    @Published var loggedIn: Bool = false
    @Published var isLoading = false
    @Published var navigationTitle: String = ""
    @Published var userData: [String: Any]!

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

    func loginWithCustomAuth() {
        Task {
            let sub = SubVerifierDetails(loginType: .web, // .installed,
                                         loginProvider: .google,
//                                         clientId: "500572929132-57dbeqrtq84m5oibve186vfmdd6p5rmh.apps.googleusercontent.com", // ios
                                         clientId: "500572929132-4735prr2svs7qphpmgdu5bgcvq3cdkr4.apps.googleusercontent.com", // web
                                         verifier: "test-custom-web-safe",
                                         redirectURL: "https://safe-wallet-web.staging.5afe.dev/"

            )
            let tdsdk = CustomAuth(aggregateVerifierType: .singleLogin,
                                   aggregateVerifier: "test-custom-web-safe",
                                   subVerifierDetails: [sub],
                                   network: .TESTNET,
                                   loglevel: .debug
            )
            let data = try await tdsdk.triggerLogin()
            await MainActor.run(body: {
                self.userData = data
                dump(data, name: "Data ")
                loggedIn = true
            })
        }
    }

}
