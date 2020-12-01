//
//  TransactionListTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class TransactionListTableViewCell: SwiftUITableViewCell {
    func setTransaction(_ tx: TransactionViewModel, from parent: UIViewController) {
        setContent(TransactionCellView(transaction: tx), from: parent)
    }
}
