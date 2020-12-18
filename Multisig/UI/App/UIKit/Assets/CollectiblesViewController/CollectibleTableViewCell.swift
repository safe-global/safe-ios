//
//  CollectibleTableViewCell.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 02.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import WebKit

class CollectibleTableViewCell: UITableViewCell {
    @IBOutlet private weak var cellImageView: UIImageView!
    @IBOutlet private weak var cellNameLabel: UILabel!
    @IBOutlet private weak var cellDescriptionLabel: UILabel!
    @IBOutlet private weak var webView: WKWebView!

    override func awakeFromNib() {
        super.awakeFromNib()
        cellNameLabel.setStyle(.headline)
        cellDescriptionLabel.setStyle(.body)
        webView.navigationDelegate = self
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        webView.stopLoading()
        webView.isHidden = true
    }

    func setName(_ value: String) {
        cellNameLabel.text = value
    }

    func setDescription(_ value: String) {
        cellDescriptionLabel.text = value
    }

    func setImage(with URL: URL?, placeholder: UIImage) {
        webView.isHidden = true
        if let url = URL {
            if url.pathExtension.caseInsensitiveCompare("svg") == .orderedSame {
                let html = """
                <html>
                <head>
                <meta name="viewport" content="width=device-width, shrink-to-fit=YES"/>
                </head>
                <body><img src="\(url)"/></body>
                </html>
                """
                webView.loadHTMLString(html, baseURL: nil)
                cellImageView.image = placeholder
            } else {
                cellImageView.kf.setImage(with: url, placeholder: placeholder)
            }
        } else {
            cellImageView.image = placeholder
        }
    }
}

extension CollectibleTableViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.alpha = 0
        webView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            webView.alpha = 1
        }
    }
}
