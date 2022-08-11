//
//  GuardiansRequest.swift
//  Multisig
//
//  Created by Mouaz on 8/11/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct GuardiansRequest: JSONRequest {
    var httpMethod: String { "GET" }

    var urlPath: String {
        "/api/v1/guardians/"
    }

    typealias ResponseType = [Guardian]
}

struct Guardian: Decodable {
    let name: String?
    let reason: String?
    let contribution: String?
    let address: AddressString
    let ens: String?
    let image_url: String?
    let start_date: String?
    var imageURL: URL? {
        image_url == nil ? nil : URL(string: image_url!)
    }
}

extension SafeClaimingService {
    func asyncGuardians(completion: @escaping (Result<GuardiansRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: GuardiansRequest(), completion: completion)
    }
}
