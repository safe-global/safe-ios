//
// Created by Dmitry Bespalov on 09.03.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct JsonAppRegistryEntry: Codable {
    var id: String
    var name: String
    var description: String?
    // link to the website
    var homepage: ValidatedURL
    var chains: [String]
    // caip-2 format version strings (namespace:reference). For Ethereum, they'll be in the form eip155:<chainid>
    var versions: [String]
    var image_id: String
    var image_url: ImageUrl
    // links to the app install pages
    var app: App
    // links to switch to the app on mobile
    var mobile: Navigation
    // links to switch to the app on desktop
    var desktop: Navigation
    var metadata: Metadata

    struct ImageUrl: Codable {
        // small image
        var sm: ValidatedURL
        // medium image
        var md: ValidatedURL
        // large image
        var lg: ValidatedURL
    }

    struct App: Codable {
        var browser: ValidatedURL
        var ios: ValidatedURL
        var android: ValidatedURL
        var mac: ValidatedURL
        var windows: ValidatedURL
        var linux: ValidatedURL
    }

    struct Navigation: Codable {
        // deeplink scheme that would open the app on the device
        var native: ValidatedURL
        // universal link that is a website url and can work as a deeplink
        var universal: ValidatedURL
    }

    struct Metadata: Codable {
        var shortName: String?
        var colors: Colors

        struct Colors: Codable {
            // color is a web color format. Can be hex #rrggbb or in the form rgb(r,g,b)
            var primary: String?
            var secondary: String?
        }
    }

    struct ValidatedURL: Codable {
        // url is nil if the string value is empty or invalid
        var url: URL?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                url = nil
            } else {
                let string = try container.decode(String.self)
                url = URL(string: string)
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(url)
        }
    }
}

struct JsonAppRegistry: Codable {
    var entries: [String: JsonAppRegistryEntry]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        entries = try container.decode([String: JsonAppRegistryEntry].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(entries)
    }
}
