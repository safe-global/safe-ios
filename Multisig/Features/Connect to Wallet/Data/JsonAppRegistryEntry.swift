//
// Created by Dmitry Bespalov on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct JsonAppRegistryEntry: Codable {
    var id: String
    var name: String
    var description: String
    var homepage: URL
    var chains: [String]
    var versions: [String]
    var image_id: String
    var image_url: ImageUrl
    var app: App
    var mobile: Navigation
    var desktop: Navigation
    var metadata: Metadata


    struct ImageUrl: Codable {
        var sm: URL
        var md: URL
        var lg: URL
    }

    // values can be empty strings
    struct App: Codable {
        var browser: URL
        var ios: URL
        var android: URL
        var mac: URL
        var windows: URL
        var linux: URL
    }

    struct Navigation: Codable {
        // only scheme, can be url?
        var native: URL
        var universal: URL
    }

    struct Metadata: Codable {
        var shortName: String

        struct Colors {
            var primary: String
            var secondary: String
        }
    }

    struct CustomURL: Codable {
        var value: URL
    }
}
