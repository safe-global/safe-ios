//
//  TrackingEvent+WebConnection.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

extension TrackingEvent {
    static func keyTypeParameters(_ keyInfo: KeyInfo) -> [String: Any] {
        ["key_type": keyInfo.keyType.trackingValue]
    }
}

extension KeyType {
    var trackingValue: String {
        switch self {
        case .deviceGenerated:
            return "generated"
        case .deviceImported:
            return "imported"
        case .ledgerNanoX:
            return "ledger_nano_x"
        case .walletConnect:
            return "connected"
        }
    }
}
