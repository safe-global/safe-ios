//
//  MultisigNotification.swift
//  NotificationServiceExtension
//
//  Created by Dmitry Bespalov on 06.08.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

protocol SafeNotification {
    var address: AddressString { get }
    var chainId: UInt256String { get }
}

enum MultisigNotification: Decodable {
    struct IncomingNativeCoin: Codable, SafeNotification {
        var address: AddressString
        var chainId: UInt256String
        var value: UInt256String
        var txHash: DataString
    }

    struct IncomingToken: Codable, SafeNotification {
        var address: AddressString
        var chainId: UInt256String
        var tokenAddress: AddressString
        var tokenId: String?
        var value: UInt256String?

        var tokenType: TokenType {
            if value != nil {
                return .erc20
            } else if tokenId != nil {
                return .erc721
            } else {
                return .unknown
            }
        }

        enum TokenType {
            case erc20, erc721, unknown
        }
    }

    struct ExecutedMultisigTransaction: Codable, SafeNotification {
        var address: AddressString
        var chainId: UInt256String
        var failed: BoolString
        var safeTxHash: DataString
        var txHash: DataString
    }

    struct NewConfirmation: Codable, SafeNotification {
        var address: AddressString
        var chainId: UInt256String
        var owner: AddressString
        var safeTxHash: DataString
    }

    struct ConfirmationRequest: Codable, SafeNotification {
        var address: AddressString
        var chainId: UInt256String
        var safeTxHash: DataString
    }

    case incomingNativeCoin(IncomingNativeCoin)
    case incomingToken(IncomingToken)
    case executedMultisigTransaction(ExecutedMultisigTransaction)
    case newConfirmation(NewConfirmation)
    case confirmationRequest(ConfirmationRequest)
    case unknown

    init(from decoder: Decoder) throws {
        enum Keys: String, CodingKey { case type }
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "INCOMING_ETHER":
            self = try .incomingNativeCoin(.init(from: decoder))
        case "INCOMING_TOKEN":
            self = try .incomingToken(.init(from: decoder))
        case "EXECUTED_MULTISIG_TRANSACTION":
            self = try .executedMultisigTransaction(.init(from: decoder))
        case "NEW_CONFIRMATION":
            self = try .newConfirmation(.init(from: decoder))
        case "CONFIRMATION_REQUEST":
            self = try .confirmationRequest(.init(from: decoder))
        default:
            self = .unknown
        }
    }

    init(from userInfo: [AnyHashable: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: userInfo, options: .prettyPrinted)
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}
