//
//  PagedRequest.swift
//  Multisig
//
//  Created by Moaaz on 6/25/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct PagedRequest<T: Decodable>: JSONRequest {

    var url: URL

    // the next/previous only works with GET requests
    var httpMethod: String {
        "GET"
    }

    var query: String? {
        url.query
    }

    var urlPath: String {
        url.path
    }

    typealias Response = PagedResponse<T>
    typealias ResponseType = Response

    init?(_ urlString: String?) {
        guard let string = urlString, let url = URL(string: string) else {
            return nil
        }
        self.url = url
    }

}
