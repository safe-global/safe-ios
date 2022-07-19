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
    //    -
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
            } else if message.contains("rpcCall") {
                handleRpcCall(message)
            } else {
                print("\(#file).\(#function) | Unknown message: \(message)")
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
            print("\(#file).\(#function) |     id: \(result.id!)")
            print("\(#file).\(#function) | method: \(result.method!)")
            print("\(#file).\(#function) |    env: \(result.env!)")
            print("\(#file).\(#function) | params: \(result.params!)")

            // TODO: Execute RPC call asynchronously and gather result
            if result.params?.call! == "eth_getCode" {
                try! sendGetCodeResponse(id: result.id!)
            } else if result.params?.call! == "eth_getBlockByNumber" {
                try! sendLatestBlockResponse(id: result.id!)
            }

        } catch {
            print("\(#file).\(#function) | Exception thrown while decoding message: \(message)")
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

            try! sendSafeInfoResponse(id: result.id!, method: result.method!, address: Safe.getSelected()?.address!)

        } catch {
            print("\(#file).\(#function) | Exception thrown while decoding message: \(message)")
        }
    }

    private func sendSafeInfoResponse(id: String, method: String, address: String?) {
        print("\(#file).\(#function) | address: \(address)")
        let response = """
                       {"safeAddress":"\(address!)","chainId":4,"threshold":2,"owners":[]}
                       """
        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":\(response)}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            print("\(#file).\(#function) | \(any) error in JS execution: \(error)")
        }
    }

    private func sendGetCodeResponse(id: String) {
        print("\(#file).\(#function) | id: \(id)")

        let response = """
                       {"result":"0x608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e0000000000000000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea265627a7a72315820d8a00dc4fe6bf675a9d7416fc2d00bb3433362aa8186b750f76c4027269667ff64736f6c634300050e0032"}
                       """
        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":\(response)}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            print("SafeAppWebViewController.\(#function) | \(any) error in JS execution: \(error)")
        }
    }


    private func sendLatestBlockResponse(id: String) {
        print("SafeAppWebViewController | id: \(id)")

        let response = """
                       {"result":
                       {
                         "baseFeePerGas": "0x14",
                         "difficulty": "0x1",
                         "extraData": "0xd883010a11846765746888676f312e31372e38856c696e7578000000000000004a85428b61a4a1b8244c75d135a1a716ac800526636b8e666adeabdccdbcca290ea24252b77a2797c69324597e0f6f4a0a110f1c1136df0a79af0964b0a5107d00",
                         "gasLimit": "0x1c9c380",
                         "gasUsed": "0x13d9beb",
                         "hash": "0x91038a51090e9b5c646894d61845858eefcf3c80fb445fdebf35f12dc629f6d5",
                         "logsBloom": "0xa5641306103850080020000080c408058100402100440205008080008a0040044810147158001040001508200a000845000064200280208d030002c24065240400b042000020040c70012548000047a00413d20900440050000142040040040a20a00d4406b0a000020814098000980020000080aa084020210030916818c8402801820000101020100821208008c40041824180004c000940210140420400350a2080900400533261c02148a30000020004a84021c118400858004681404042600212028000003144020100022100009a10d109880982b100100102b109610260108e900b40808402a11800010008000008090000a8822080280001088a4400",
                         "miner": "0x0000000000000000000000000000000000000000",
                         "mixHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
                         "nonce": "0x0000000000000000",
                         "number": "0xa8a3ad",
                         "parentHash": "0x150e45676f76153c4f8a39ec4b9165547d2c001672afc8f2fc71a52f69c23d6a",
                         "receiptsRoot": "0x5732d3cc3ab7f4dc090acd4bc4419aae753fba8a9168f86a6d695b1700dc7cc1",
                         "sha3Uncles": "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
                         "size": "0x17032",
                         "stateRoot": "0xe82e739d6e1cd74cd56880045d9ba6d4d0b96bf246c5c99af06b21b1abc80d95",
                         "timestamp": "0x62d6b5b5",
                         "totalDifficulty": "0x114261b",
                         "transactions": [
                           "0xf039a5e24cd99234c782bc809040e906e1d61ca315d247cfa5fa9b3965ed8bee",
                           "0x892e2e9038f3a33b9f39f851c1778e991b9aabcd5f574db08b607a10a2cd1003",
                           "0x2fc37c275f91a56a67e71d9b7ef1bdc2724f8fdb133f4822d5fb8d437fe0a3af",
                           "0x8dba4d72f1af5a7dd17a010c6766f43c8c661dd1ff8e2025fcd6cbb3909e8816",
                           "0x7cb6394f0e4fdf92eae9b8275fd8a00f983bb7a05e82d922603e9798369e4959",
                           "0x3cfcbddd59d59ca60ee9e67a9df04a7e4a77fea1d706571de76051deb7001fe2",
                           "0x36ee1b18e79caf715c44e2ff5e92de4cb8ca3980ac7e7e1b6841757e5ed6f1bc",
                           "0x9c0955cf48fd097b670d7a02b5e010c0b9160a5f85ae43af1be1b90aa38b5312",
                           "0x11966c11d7527389a18ba41f0d0cd33cdd8a1227b87fff16f82ef918d6cb6236",
                           "0x7b5121e0c22f2bb795158869ceaec3818f1ad2deb7dade2aaf4c8ffc04651ff2",
                           "0x9d27434c0f0fc628fcbb2a01c10b913102102e56aeffc34cfbd89579b2cd6644",
                           "0x44c7b56352b6b776712b473c91aa498343eb3d70478e84f6332241be60325d4f",
                           "0x69389ed98e6551840e1f7abb8e5c8afeacfd5e5db0be0d5b7cfe58b2fd3cb685",
                           "0x39e785399415c5392ab11bf74c0eee82a9e5b6817ebc741c43afeb777f78420c",
                           "0x95200e8c22fc7d454ab2c03e6343cdee7e309e1fb6c1935588322fd59fdc14de",
                           "0x35c3d608e39379b16d07ea7797dc40c3515b69d595be952a76410df9fca16f4b",
                           "0x5c96c63277a2445c119bfb6df6e9f313137f451b5a874bd69a49d3b722c79261",
                           "0xe914380c518df47d1745720629c47698d6cb9e3ab5dcd8e94ca5a109e7a5bf53",
                           "0x99b0b33e5c0cdbbc2f9eae808783afe070ec9ee176e4369f0524c5c0f7e9de43",
                           "0xa7507dfa5895fe324ea8a0ed92b737502dddce8accc30b81c73cc0ff923dc11b",
                           "0x5940e62a5a7a2de6f1608f677924df550df262e718fe7eaf5f9b64673dafa0ab",
                           "0xd7d46c46649eb442d16250efde6dc958f138c1fa2ac6edd9104013e645901611",
                           "0x48f66d1ab8ed50c00169f121a1c11e614574f20e04a0e64d3fdef2b7630c3fb6",
                           "0x4b766e2d1feab49bf373ca2daddc424e980dba29c97980b79e6dea4c6ed61c45",
                           "0xf5b230c74fed45897ed35434e66fa6cb99b1f1f3cf327e02677b1eb9834cac25",
                           "0x07b75a160ece7971936ff1498a5df9ca102f893b31f2481cc603f6487414cc82",
                           "0xd7f121dff19be83fea1e4fc677823d1dd172840dbdd387356bdf57ef6779df78",
                           "0x61bcb95279a77cc01696ffaf20fc4f8723fb31d1cf02d8213c432a0d67c328a6",
                           "0xda48608f54b1bb0ab789d1250f1e49c6d067444381847ea8325b55345abd82cd",
                           "0xf91073c287e76a476b0e2327f29cac137d154ec662b32db6eb32d248a323605f",
                           "0xfe8d0f4071f5b4c6a9c24f5a3a2815c6df27434d084a2fd224ca9322b6bdb062",
                           "0x8696a6b41534e462e7ead8bbae733ef8c32627adf88fb5b8d1c27dda6cb0f34d",
                           "0x0d85d7c4449f6beafa06ed28fa1a3d3e6a047de3f5f5cfc7a3a660691b4e91ed",
                           "0x6f8b546059357a5b08c5fd7e07fc73d3188d4f65dd802e9b84601d0a86b8632f",
                           "0xefd2d95411d5a3a9e0aaa6d356ff8126878c68690d3ae79076e48e613ecf77cc",
                           "0x799d9001e5d7fd5a0979d1a4c7fd971ae5807452a6e45a725d2235c7ea03f5c7",
                           "0x71561ea9623e30eb9b56bfa941f0bad21e116580b92ecb85c7212289499ecf8e",
                           "0x4ed19509bfaa71e7dcc0ec0d35a95ef5959e4b34ccf1db66dd45e54fc0c682d0",
                           "0x9f369b910abf22c971c49109f85e85f7d91ef3004b5ea675023e835d22ec54af"
                         ],
                         "transactionsRoot": "0xb7ec57e563c7ffb977889cb034defa1c9789fe82ea9e83d95719a9589d63e7e1",
                         "uncles": []
                       }
                       }
                       """
        webView.evaluateJavaScript("""
                                   successMessage = JSON.parse('{"id":"\(id)","success":true,"version":"6.2.0","data":\(response)}');
                                   iframe = document.getElementById('iframe-https://cowswap.exchange'); 
                                   iframe.contentWindow.postMessage(successMessage);
                                   """) { any, error in
            print("SafeAppWebViewController.\(#function) | \(any) error in JS execution: \(error)")
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
    //var params: [String]? // What type can we use if strings and booleans are mixed in the array?
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