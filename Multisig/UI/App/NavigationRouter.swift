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
}

extension NavigationRouter {
    func navigateAfterDelay(to route: NavigationRoute) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) {
            navigate(to: route)
        }
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

    private let pattern = "^https://gnosis-safe.io/app/([-a-zA-Z0-9]{1,20}):(0x[a-fA-F0-9]{40})/([-a-zA-Z0-9]{1,20})(/[-a-zA-Z0-9_]+)?"

    func routeFrom(from url: URL) -> NavigationRoute? {
        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }
        guard matches.count >= 3,
                let ـ = Address(matches[1]),
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
