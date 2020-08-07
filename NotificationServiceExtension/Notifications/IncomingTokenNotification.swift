//
//  IncomingTokenNotification.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 06.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct IncomingTokenNotification: MultisigNotification {
    let address: PlainAddress
    let tokenType: TokenType

    enum TokenType {
        case erc20, erc721, unknown
    }

    init?(payload: NotificationPayload) {
        guard
            let rawType = payload.type,
            let type = NotificationType(rawValue: rawType),
            type == .incomingToken,
            let address = PlainAddress(payload.address)
        else {
            return nil
        }
        self.address = address
        if payload.value != nil {
            tokenType = .erc20
        } else if payload.tokenId != nil {
            tokenType = .erc721
        } else {
            tokenType = .unknown
        }
    }

    var localizedTitle: String {
        "Incoming token"
    }

    var localizedBody: String {
        switch tokenType {
        case .erc20:
            return "\(address.truncatedInMiddle): ERC20 tokens received"
        case .erc721:
            return "\(address.truncatedInMiddle): ERC721 token received"
        case .unknown:
            return "\(address.truncatedInMiddle): tokens received"
        }
    }
}
