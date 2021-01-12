//
//  String+Error.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? {
        self
    }
}
