//
//  SessionInfo.swift
//  Multisig
//
//  Created by Mouaz on 2/20/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
struct SessionInfo {
    let name: String
    let descriptionText: String
    let dappURL: String
    let iconURL: String
    let chains: [String]
    let methods: [String]
    let pendingRequests: [String]
}
