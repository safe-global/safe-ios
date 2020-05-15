//
//  DisplayURL.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct DisplayURL {

    // url without the API keys, paths, usernames, and passwords.
    var value: URL {
        guard let comps = URLComponents(url: original, resolvingAgainstBaseURL: false) else {
            return original
        }
        var result = URLComponents()
        result.scheme = comps.scheme
        result.host = comps.host
        result.port = comps.port
        return result.url ?? original
    }

    var absoluteString: String {
        value.absoluteString
    }

    var original: URL

    init(_ url: URL) {
        self.original = url
    }

}
