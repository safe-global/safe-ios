//
//  TimeZone+Offset.swift
//  Multisig
//
//  Created by Moaaz on 1/13/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

extension TimeZone {
    static func currentOffest() -> Int {
        TimeZone.current.secondsFromGMT() * 1000
    }
}
