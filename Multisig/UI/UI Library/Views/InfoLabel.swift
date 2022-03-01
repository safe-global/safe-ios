//
//  InfoLabel.swift
//  Multisig
//
//  Created by Vitaly on 17.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InfoLabel: UINibView {

    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var labelIcon: UIImageView!
    
    private var tooltipSource: TooltipSource?

    override func commonInit() {
        super.commonInit()
        labelText.setStyle(.headline)
    }
    
    func setText(_ text: String = "", description: String? = nil, style: GNOTextStyle = .headline) {
        
        labelText.setStyle(style)
        labelText.text = text
        
        if let description = description {
            tooltipSource = TooltipSource(target: self, arrowTarget: labelIcon)
            tooltipSource?.message = description
            tooltipSource?.aboveTarget = false
        } else {
            tooltipSource = nil
        }

        labelIcon.isHidden = description == nil
    }
}
