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
}
