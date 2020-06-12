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
        case .waitingConfirmations(let remining):
            return "Execute (\(remining) more confirmation needed)"
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
        case .executed:
            return "ico-confirm"
        case .confirmed:
            return "ico-confirm"
        case .rejected:
            return "ico-reject"
        case .canceled:
            return "ico-confirm"
        case .failed:
            return "ico-reject"
        case .waitingConfirmations(_):
            return "ico-empty-circle"
        case .confirm:
            return "ico-empty-circle"
        case .execute:
            return "ico-empty-circle"
        }
    }

    var color: Color {
        switch style {
        case .created:
            return .gnoHold
        case .executed:
            return .gnoHold
        case .confirmed:
            return .gnoHold
        case .rejected:
            return .gnoTomato
        case .canceled:
            return .gnoDarkBlue
        case .failed:
            return .gnoTomato
        case .waitingConfirmations(_):
            return .gnoMediumGrey
        case .confirm:
            return .gnoHold
        case .execute:
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
