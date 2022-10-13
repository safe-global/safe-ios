//
//  TipsView.swift
//  Multisig
//
//  Created by Vitaly on 11.04.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class TipsView: UINibView {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tipsContainer: UIStackView!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.setStyle(.headline)
        backgroundView.backgroundColor = .infoBackground
        backgroundView.layer.cornerRadius = 8
    }
    
    func setContent(title: String, tips: [String]) {
        
        titleLabel.text = title
        tipsContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        tips.forEach {
        
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .firstBaseline
            row.distribution = .fill
            row.spacing = 8
                    
            let bulletPointLabel = UILabel()
            bulletPointLabel.addConstraint(NSLayoutConstraint(item: bulletPointLabel,
                                                              attribute: .width,
                                                              relatedBy: .equal,
                                                              toItem: nil,
                                                              attribute: .width,
                                                              multiplier: 1,
                                                              constant: 10))
            bulletPointLabel.setStyle(.callout)
            bulletPointLabel.text = "\u{2022}"

            let tipLabel = UILabel()
            tipLabel.setStyle(.callout)
            tipLabel.numberOfLines = 0
            tipLabel.text = $0
            
            row.addArrangedSubview(bulletPointLabel)
            row.addArrangedSubview(tipLabel)
            
            tipsContainer.addArrangedSubview(row)
        }
    }
}
