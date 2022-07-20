//
// Created by Dirk Jäckel on 21.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WebKit
import UIKit
import JsonRpc2
import Json

class SafeAppWebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {

    // TODO: Next steps
    // - Embed webview in NavBarController so there is a back button to go back
    // - Decide, where the entry point should be and enter WebView form there if it is not too hidden :-)
    // - hand over rpcCalls and post result to WebView
    //    -
    // - handle Missing calls:
    //    sendTransactions
    //    getChainInfo
    //    getTxBySafeTxHash
    //    getSafeBalances
    //    signMessage

    private var rpcClient: JsonRpc2.Client? = nil

    func clientForChain(_ chain: Chain) {
        let urlString = chain.authenticatedRpcUrl.absoluteString
        rpcClient = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: urlString), serializer: JsonRpc2.DefaultSerializer())
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handleMessage(message.body as? String)
    }

    var webView: WKWebView!

    private func handleMessage(_ message: String?) {
        print("\(#file).\(#function) | message: \(message!)")

        if let message = message {
            if message.contains("getSafeInfo") {
                handleGetSafeInfo(message)
            } else if message.contains("rpcCall") {
                handleRpcCall(message)
            } else if message.contains("sendTransactions") {
                handleSendTransactions(message)
            } else {
                print("\(#file).\(#function) | Unknown message: \(message)")
            }
        }
    }

    private func handleSendTransactions(_ message: String) {

        let decoder = JSONDecoder()
        let jsonData = message.data(using: .utf8)!
        do {
            let result = try decoder.decode(SendTransactionsData.self, from: jsonData)

            print("-------> \(#file).\(#function) | txs: \(result)")



        } catch {
            print("\(#file).\(#function) | Exception thrown while decoding message: \(message)")
        }

    }

    private func handleRpcCall(_ message: String) {
        if let chain = try! Safe.getSelected()?.chain {
            clientForChain(chain)

            let decoder = JSONDecoder()
            let jsonData = message.data(using: .utf8)!
            do {
                let result = try decoder.decode(RpcCallData.self, from: jsonData)
                if let call = result.params?.call {
                    let request = JsonRpc2.Request(
                            jsonrpc: "2.0",
                            method: call,
                            params: result.params?.params,
                            id: .string(result.id!)
                    )

                    rpcClient!.send(request: request) { (response: JsonRpc2.Response?) in
                        self.sendRpcResponse(id: result.id!, response: response)
                    }
                }
            } catch {
                print("\(#file).\(#function) | Exception thrown while decoding message: \(message)")
            }
        }
    }

    private func handleGetSafeInfo(_ message: String) {
        print("\(#file).\(#function) | handleGetSafeInfo()")
        print("\(#file).\(#function) | Message: \(message)")

        let decoder = JSONDecoder()
        let jsonData = message.data(using: .utf8)!
        do {
            let result = try decoder.decode(SafeInfoRequestData.self, from: jsonData)
            // {"id":"72a4662487","method":"getSafeInfo","env":{"sdkVersion":"6.2.0"}}

            print("\(#file).\(#function) |     id: \(result.id!)")
            print("\(#file).\(#function) | method: \(result.method!)")
            print("\(#file).\(#function) |    env: \(result.env!)")

            try! sendSafeInfoResponse(id: result.id!, method: result.method!, address: Safe.getSelected()?.address!, chainId: Safe.getSelected()?.chain?.id ?? "1", threshold: Safe.getSelected()?.threshold ?? 1)

        } catch {
            print("\(#file).\(#function) | Exception thrown while decoding message: \(message)")
        }
    }

    private func sendSafeInfoResponse(id: String, method: String, address: String?, chainId: String, threshold: UInt256) {
        let response = """
                       {"safeAddress":"\(address!)","chainId":\(chainId),"threshold":\(threshold),"owners":[]}
                       """

        print("------> \(#file).\(#function) |    response: \(response)")

        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":\(response)}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            print("\(#file).\(#function) | \(any) error in JS execution: \(error)")
        }
    }

    private func sendRpcResponse(id: String, response: JsonRpc2.Response?) {

        var responseDataString: String = "[]"
        let encoder = JSONEncoder()

        switch response?.result {
        case .object(let value):
            responseDataString = try! encoder.encode(value).makeString()
        case .none:
            responseDataString = ""
        case .string(let value):
            responseDataString = try! encoder.encode(value).makeString()
        case .array(let value):
            responseDataString = try! encoder.encode(value).makeString()
        case .int(let value):
            responseDataString = try! encoder.encode(value).makeString()
        case .uint(let value):
            responseDataString = try! encoder.encode(value).makeString()
        case .double(let value):
            responseDataString = try! encoder.encode(value).makeString()
        case .bool(let value):
            responseDataString = try! encoder.encode(value).makeString()
        case .null:
            responseDataString = ""
        }

        print("---------> \(#file).\(#function) | responseAsData: \(responseDataString)")
        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":\(responseDataString)}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            print("\(#file).\(#function) | \(any) error in JS execution: \(error)")
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
    var params: JsonRpc2.Params
}

struct SafeInfoRequestData: Codable {
    var id: String?
    var method: String?
    var env: EnvironmentData?
}

struct EnvironmentData: Codable {
    var sdkVersion: String?
}

struct SafeInfoResponseData: Codable {
    var id: String?
    var method: String
}

struct SendTransactionsData: Codable {
    var id: String?
    var method: String?
    var params: SendTxParams?
}

struct SendTxParams: Codable {
    var txs: [SendTx]?
}

struct SendTx: Codable {
    var value: String?
    var data: String?
    var gas: String?
    var from: String?
    var to: String?
}