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
        "/guardians/guardians.json"
    }

    typealias ResponseType = [Guardian]
}


extension SafeClaimingService {
    func asyncGuardians(completion: @escaping (Result<GuardiansRequest.ResponseType, Error>) -> Void) -> URLSessionTask? {
        asyncExecute(request: GuardiansRequest(), completion: completion)
    }
}
