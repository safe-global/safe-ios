//
// Created by Dirk Jäckel on 21.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WebKit
import UIKit

class SafeAppWebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {

    // TODO: Next steps
    // - Embed webview in NavBarController so there is a back button to go back
    // - Decide, where the entry point should be and enter WebView form there if it is not too hidden :-)
    // - hand over rpcCalls and post result to WebView
    // - handle Missing calls:
    //    sendTransactions
    //    getChainInfo
    //    getTxBySafeTxHash
    //    getSafeBalances
    //    signMessage


    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handleMessage(message.body as? String)
    }

    var webView: WKWebView!

    private func handleMessage(_ message: String?) {

        if let message = message {
            if message.contains("getSafeInfo") {
                handleGetSafeInfo(message)
            } else if  message.contains("rpcCall"){
                handleRpcCall(message)
            } else {
                print("SafeAppWebViewController | Unknown message: \(message)")
            }
        }
    }

    private func handleRpcCall(_ message: String) {
        let decoder = JSONDecoder()
        let jsonData = message.data(using: .utf8)!
        do {
            let result = try decoder.decode(RpcCallData.self, from: jsonData)
            // {"id":"4a59adf4dc","method":"rpcCall","params":{"call":"eth_getCode","params":["0x1c8b9b78e3085866521fe206fa4c1a67f49f153a","latest"]},"env":{"sdkVersion":"6.2.0"}}
            // {"id":"b026a52183","method":"rpcCall","params":{"call":"eth_getBlockByNumber","params":["latest",false]},"env":{"sdkVersion":"6.2.0"}} <- Not parsed correctly because of Boolean in call params
            print ("SafeAppWebViewController |     id: \(result.id!)")
            print ("SafeAppWebViewController | method: \(result.method!)")
            print ("SafeAppWebViewController |    env: \(result.env!)")
            print ("SafeAppWebViewController | params: \(result.params!)")

            // TODO: Execute RPC call asynchronously and gather result

        } catch {
            print("SafeAppWebViewController | Exception thrown while decoding message: \(message)")
        }
    }

    private func handleGetSafeInfo(_ message: String) {
        print("SafeAppWebViewController | handleGetSafeInfo()")
        print("SafeAppWebViewController | Message: \(message)")

        let decoder = JSONDecoder()
        let jsonData = message.data(using: .utf8)!
        do {
            let result = try decoder.decode(SafeInfoRequestData.self, from: jsonData)
            // {"id":"72a4662487","method":"getSafeInfo","env":{"sdkVersion":"6.2.0"}}

            print ("SafeAppWebViewController |     id: \(result.id!)")
            print ("SafeAppWebViewController | method: \(result.method!)")
            print ("SafeAppWebViewController |    env: \(result.env!)")

            try! sendResponse(id: result.id!, method: result.method!, address: Safe.getSelected()?.address!)

        } catch {
            print("SafeAppWebViewController | Exception thrown while decoding message: \(message)")
        }
    }

    private func sendResponse(id: String, method: String, address: String?) {
        print("SafeAppWebViewController | aaddress: \(address)")

        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":{"safeAddress":"\(address!)","chainId":4,"threshold":2,"owners":[]}}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            print("SafeAppWebViewController | \(any) error in JS execution: \(error)")
        }
    }

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        webConfiguration.preferences = preferences
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webConfiguration.userContentController.add(self, name: "messageData")

        let source = """
                     window.addEventListener('message', function(e) { 
                       window.webkit.messageHandlers.messageData.postMessage(JSON.stringify(e.data));
                     });
                     """
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webConfiguration.userContentController.addUserScript(script)

        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

//        let urlString = "https://app.uniswap.org"
        let urlString = "https://cowswap.exchange"

        let myURL = URL(string: urlString)
        let myRequest = URLRequest(url: myURL!)
        webView.loadHTMLString("""
                               <html>
                                    <head>
                                        <meta name="viewport" content="width=device-width,initial-scale=1.0">
                                    </head>
                                    <body>
                                        <iframe height="100%" width="100%" frameborder="0" id="iframe-\(urlString)" src="\(urlString)" title="Safe-App" allow="camera" class="sc-fvpsdx leyeXM">
                                        </iframe>
                                    </body>
                               </html>
                               """, baseURL: myURL)
    }
}

struct RpcCallData: Codable {
    var id: String?
    var method: String?
    var params: RpcCallParamsData?
    var env: EnvironmentData?
}
struct RpcCallParamsData: Codable {
    var call: String?
    var params: [String]? // What type can we use if strings and booleans are mixed in the array?
}
struct SafeInfoRequestData: Codable {
    var id: String?
    var method: String?
    var env: EnvironmentData?
}
struct EnvironmentData: Codable {
    var sdkVersion: String?
}
struct SafeInfoResponseData: Codable  {
    var id: String?
    var method: String
}