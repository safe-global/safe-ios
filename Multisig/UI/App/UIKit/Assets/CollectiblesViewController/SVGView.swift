//
//  SVGView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import WebKit

class SVGView: UINibView {
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var placeholderImageView: UIImageView!

    override func commonInit() {
        super.commonInit()
        webView.navigationDelegate = self
    }

    func setPlaceholder(_ image: UIImage?) {
        placeholderImageView.image = image
    }

    func setSVG(url: URL) {
        hideWebView()
        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, shrink-to-fit=YES"/>
        </head>
        <body><img src="\(url)"/></body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func showWebView() {
        webView.alpha = 0
        webView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.webView.alpha = 1
        }
    }

    private func hideWebView() {
        self.webView.isHidden = true
    }
}

extension SVGView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showWebView()
    }
}
