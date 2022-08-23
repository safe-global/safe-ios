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
        "/claiming-app-data/resources/data/guardians.json"
    }

    typealias ResponseType = [Guardian]
}

struct Guardian: Decodable {
    let name: String?
    let reason: String?
    let contribution: String?
    let address: AddressString
    let ens: String?
    let image: String?
    var imageURL: URL? {
        guard let image = image else {
            return nil
        }
        return URL(string: "https://5afe.github.io/claiming-app-data/resources/data/images/\(image)")
    }
}

extension SafeClaimingService {
    func asyncGuardians(completion: @escaping (Result<GuardiansRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: GuardiansRequest(), completion: completion)
    }
}
