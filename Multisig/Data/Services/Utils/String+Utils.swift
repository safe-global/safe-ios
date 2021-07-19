//
//  String.swift
//  Multisig
//
//  Created by Moaaz on 7/19/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

extension String {
    func compareNumeric(_ value: String) -> ComparisonResult {
        return compare(value, options: .numeric)
    }
}
