//
// Created by Dirk Jäckel on 21.06.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import WebKit
import UIKit
import JsonRpc2
import Json
import Ethereum


class SafeAppWebViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {

    // TODO: Next steps
    // - Embed webview in NavBarController so there is a back button to go back
    // - Decide, where the entry point should be and enter WebView form there if it is not too hidden :-)
    // - hand over rpcCalls and post result to WebView
    //    - rpcCalls - done
    // - handle Missing calls:
    //    sendTransactions - POC
    //    getChainInfo
    //    getTxBySafeTxHash
    //    getSafeBalances
    //    signMessage

    private var rpcClient: JsonRpc2.Client? = nil
    private let safe: Safe = try! Safe.getSelected()!

    func clientForChain(_ chain: Chain) {
        let urlString = chain.authenticatedRpcUrl.absoluteString
        rpcClient = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: urlString), serializer: JsonRpc2.DefaultSerializer())
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        handleMessage(message.body as? String)
    }

    var webView: WKWebView!

    private func handleMessage(_ message: String?) {
        //LogService.shared.debug(" | message: \(message!)")

        if let message = message {
            if message.contains("getSafeInfo") {
                handleGetSafeInfo(message)
            } else if message.contains("rpcCall") {
                handleRpcCall(message)
            } else if message.contains("sendTransactions") {
                handleSendTransactions(message)
            } else {
                if (!message.contains("\"success\":true,")) {
                    LogService.shared.error(" | Unknown message: \(message)")
                }
            }
        }
    }

    private func handleSendTransactions(_ message: String) {

        let decoder = JSONDecoder()
        let jsonData = message.data(using: .utf8)!
        do {
            let result = try decoder.decode(SendTransactionsData.self, from: jsonData)
            LogService.shared.debug(" | txs: \(result)")
            let privateKey = try! PrivateKey(data: Data(hex: "0xda18066dda40499e6ef67a392eda0fd90acf804448a765db9fa9b6e7dd15c322")) //0xE86935943315293154c7AD63296b4e1adAc76364

            //TODO get nonce from estimate Call. This only works if queue is empty
            if let safeNonce = safe.nonce {
                let nonce: UInt256String = UInt256String(safeNonce)
                // TODO create a Transaction for signing
                if let tx = result.params?.txs?[0],
                   let id = safe.chain?.id,
                   let to = tx.to {
                    if let transaction: Transaction = Transaction(
                            safeAddress: safe.addressValue,
                            chainId: id,
                            toAddress: Address(exactly: to.value),
                            contractVersion: safe.contractVersion!,
                            amount: tx.value,
                            data: tx.data?.data ?? Data(),
                            safeTxGas: "0",
                            nonce: nonce
                    ) {
                        LogService.shared.info(" ------>       transaction to be signed: \(transaction)")

                        // TODO Sign tx
                        let signature = try SafeTransactionSigner().sign(transaction, key: privateKey)

                        // TODO Propose transaction
                        LogService.shared.info(" ------>       signature: \(signature)")

                        let address: Address = "0xE86935943315293154c7AD63296b4e1adAc76364" // owner address
                        let keyInfo: KeyInfo = try! KeyInfo.firstKey(address: address)!

                        proposeTransaction(transaction: transaction, keyInfo: keyInfo, signature: signature.hexadecimal, id: result.id!)

                    }
                }
            }


        } catch {
            LogService.shared.error(" | Exception thrown while decoding message: \(message) \(error)")
        }

    }

    private func proposeTransaction(transaction: Transaction, keyInfo: KeyInfo, signature: String, id: String) {
        let currentDataTask = App.shared.clientGatewayService.asyncProposeTransaction(transaction: transaction,
                sender: AddressString(keyInfo.address),
                signature: signature,
                chainId: safe.chain!.id!) { result in
            // NOTE: sometimes the data of the transaction list is not
            // updated right away, we'll give a moment for the backend
            // to catch up before finishing with this request.
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) {
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    //TODO call back
                    //self.endConfirm()
                    switch result {
                    case .failure(let error):
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                                   (error as NSError).domain == NSURLErrorDomain {
                            return
                        }
                        App.shared.snackbar.show(error: GSError.error(description: "Failed to create transaction", error: error))
                    case .success(let transaction):
                        NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)


                        // TODO return safeTxHas to the web view
                        if let safeTxHash = transaction.multisigInfo?.safeTxHash {

                            self.webView.evaluateJavaScript("""
                                                            successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":{"safeTxHash": "\(safeTxHash)"}}');
                                                            iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                                            iframe.contentWindow.postMessage(successMessage);
                                                            """) { any, error in
                                LogService.shared.debug(" | \(any) error in JS execution: \(error)")
                            }
                        }
                    }
                }
            }
        }
    }

    private func handleRpcCall(_ message: String) {
        if let chain = safe.chain {
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
                LogService.shared.error(" | Exception thrown while decoding message: \(message)")
            }
        }
    }

    private func handleGetSafeInfo(_ message: String) {
        LogService.shared.debug(" | handleGetSafeInfo()")
        LogService.shared.debug(" | Message: \(message)")

        let decoder = JSONDecoder()
        let jsonData = message.data(using: .utf8)!
        do {
            let result = try decoder.decode(SafeInfoRequestData.self, from: jsonData)
            // {"id":"72a4662487","method":"getSafeInfo","env":{"sdkVersion":"6.2.0"}}

            LogService.shared.debug(" |     id: \(result.id!)")
            LogService.shared.debug(" | method: \(result.method!)")
            LogService.shared.debug(" |    env: \(result.env!)")

            try! sendSafeInfoResponse(id: result.id!, method: result.method!, address: safe.address!, chainId: safe.chain?.id ?? "1", threshold: safe.threshold ?? 1)

        } catch {
            LogService.shared.debug(" | Exception thrown while decoding message: \(message)")
        }
    }

    private func sendSafeInfoResponse(id: String, method: String, address: String?, chainId: String, threshold: UInt256) {
        let response = """
                       {"safeAddress":"\(address!)","chainId":\(chainId),"threshold":\(threshold),"owners":[]}
                       """

        LogService.shared.debug(" |    response: \(response)")

        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":\(response)}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            LogService.shared.debug(" | \(any) error in JS execution: \(error)")
        }
    }

    private func sendRpcResponse(id: String, response: JsonRpc2.Response?) {

        var responseDataString: String = "[]"
        let encoder = JSONEncoder()

        switch response?.result {
        case .object(let value):
            responseDataString = try! encoder.encode(value).makeString()
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
        case .none, .null:
            responseDataString = ""
        }

        LogService.shared.debug(" | responseAsData: \(responseDataString)")
        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":\(responseDataString)}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            LogService.shared.debug(" | \(any) error in JS execution: \(error)")
        }
    }

    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true


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


    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {

        // Set the message as the UIAlertController message
        let alert = UIAlertController(
                title: nil,
                message: message,
                preferredStyle: .alert
        )

        // Add a confirmation action "OK"
        let okAction = UIAlertAction(
                title: "OK",
                style: .default,
                handler: { _ in
                    // Call completionHandler confirming the choice
                    completionHandler(true)
                }
        )
        alert.addAction(okAction)

        // Add a cancel action "Cancel"
        let cancelAction = UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: { _ in
                    // Call completionHandler cancelling the choice
                    completionHandler(false)
                }
        )
        alert.addAction(cancelAction)

        // Display the NSAlert
        present(alert, animated: true, completion: nil)
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
    var value: UInt256String?
    var data: DataString?
    var gas: UInt256String?
    var from: UInt256String?
    var to: UInt256String?
}
