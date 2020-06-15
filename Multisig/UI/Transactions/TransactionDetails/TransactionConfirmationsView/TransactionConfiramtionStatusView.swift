//
//  TransactionConfiramtionStatusView.swift
//  Multisig
//
//  Created by Moaaz on 6/11/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionConfiramtionStatusView: View {
    let style: TransactionConfiramtionStatusViewStyle

    var body: some View {
        HStack {
            Image(imageName).foregroundColor(color)
            BodyText(title, textColor: color)
        }
    }

    var title: String {
        switch style {
        case .created:
            return "Created"
        case .executed:
            return "Executed"
        case .confirmed:
            return "Confirmed"
        case .rejected:
            return "Rejected"
        case .canceled:
            return "Canceled"
        case .failed:
            return "Failed"
        case .waitingConfirmations(let remaining):
            return "Execute (\(remaining) more confirmation needed)"
        case .confirm:
            return "Confirm"
        case .execute:
            return "Execute"
        }
    }

    var imageName: String {
        switch style {
        case .created:
            return "ico-create"
        case .executed, .confirmed, .canceled:
            return "ico-confirm"
        case .rejected, .failed:
            return "ico-reject"
        default:
            return "ico-empty-circle"
        }
    }

    var color: Color {
        switch style {
        case .canceled:
            return .gnoDarkBlue
        case .waitingConfirmations(_):
            return .gnoMediumGrey
        case .rejected, .failed:
            return .gnoTomato
        default:
            return .gnoHold
        }
    }
}

enum TransactionConfiramtionStatusViewStyle: Hashable {
    case created
    case executed
    case failed
    case confirmed
    case rejected
    case canceled
    case waitingConfirmations(Int)
    case confirm
    case execute
}
