//
//  WebImageView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import WebKit
import Kingfisher

class WebImageView: UINibView {
    var onError: () -> Void = {}
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var imageView: UIImageView!

    override func commonInit() {
        super.commonInit()
        webView.navigationDelegate = self
        imageView.backgroundColor = UIColor(named: "transparentBackground")
        hideWebView()
    }

    func setImage(url: URL?, placeholder: UIImage?, onError: @escaping () -> Void = {}) {
        guard let url = url else {
            showPlaceholder(placeholder)
            return
        }
        // NOTE: huge memory leak when using UIImageView for displaying "gif" images -> instead, use the web view.
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "png", "jpg", "jpeg", "heif":
            hideWebView()
            webView.stopLoading()
            self.onError = onError
            imageView.kf.setImage(with: url, placeholder: placeholder, completionHandler:  { [weak self] result in
                if case Result.failure(_) = result, let `self` = self {
                    self.onError()
                }
            })
        default:
            imageView.image = placeholder
            setWebImage(url: url)
        }
    }

    private func showPlaceholder(_ placeholder: UIImage?) {
        imageView.image = placeholder
        hideWebView()
        webView.stopLoading()
    }

    private func setWebImage(url: URL) {
        hideWebView()
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, shrink-to-fit=YES"/>
        </head>
        <body style="background-color: #ffffff">
            <img src="\(url.absoluteString)" style="width: 100%; height: auto;"/>
        </body>
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

extension WebImageView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        showWebView()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onError()
    }
}
