//
//  MoonpayModels.swift
//  Multisig
//
//  Created by Mouaz on 8/1/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation

enum MoonpayModels {
    struct Currency: Decodable {
        let id: String
        let name: String
        let code: String
        let metadata: Metadata?

        struct Metadata: Decodable {
            let chainId: String?
            let networkCode: String?
        }
    }
}
