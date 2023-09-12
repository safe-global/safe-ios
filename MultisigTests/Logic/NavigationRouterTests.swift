//
//  DefaultNavigationRouterTests.swift
//  MultisigTests
//
//  Created by Dmitrii Bespalov on 21.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

let BASE_URL = "https://some.host"

final class DefaultNavigationRouterTests: XCTestCase {

    let router = DefaultNavigationRouter()

    func testAssets() {
        let url = "\(BASE_URL)/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/balances"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }

    func testHistory() {
        let url = "\(BASE_URL)/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/transactions/history"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/history/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testQueue() {
        let url = "\(BASE_URL)/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/transactions/queue"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/queued/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }

    func testTransactionDetails() {
        let url = "\(BASE_URL)/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/transactions/some_identifier"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/details/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
        XCTAssertEqual(route?.info["transactionId"] as? String, "some_identifier")
    }
    
    func testNotMatching() {
        let url = "\(BASE_URL)/settings"
        let route = router.routeFrom(from: URL(url))
        XCTAssertNil(route)
    }
    
    func testAddressNotValid() {
        let url = "\(BASE_URL)/eth:0x1111111111D19Be20952152c549ee478Bf1bf36b/balances"
        let route = router.routeFrom(from: URL(url))
        XCTAssertNil(route)
    }
    
    func testChainIDNotValid() {
        let url = "\(BASE_URL)/ABC:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/balances"
        let route = router.routeFrom(from: URL(url))
        XCTAssertNil(route)
    }
}

final class ExtendedNavigationRouterTests: XCTestCase {
    let router = ExtendedNavigationRouter()
    
    func testWelcome() {
        let url = "\(BASE_URL)/welcome"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/")
    }
    
    func testHome() {
        let url = "\(BASE_URL)/home"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/")
    }
    
    func testLoadSafe() {
        let url = "\(BASE_URL)/new-safe/load"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/loadSafe")
    }

    func testLoadSafeWithNetwork() {
        let url = "\(BASE_URL)/new-safe/load?chain=eth"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/loadSafe")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testLoadSafeWithNetworkAndAddress() {
        let url = "\(BASE_URL)/new-safe/load?chain=eth&address=0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/loadSafe")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
    }
    
