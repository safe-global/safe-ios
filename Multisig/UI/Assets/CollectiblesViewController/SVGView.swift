//
//  SVGView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import WebKit
import Kingfisher

class SVGView: UINibView {
    var onError: () -> Void = {}
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var imageView: UIImageView!

    override func commonInit() {
        super.commonInit()
        webView.navigationDelegate = self
        imageView.backgroundColor = UIColor(named: "transparentBackground")
    }

    func setImage(url: URL?, placeholder: UIImage?, onError: @escaping () -> Void = {}) {
        self.onError = onError
        if let url = url, url.pathExtension.caseInsensitiveCompare("svg") == .orderedSame {
            imageView.image = placeholder
            setSVG(url: url)
        } else {
            hideWebView()
            webView.stopLoading()
            imageView.kf.setImage(with: url, placeholder: placeholder, completionHandler:  { [weak self] result in
                if case Result.failure(_) = result, let `self` = self {
                    self.onError()
                }
            })
        }
    }

    private func setSVG(url: URL) {
        hideWebView()
        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, shrink-to-fit=YES"/>
        </head>
        <body style="background-color: #ffffff"><img src="\(url)"/></body>
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
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onError()
    }
}
