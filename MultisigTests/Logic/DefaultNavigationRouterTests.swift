//
//  DefaultNavigationRouterTests.swift
//  MultisigTests
//
//  Created by Dmitrii Bespalov on 21.08.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

final class DefaultNavigationRouterTests: XCTestCase {

    let router = DefaultNavigationRouter()

    func testAssets() {
        let url = "https://some.host/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/balances"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }

    func testHistory() {
        let url = "https://some.host/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/transactions/history"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/history/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testQueue() {
        let url = "https://some.host/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/transactions/queue"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/queued/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }

    func testTransactionDetails() {
        let url = "https://some.host/eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/transactions/some_identifier"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/details/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
        XCTAssertEqual(route?.info["transactionId"] as? String, "some_identifier")
    }
    
    func testNotMatching() {
        let url = "https://some.host/settings"
        let route = router.routeFrom(from: URL(url))
        XCTAssertNil(route)
    }
    
    func testAddressNotValid() {
        let url = "https://some.host/eth:0x1111111111D19Be20952152c549ee478Bf1bf36b/balances"
        let route = router.routeFrom(from: URL(url))
        XCTAssertNil(route)
    }
    
    func testChainIDNotValid() {
        let url = "https://some.host/ABC:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b/balances"
        let route = router.routeFrom(from: URL(url))
        XCTAssertNil(route)
    }
}

final class ExtendedNavigationRouterTests: XCTestCase {
    let router = ExtendedNavigationRouter()

    func testAssets() {
        let url = "https://some.host/balances?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testCollectibles() {
        let url = "https://some.host/balances/nfts?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/assets/collectibles/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
    }
    
    func testHistory() {
        let url = "https://some.host/transactions/history?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/history/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")

    }
    
    func testQueue() {
        let url = "https://some.host/transactions/queue?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/queued/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")

    }

    func testDetails() {
        let url = "https://some.host/transactions/tx?safe=eth:0x46F228b5eFD19Be20952152c549ee478Bf1bf36b&id=some-identifier"
        let route = router.routeFrom(from: URL(url))
        XCTAssertEqual(route?.path, "/transactions/details/")
        XCTAssertEqual(route?.info["address"] as? String, "0x46F228b5eFD19Be20952152c549ee478Bf1bf36b")
        XCTAssertEqual(route?.info["chainId"] as? String, "1")
        XCTAssertEqual(route?.info["transactionId"] as? String, "some-identifier")
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
        let route = router.routeFrom(from: URL("https://some.host/"))
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
