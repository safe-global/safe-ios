//
//  SCGPagedRequest.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SCGPagedRequest<T: Decodable>: JSONRequest {

    var url: URL?

    typealias ResponseType = SCGPage<T>

    struct InvalidURL: LocalizedError {
        var errorDescription: String? {
            "Invalid next page URL"
        }
    }

    init(_ urlString: String) throws {
        guard let url = URL(string: urlString) else {
            throw InvalidURL()
        }
        self.url = url
    }

}
