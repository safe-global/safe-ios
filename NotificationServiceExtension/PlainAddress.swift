//
//  PlainAddress.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 06.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

// This is created to not share much code between app and
// the extension due to increased complexity.
struct PlainAddress: CustomStringConvertible {
    let value: String

    init?(_ value: String?) {
        guard let value = value, value.count == 42, value.starts(with: "0x") else { return nil }
        self.value = value
    }

    var description: String {
        value
    }

    var truncatedInMiddle: String {
        value.prefix(6) + "…" + value.suffix(4)
    }
}

