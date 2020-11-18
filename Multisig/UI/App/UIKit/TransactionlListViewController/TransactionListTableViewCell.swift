//
//  TransactionListTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class TransactionListTableViewCell: UITableViewCell {

    weak var controller: UIHostingController<TransactionCellView>?

    func setController(_ hostingController: UIHostingController<TransactionCellView>) {
        let size = hostingController.sizeThatFits(in: CGSize(width: contentView.bounds.size.width, height: CGFloat.greatestFiniteMagnitude))
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        hostingController.view.backgroundColor = .clear
        hostingController.view.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        contentView.addSubview(hostingController.view)
        controller = hostingController
    }
}
