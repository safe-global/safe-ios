//
// Created by Dirk Jäckel on 21.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WebKit
import UIKit

class SafeAppWebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("---->       didReceive message: \(message)")
        print("---->  didReceive message.name: \(message.name)")
        print("---->  didReceive message.body: \(message.body)")
        print("----> didReceive message.world.name: \(message.world.name)")
    }

    var webView: WKWebView!

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        webConfiguration.preferences = preferences
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webConfiguration.userContentController.add(self, name: "message")
        webConfiguration.userContentController.add(self, name: "click")
        webConfiguration.userContentController.add(self, name: "input")
        webConfiguration.userContentController.add(self, name: "load")

        let source = """
                     window.addEventListener('message', function(e) { 
                       window.webkit.messageHandlers.message.postMessage(JSON.stringify(e.data));
                     });

                     window.addEventListener('click', function(e) { 
                       window.webkit.messageHandlers.click.postMessage(JSON.stringify(e.data));
                     });

                     window.addEventListener('input', function(e) { 
                       window.webkit.messageHandlers.input.postMessage(JSON.stringify(e.data));
                     });

                     window.addEventListener('load', function(e) { 
                       window.webkit.messageHandlers.load.postMessage(JSON.stringify(e.data));
                     });
                     """
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webConfiguration.userContentController.addUserScript(script)


        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let myURL = URL(string: "https://cowswap.exchange")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }

    ///
    /// - Parameters:
    ///   - webView:
    ///   - navigationAction:
    ///   - decisionHandler:
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                          decisionHandler: @escaping (WKNavigationActionPolicy) -> Swift.Void) {

        //link to intercept www.example.com
        print("navigationAction: \(navigationAction)")
        // navigation types: linkActivated, formSubmitted,
        //                   backForward, reload, formResubmitted, other

        if navigationAction.navigationType == .linkActivated {
            if navigationAction.request.url!.absoluteString == "http://www.example.com" {
                //do stuff
                print("navigationAction: \(navigationAction)")
                //this tells the webview to cancel the request
                decisionHandler(.cancel)
                return
            }
        }

        //this tells the webview to allow the request
        decisionHandler(.allow)

    }

    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
        print("navigationAction: previewingViewController: \(previewingViewController)")
    }

    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        fatalError("webView(_:shouldPreviewElement:) has not been implemented")
    }
}
