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
        case "/welcome", "/home":
            return NavigationRoute.showAssets()
        case "/new-safe/load":
            let chain = chainQueryParameter(named: "chain", in: url)
            let address = addressQueryParameter(named: "address", in: url)
            // prefer prefixed address in order to reduce input errors
            let prefixedAddress = eip3770AddressQueryParameter(named: "address", in: url)
            let route = NavigationRoute.loadSafe(
                chainId: prefixedAddress?.chainId ?? chain?.id,
                address: prefixedAddress?.address ?? address?.checksummed
            )
            return route
        case "/new-safe/create":
            let chain = chainQueryParameter(named: "chain", in: url)
            let route = NavigationRoute.createSafe(chainId: chain?.id)
            return route
        case "/balances":
            guard let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url) else {
                return nil
            }
            let route = NavigationRoute.showAssets(
                safeAddress.address,
                chainId: safeAddress.chainId
            )
            return route
        case "/balances/nfts":
            guard let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url) else {
                return nil
            }
            let route = NavigationRoute.showCollectibles(
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

        // messages are not implemented, so navigate to the default location, i.e. queue
        case "/transactions/queue", "/transactions", "/transactions/messages":
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
        // data and environment-variables are not implemented
        case "/settings", "/settings/data", "/settings/environment-variables":
            let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url)
            let route = NavigationRoute.appSettings(
                address: safeAddress?.address,
                chainId: safeAddress?.chainId
            )
            return route
        // spending-limits are not implemented
        case "/settings/setup", "/settings/spending-limits":
            guard let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url) else {
                return nil
            }
            let route = NavigationRoute.accountSettings(
                address: safeAddress.address,
                chainId: safeAddress.chainId
            )
            return route
        case "/settings/appearance":
            let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url)
            let route = NavigationRoute.appearanceSettings(
                address: safeAddress?.address,
                chainId: safeAddress?.chainId
            )
            return route
        case "/settings/modules":
            guard let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url) else {
                return nil
            }
            let route = NavigationRoute.accountAdvancedSettings(
                address: safeAddress.address,
                chainId: safeAddress.chainId
            )
            return route
        case "/settings/safe-apps", "/apps":
            let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url)
            let route = NavigationRoute.dapps(
                address: safeAddress?.address,
                chainId: safeAddress?.chainId
            )
            return route
        case "/settings/cookies":
            let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url)
            let route = NavigationRoute.advancedAppSettings(
                address: safeAddress?.address,
                chainId: safeAddress?.chainId
            )
            return route
        case "/address-book":
            let safeAddress = eip3770AddressQueryParameter(named: "safe", in: url)
            let route = NavigationRoute.addressBook(
                address: safeAddress?.address,
                chainId: safeAddress?.chainId
            )
            return route
        case "/share/safe-app":
            let chain = chainQueryParameter(named: "chain", in: url)
            var route = NavigationRoute.dapps(
                chainId: chain?.id
            )
            if let encodedAppUrl = queryParameterValue(named: "appUrl", in: url),
                let appUrl = encodedAppUrl.removingPercentEncoding {
                route.info["appUrl"] = appUrl
            }
            return route
        case "/terms":
            return NavigationRoute.terms()
        case "/privacy":
            return NavigationRoute.privacy()
        case "/licenses":
            return NavigationRoute.licenses()
        case "/imprint", "/cookie":
            return NavigationRoute.about()
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
    
    private func addressQueryParameter(named name: String, in url: URL) -> Address? {
        guard
            let text = queryParameterValue(named: name, in: url),
            let address = Address(text)
        else {
            return nil
        }
        return address
    }
    
    private func chainQueryParameter(named name: String, in url: URL) -> Chain? {
        guard
            let text = queryParameterValue(named: name, in: url),
            let chain = Chain.by(shortName: text)
        else {
            return nil
        }
        return chain
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
    
    // MARK: Onboarding
    
    static let requestToAddOwnerPath = "/addOwner"

    static func requestToAddOwner(_ params: AddOwnerRequestParameters) -> NavigationRoute {
        var route = NavigationRoute(path: requestToAddOwnerPath)
        route.info["parameters"] = params
        return route
    }

    // MARK: Add Safe
    static func loadSafe(chainId: String? = nil, address: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/loadSafe")

        if let chainId = chainId {
            route.info["chainId"] = chainId
        }
        if let address = address {
            route.info["address"] = address
        }

        return route
    }
    
    static func createSafe(chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/createSafe")
        if let chainId = chainId {
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


    // MARK: Assets
    
    static func showAssets(_ address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/assets/")
        if let address = address,
           let chainId = chainId {
            route.info["address"] = address
            route.info["chainId"] = chainId
        }
        
        return route
    }
    
    static func showCollectibles(_ address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/assets/collectibles/")
        if let address = address,
           let chainId = chainId {
            route.info["address"] = address
            route.info["chainId"] = chainId
        }
        
        return route
    }

    // MARK: Transactions

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
    
    // MARK: Settings
    
    static func connectToWeb(_ code: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/settings/connectToWeb")
        if let code = code {
            route.info["code"] = code
        }
        return route
    }
    
    static func appSettings(address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/settings/app")
        if let address = address, let chainId = chainId {
            route.info["address"] = address
            route.info["chainId"] = chainId
        }
        return route
    }
    
    static func appearanceSettings(address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/settings/app/appearance")
        if let address = address, let chainId = chainId {
            route.info["address"] = address
            route.info["chainId"] = chainId
        }
        return route
    }
    
    static let accountSettingsPath = "/settings/account"
    
    static func accountSettings(address: String, chainId: String) -> NavigationRoute {
        var route = NavigationRoute(path: accountSettingsPath)
        route.info["address"] = address
        route.info["chainId"] = chainId
        return route
    }
    
    static let accountAdvancedSettingsPath = "/settings/account/advanced"
    
    static func accountAdvancedSettings(address: String, chainId: String) -> NavigationRoute {
        var route = NavigationRoute(path: accountAdvancedSettingsPath)
        route.info["address"] = address
        route.info["chainId"] = chainId
        return route
    }
    
    static func dapps(address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/dapps/")
        if let address = address {
            route.info["address"] = address
        }
        if let chainId = chainId {
            route.info["chainId"] = chainId
        }
        return route
    }
    
    static func advancedAppSettings(address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/settings/app/advanced")
        if let address = address, let chainId = chainId {
            route.info["address"] = address
            route.info["chainId"] = chainId
        }
        return route
    }
    
    static func addressBook(address: String? = nil, chainId: String? = nil) -> NavigationRoute {
        var route = NavigationRoute(path: "/settings/app/address-book")
        if let address = address, let chainId = chainId {
            route.info["address"] = address
            route.info["chainId"] = chainId
        }
        return route
    }
    
    static func about() -> NavigationRoute {
        return NavigationRoute(path: "/settings/app/about")
    }
    
    static func terms() -> NavigationRoute {
        return NavigationRoute(path: "/settings/app/about/terms")
    }
    
    static func privacy() -> NavigationRoute {
        return NavigationRoute(path: "/settings/app/about/privacy")
    }
    
    static func licenses() -> NavigationRoute {
        return NavigationRoute(path: "/settings/app/about/licenses")
    }
    
    static var appSettingsDetailPaths: [String] = [
        NavigationRoute.connectToWeb(),
        .appearanceSettings(),
        .advancedAppSettings(),
        .addressBook(),
        .about(),
        .terms(),
        .licenses(),
        .privacy()
    ].map { $0.path }
    
    static var appSettingsAboutPaths: [String] = [
        NavigationRoute.about(),
        .terms(),
        .licenses(),
        .privacy()
    ].map { $0.path }
}
