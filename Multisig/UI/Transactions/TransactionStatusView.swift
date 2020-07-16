//
//  TransactionStatusView.swift
//  Multisig
//
//  Created by Moaaz on 6/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionStatusView: View {
    let status: TransactionStatus
    var style: Style = .body
    var body: some View {
        HStack (spacing: 6) {
            if [.waitingConfirmation, .waitingExecution].contains(status) {
                Image("ico-bullet-point")
            }

            if style == .body {
                Text(status.title)
                    .body(statusColor)
            } else {
                Text(status.title)
                    .footnote(statusColor)
            }
        }
        .foregroundColor(statusColor)
    }
    
    var statusColor: Color {
        switch status {
        case .waitingExecution, .waitingConfirmation, .pending:
             return .gnoPending
        case .failed:
            return .gnoTomato
        case .cancelled:
            return .gnoDarkGrey
        case .success:
            return .gnoHold
        }
    }

    enum Style {
        case body
        case footnote
    }
}

struct TransactionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        return TransactionStatusView(status: .failed, style: .body)
    }
}
