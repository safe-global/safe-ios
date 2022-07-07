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
