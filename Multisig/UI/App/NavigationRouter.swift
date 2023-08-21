//
// Created by Dmitry Bespalov on 15.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

struct NavigationRoute {
    var path: String
    var info: [String: Any] = [:]
}

protocol NavigationRouter {
    func canNavigate(to route: NavigationRoute) -> Bool
    func navigate(to route: NavigationRoute)
    func routeFrom(from url: URL) -> NavigationRoute?
}

extension NavigationRouter {
    func navigateAfterDelay(to route: NavigationRoute) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            navigate(to: route)
        }
    }
}

class CompositeNavigationRouter: NavigationRouter {
    static let shared = CompositeNavigationRouter(routers: [ExtendedNavigationRouter(), DefaultNavigationRouter()])
    
    private var routers: [NavigationRouter]

    init(routers: [NavigationRouter]) {
        self.routers = routers
    }
    
    func canNavigate(to route: NavigationRoute) -> Bool {
        for router in routers {
            if router.canNavigate(to: route) {
                return true
            }
        }
        return false
    }
    
    func navigate(to route: NavigationRoute) {
        for router in routers {
            if router.canNavigate(to: route) {
                router.navigate(to: route)
                return
            }
        }
    }
    
    func routeFrom(from url: URL) -> NavigationRoute? {
        for router in routers {
            if let route = router.routeFrom(from: url) {
                return route
            }
        }
        return nil
    }
}

class DefaultNavigationRouter: NavigationRouter {
    static let shared = DefaultNavigationRouter()

    private var sceneDelegate: SceneDelegate? {
        UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
    }

    func canNavigate(to route: NavigationRoute) -> Bool {
        guard let sceneDelegate = sceneDelegate else { return false }
        return sceneDelegate.canNavigate(to: route)
    }

    func navigate(to route: NavigationRoute) {
        sceneDelegate?.navigate(to: route)
    }

    private let pattern = "^https://.*/([-a-zA-Z0-9]{1,20}):(0x[a-fA-F0-9]{40})/([-a-zA-Z0-9]{1,20})(/[-a-zA-Z0-9_]+)?"

    func routeFrom(from url: URL) -> NavigationRoute? {
        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }
        guard matches.count >= 3,
                let _ = Address(matches[1]),
              let chain = Chain.by(shortName: matches[0]) else { return nil }

        let safeAddress = matches[1]
        let chainId = chain.id!

        let page = matches[2]
        if page == "balances" {
            return NavigationRoute.showAssets(matches[1], chainId: chainId)
        } else if page == "transactions" {
            var details = matches[3]
            details.removeFirst()

            if details == "history" {
                return NavigationRoute.showTransactionHistory(safeAddress, chainId: chainId)
            } else if details == "queue" {
                return NavigationRoute.showTransactionQueued(safeAddress, chainId: chainId)
            } else {
                return NavigationRoute.showTransactionDetails(safeAddress, chainId: chainId, transactionId: details)
            }
        }

        return nil
    }
}

class ExtendedNavigationRouter: NavigationRouter {
    static let shared = ExtendedNavigationRouter()

    private var sceneDelegate: SceneDelegate? {
        UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate
    }

    func canNavigate(to route: NavigationRoute) -> Bool {
        guard let sceneDelegate = sceneDelegate else { return false }
        return sceneDelegate.canNavigate(to: route)
    }

    func navigate(to route: NavigationRoute) {
        sceneDelegate?.navigate(to: route)
    }

    private let pattern = "^https://.*/([-a-zA-Z0-9]{1,20})(/[-a-zA-Z0-9_]+)?"

    func routeFrom(from url: URL) -> NavigationRoute? {
        
        switch url.path {
        case "/balances":
            guard let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url) else {
                return nil
            }
            let route = NavigationRoute.showAssets(
                safeAddress.address,
                chainId: safeAddress.chainId
            )
            return route
        case "/transactions/history":
            guard let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url) else {
                return nil
            }
            let route = NavigationRoute.showTransactionHistory(
                safeAddress.address,
                chainId: safeAddress.chainId
            )
            return route
        case "/transactions/queue":
            guard let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url) else {
                return nil
            }
            let route = NavigationRoute.showTransactionQueued(
                safeAddress.address,
                chainId: safeAddress.chainId
            )
            return route
        case "/transactions/tx":
            guard
                let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url),
                let transactionId = queryParameterValue(named: "id", in: url)
            else {
                return nil
            }
            let route = NavigationRoute.showTransactionDetails(
                safeAddress.address,
                chainId: safeAddress.chainId,
                transactionId: transactionId
            )
            return route

        default:
            return nil
        }
    }
    
    // get the address and chain id from the 'safe'
    private func eip3770AddressQueryParameter(named name: String, in url: URL) -> (address: String, chainId: String)? {
        guard
            let paramValue = queryParameterValue(named: name, in: url),
            let address = try? Address.addressWithPrefix(text: paramValue),
            let prefix = address.prefix,
            let chainId = Chain.by(shortName: prefix)?.id
        else {
            return nil
        }
        return (address.checksummed, chainId)
    }

    // get the value of a query parameter
    private func queryParameterValue(named name: String, in url: URL) -> String? {
        let urlComps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let items = urlComps?.queryItems
        guard
            let paramValue = items?.first(where: { item in
                item.name == name
            })?.value
        else {
            return nil
        }
        return paramValue
    }
}


extension NavigationRoute {
    static func connectToWeb(_ code: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/settings/connectToWeb")
        if let code = code {
            route.info["code"] = code
        }
        return route
    }

    static func showAssets(_ address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/assets/")
        if let address = address,
           let chainId = chainId {
            route.info["address"] = address
            route.info["chainId"] = chainId
        }

        return route
    }

    static let deploymentFailedPath = "/deploymentFailed/"

    static func deploymentFailed(safe: Safe) -> NavigationRoute {
        var route = NavigationRoute(path: deploymentFailedPath)
        route.info["safe"] = safe
        return route
    }

    static let requestToAddOwnerPath = "/addOwner"

    static func requestToAddOwner(_ params: AddOwnerRequestParameters) -> NavigationRoute {
        var route = NavigationRoute(path: requestToAddOwnerPath)
        route.info["parameters"] = params
        return route
    }

    static func showTransactionHistory(_ address: String, chainId: String) -> NavigationRoute {
        var route = NavigationRoute(path: "/transactions/history/")
        route.info["address"] = address
        route.info["chainId"] = chainId

        return route
    }

    static func showTransactionQueued(_ address: String, chainId: String) -> NavigationRoute {
        var route = NavigationRoute(path: "/transactions/queued/")
        route.info["address"] = address
        route.info["chainId"] = chainId

        return route
    }

    static func showTransactionDetails(_ address: String, chainId: String, transactionId: String) -> NavigationRoute {
        var route = NavigationRoute(path: "/transactions/details/")
        route.info["address"] = address
        route.info["chainId"] = chainId
        route.info["transactionId"] = transactionId

        return route
    }
}
