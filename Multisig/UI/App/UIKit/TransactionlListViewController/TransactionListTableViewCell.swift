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

    private weak var controller: UIHostingController<TransactionCellView>?

    func setTransaction(_ tx: TransactionViewModel, from parent: UIViewController) {
        if let vc = controller {
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }

        let vc = UIHostingController(rootView: TransactionCellView(transaction: tx))
        parent.addChild(vc)

        var boundsSize = contentView.bounds.size
        boundsSize.height = CGFloat.greatestFiniteMagnitude
        let size = vc.sizeThatFits(in: boundsSize)
        vc.view.frame = CGRect(origin: .zero, size: size)
        vc.view.backgroundColor = .clear
        vc.view.autoresizingMask = [.flexibleRightMargin, .flexibleBottomMargin]
        contentView.addSubview(vc.view)
        controller = vc

        vc.didMove(toParent: parent)

        // somehow adding hosting controller auto-shows the navigation bar
        parent.navigationController?.navigationBar.isHidden = true
    }
}
