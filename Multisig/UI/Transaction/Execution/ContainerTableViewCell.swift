//
//  ContainerTableViewCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 12.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ContainerTableViewCell: UITableViewCell {

    @IBOutlet weak var cellContentView: UIView!

    func setContent(_ view: UIView?) {
        for view in cellContentView.subviews {
            view.removeFromSuperview()
        }
        if let view = view {
            view.translatesAutoresizingMaskIntoConstraints = false
            cellContentView.addSubview(view)

            cellContentView.addConstraints([
                cellContentView.topAnchor.constraint(equalTo: view.topAnchor),
                cellContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),

                cellContentView.heightAnchor.constraint(equalTo: view.heightAnchor),
                cellContentView.widthAnchor.constraint(equalTo: view.widthAnchor)
//                    cellContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//                cellContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            
            self.setNeedsUpdateConstraints()
        }
    }
    
}
