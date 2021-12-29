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

        if !text.isEmpty {
            
            let attributedText = NSMutableAttributedString(string: "\(text) ", attributes: style.attributes)
            
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "ico-info")
            //FIXME: discuss if using system image is a better alternative
            //UIImage(systemName: "info.circle")
            let imageOffsetY: CGFloat = -3.0
            attachment.bounds = CGRect(x:0, y:imageOffsetY, width: attachment.image!.size.width, height:attachment.image!.size.height)
            
            let attachmentString = NSAttributedString(attachment: attachment)
            
            attributedText.append(attachmentString)

            self.attributedText = attributedText
            
            if let description = description {
                tooltipSource = TooltipSource(target: self)
                tooltipSource?.message = description
                tooltipSource?.aboveTarget = false
            } else {
                tooltipSource = nil
            }
        } else {
            attributedText = nil
            tooltipSource = nil
        }
    }
}
