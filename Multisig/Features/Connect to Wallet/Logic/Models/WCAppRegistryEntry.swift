//
// Created by Vitaly on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class WCAppRegistryEntry {

    var id: String

    var role: Role

    var name: String
    
    var rank: Int

    var shortName: String? = nil

    var description: String? = nil

    var homepage: URL? = nil

    var imageId: String? = nil

    var imageSmallUrl: URL? = nil

    var imageMediumUrl: URL? = nil

    var imageLargeUrl: URL? = nil

    var appStoreLink: URL? = nil

    var linkMobileNative: URL? = nil

    var linkMobileUniversal: URL? = nil

    var chains: [String]

    var versions: [String]

    init(
            id: String,
            role: Role,
            chains: [String],
            versions: [String],
            name: String,
            rank: Int,
            shortName: String? = nil,
            description: String? = nil,
            homepage: URL? = nil,
            imageId: String? = nil,
            imageSmallUrl: URL? = nil,
            imageMediumUrl: URL? = nil,
            imageLargeUrl: URL? = nil,
            appStoreLink: URL? = nil,
            linkMobileNative: URL? = nil,
            linkMobileUniversal: URL? = nil
    ) {
        self.id = id
        self.role = role
        self.chains = chains
        self.versions = versions
        self.name = name
        self.rank = rank
        self.shortName = shortName
        self.description = description
        self.homepage = homepage
        self.imageId = imageId
        self.imageSmallUrl = imageSmallUrl
        self.imageMediumUrl = imageMediumUrl
        self.imageLargeUrl = imageLargeUrl
        self.appStoreLink = appStoreLink
        self.linkMobileNative = linkMobileNative
        self.linkMobileUniversal = linkMobileUniversal

    }

    enum Role: Int16 {
        case wallet = 0
        case dapp = 1
    }

    /// Based on the wallet connect url, returns either universal link (preferred) or a deeplink to establish
    /// WalletConnect connection. Preserves path in the universal link in the entry
    ///
    /// see: https://docs.walletconnect.com/mobile-linking#for-ios
    func connectLink(from url: WebConnectionURL) -> URL? {
        if let link = linkMobileUniversal,
           link.host == nil || !(link.host == "apps.apple.com" || link.host == "itunes.apple.com" || link.host == "play.google.com"),
           var components = URLComponents(url: link, resolvingAgainstBaseURL: false)
        {
            let encodedUri = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            components.percentEncodedQuery = "uri=\(encodedUri)"

            if let url = components.url, url.lastPathComponent != "wc" {
                components.path = url.appendingPathComponent("wc").path
            }

            return components.url
        } else if
            let link = linkMobileNative,
            var components = URLComponents(url: link, resolvingAgainstBaseURL: false)
        {
            let encodedUri = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            components.percentEncodedQuery = "uri=\(encodedUri)"

            if components.scheme == nil && components.host == nil, let componentsUrl = components.url {
                if componentsUrl.pathComponents.count == 1 {
                    components.scheme = componentsUrl.pathComponents.first
                    components.path = ""
                } else {
                    return URL(string: url.absoluteString)
                }
            }

            if let host = components.host, !host.isEmpty {
                guard host != "wc" else {
                    return components.url
                }

                if let url = components.url, url.lastPathComponent != "wc" {
                    components.path = url.appendingPathComponent("wc").path
                }

                return components.url
            } else {
                components.host = "wc"
                return components.url
            }
        } else {
            // fallback to the connection url
            return URL(string: url.absoluteString)
        }
    }

    /// Link to switch to the wallet
    ///
    /// see: https://docs.walletconnect.com/mobile-linking#for-ios
    func navigateLink(from url: WebConnectionURL) -> URL? {
        if let link = connectLink(from: url),
           var components = URLComponents(url: link, resolvingAgainstBaseURL: false) {

            if let index = components.queryItems?.firstIndex(where: { $0.name == "uri" }) {
                components.queryItems?[index] = URLQueryItem(name: "uri", value: "wc:\(url.handshakeChannelId)@\(url.protocolVersion)")
            }

            return components.url
        }
        return nil
    }
}

