//
//  SafeRelayService.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 17.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class SafeRelayService {
    private let logger: Logger
    private let httpClient: JSONHTTPClient

    init(url: URL, logger: Logger) {
        self.logger = logger
        httpClient = JSONHTTPClient(url: url, logger: logger)
    }
}
