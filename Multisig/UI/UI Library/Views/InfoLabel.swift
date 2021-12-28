//
//  InfoLabel.swift
//  Multisig
//
//  Created by Vitaly Katz on 27.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit


class InfoLabel : UILabel {
    
    private var tooltipSource: TooltipSource?
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    func setText(_ text: String = "", description: String? = nil, style: GNOTextStyle = .headline) {
        
        let result = NSMutableAttributedString()

        if !text.isEmpty {
            let attributedText = NSMutableAttributedString(string: "\(text) ", attributes: style.attributes)
            result.append(attributedText)
            
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "ico-info")
            let imageOffsetY: CGFloat = -2.0
            attachment.bounds = CGRect(x:0, y:imageOffsetY, width: attachment.image!.size.width, height:attachment.image!.size.height);

            let attachmentString = NSAttributedString(attachment: attachment)
            result.append(attachmentString)

            self.attributedText = result
            
            if let description = description {
                tooltipSource = TooltipSource(target: self)
                tooltipSource?.message = description
                tooltipSource?.aboveTarget = false
            }
        } else {
            attributedText = nil
            tooltipSource = nil
        }
    }
}