    func testLoadSafeWithAddress() {
        let url = "\(BASE_URL)/new-safe/load?address=0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/loadSafe")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
    }
    
    func testLoadSafeWithPrefixedAddress() {
        let url = "\(BASE_URL)/new-safe/load?address=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/loadSafe")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
    }
    
    func testLoadSafeWithChainAndPrefixedAddress() {
        let url = "\(BASE_URL)/new-safe/load?chain=matic&address=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/loadSafe")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
    }
    
    func testCreateSafe() {
        let url = "\(BASE_URL)/new-safe/create"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/createSafe")
    }

    func testCreateSafeWithNetwork() {
        let url = "\(BASE_URL)/new-safe/create?chain=eth"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/createSafe")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }

    func testAssets() {
        let url = "\(BASE_URL)/balances?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testCollectibles() {
        let url = "\(BASE_URL)/balances/nfts?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/collectibles/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testHistory() {
        let url = "\(BASE_URL)/transactions/history?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/history/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")

    }
    
    func testQueue() {
        let url = "\(BASE_URL)/transactions/queue?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/queued/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")

    }
    
    func testTransactions() {
        let url = "\(BASE_URL)/transactions?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/queued/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testTransactionMessages() {
        let url = "\(BASE_URL)/transactions/messages?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/queued/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }

    func testDetails() {
        let url = "\(BASE_URL)/transactions/tx?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b&id=some-identifier"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/details/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
        XCTAssertEqual(route?.info["transactionId"] as? String, "some-identifier")
    }
    
    func testSettingsMain() {
        let url = "\(BASE_URL)/settings?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testSettingsMainFromData() {
        let url = "\(BASE_URL)/settings/data?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testSettingsMainFromEnvVars() {
        let url = "\(BASE_URL)/settings/environment-variables?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testSettingsAccount() {
        let url = "\(BASE_URL)/settings/setup?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/account")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testSettingsAccountFromSpendingLimits() {
        let url = "\(BASE_URL)/settings/spending-limits?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/account")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testSettingsAppearance() {
        let url = "\(BASE_URL)/settings/appearance?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/appearance")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testSettingsAccountModules() {
        let url = "\(BASE_URL)/settings/modules?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/account/advanced")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testDappsSettings() {
        let url = "\(BASE_URL)/settings/safe-apps?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/dapps/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testCookieSettings() {
        let url = "\(BASE_URL)/settings/cookies?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/advanced")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testAddressBook() {
        let url = "\(BASE_URL)/address-book?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/address-book")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testDapps() {
        let url = "\(BASE_URL)/apps?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/dapps/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testShareDapp() {
        let url = "\(BASE_URL)/share/safe-app?appUrl=https%3A%2F%2Fapp.ens.domains&chain=eth"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/dapps/")
        XCTAssertEqual(route?.info["appUrl"] as? String, "https://app.ens.domains")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testTerms() {
        let url = "\(BASE_URL)/terms"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/about/terms")
    }
    
    func testPrivacy() {
        let url = "\(BASE_URL)/privacy"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/about/privacy")
    }
    
    func testLicenses() {
        let url = "\(BASE_URL)/licenses"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/about/licenses")
    }
    
    func testImprint() {
        let url = "\(BASE_URL)/imprint"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/about")
    }
    
    func testCookie() {
        let url = "\(BASE_URL)/cookie"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/settings/app/about")
    }
}

fileprivate let SUPPORTED_PATH = "/some/path"
fileprivate let UNSUPPORTED_PATH = "/"

final class CompositeNavigationRouterTests: XCTestCase {
    class RouterA: NavigationRouter {
        
        func canNavigate(to route: NavigationRoute) -> Bool {
            false
        }
        
        var didNavigate = false
        
        func navigate(to route: NavigationRoute) {
            didNavigate = true
        }
        
        func routeFrom(from url: URL) -> NavigationRoute? {
            nil
        }
    }

    class RouterB: NavigationRouter {
        func canNavigate(to route: NavigationRoute) -> Bool {
            route.path == SUPPORTED_PATH
        }
        
        var didNavigate = false
        
        func navigate(to route: NavigationRoute) {
            didNavigate = true
        }
        
        func routeFrom(from url: URL) -> NavigationRoute? {
            NavigationRoute(path: SUPPORTED_PATH)
        }
    }
    
    var a: RouterA!
    var b: RouterB!
    var router: CompositeNavigationRouter!
    
    override func setUp() async throws {
        a = RouterA()
        b = RouterB()
        router = CompositeNavigationRouter(routers: [a, b])
    }

    func testCanNavigate() {
        XCTAssertFalse(router.canNavigate(to: NavigationRoute(path: UNSUPPORTED_PATH)))
        XCTAssertTrue(router.canNavigate(to: NavigationRoute(path: SUPPORTED_PATH)))
    }
    
    func testNavigateNotSupportedPath() {
        router.navigate(to: NavigationRoute(path: UNSUPPORTED_PATH))
        XCTAssertFalse(a.didNavigate)
        XCTAssertFalse(b.didNavigate)
    }
    
    func testNavigateSupportedpath() {
        router.navigate(to: NavigationRoute(path: SUPPORTED_PATH))
        XCTAssertFalse(a.didNavigate)
        XCTAssertTrue(b.didNavigate)
    }
    
    func testRouteFrom() {
        let route = router.routeFrom(from: URL("\(BASE_URL)/"))
        XCTAssertEqual(route?.path, SUPPORTED_PATH)
    }
}

extension URL {
    fileprivate init(_ str: String) {
        guard let url = URL(string: str) else {
            preconditionFailure("Failed to creat url: \(str)")
        }
        self = url
    }
}
