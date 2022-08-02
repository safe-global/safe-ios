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

    override func commonInit() {
        super.commonInit()
        tweetButton.setText("Tweet", .tweet)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.borderWidth = 2
        layer.borderColor = UIColor.backgroundPrimary.cgColor
        layer.cornerRadius = 8

        tweetLabel.setStyle(.secondary.color(.labelPrimary))
        tweetButton.setText("Tweet", .tweet)
    }

    func setTweet(text: String, hashtags: [String]) {

        let hashtagsString = hashtags
            .map {
                "#\($0)"
            }
            .joined(separator: " ")

        tweetLabel.attributedText = "\(text) \(hashtagsString)".highlightRange(
            originalStyle: .secondary.color(.labelPrimary),
            highlightStyle: .primary.color(.primary),
            textToHightlight: hashtagsString
        )
    }

    @IBAction func didTapTweetButton(_ sender: Any) {
        let shareString = "https://twitter.com/intent/tweet?text=\(tweetLabel.text!)"
        let escapedShareString = shareString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let url = URL(string: escapedShareString)
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
}
