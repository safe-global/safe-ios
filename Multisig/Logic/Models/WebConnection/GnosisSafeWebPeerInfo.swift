//
// Created by Dmitry Bespalov on 10.02.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

class GnosisSafeWebPeerInfo: WebConnectionPeerInfo {
    var browser: String? {
        let parts = description.split(separator: ";")
        guard parts.count == 2, let part = parts.first else { return nil }
        return String(part)
    }

    var appVersion: String? {
        let parts = description.split(separator: ";")
        guard parts.count == 2, let part = parts.last else { return nil }
        return String(part)
    }
}