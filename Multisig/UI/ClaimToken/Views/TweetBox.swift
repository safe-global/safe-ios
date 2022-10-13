//
//  TweetBox.swift
//  Multisig
//
//  Created by Vitaly on 02.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//


import UIKit

class TweetBox: UINibView {
    
    @IBOutlet weak var tweetLabel: UILabel!
    @IBOutlet weak var tweetButton: UIButton!

    var onTweet: () -> Void = { }
    

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.borderWidth = 2
        layer.cornerRadius = 8

        tweetLabel.setStyle(.body)
        tweetButton.setText("Tweet", .tweet)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // changing here to react to dark/light color change
        layer.borderColor = UIColor.backgroundPrimary.cgColor
    }

    func setTweet(text: String, highlights: [String]) {
        let attributedText = NSMutableAttributedString(string: text, attributes: GNOTextStyle.body.attributes)

        for string in highlights {
            let range = (text as NSString).range(of: string)
            guard range.location != NSNotFound else { continue }
            attributedText.addAttributes(GNOTextStyle.bodyPrimary.attributes, range: range)
        }
        
        tweetLabel.attributedText = attributedText
    }

}
