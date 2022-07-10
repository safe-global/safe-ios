//
// Created by Dirk Jäckel on 08.07.22.
// Copyright (c) 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Multisig

class MockJSONHttpClient {

    typealias TxData = SCGModels.TxData

    var decoder: JSONDecoder = JSONDecoder()

    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
    }

    private func loadAndParseFile(fileName: String) throws -> SCGModels.TransactionDetails? {
        let data = jsonData(fileName)
        return try decoder.decode(SCGModels.TransactionDetails.self, from: data)
    }

    private func jsonData(_ name: String) -> Data {
        try! Data(contentsOf: Bundle(for: Self.self).url(forResource: name, withExtension: "json")!)
    }

//    private func request<T: JSONRequest>(from request: T) throws -> Request {
//        let requestData = request.httpMethod != "GET" ? (try jsonEncoder.encode(request)) : nil
//        let requestHeaders = request.httpMethod != "GET" ? ["Content-Type": "application/json"] : [:]
//        let httpRequest = Request(httpMethod: request.httpMethod,
//                urlPath: request.urlPath,
//                query: request.query,
//                body: requestData,
//                headers: requestHeaders,
//                url: request.url)
//        return httpRequest
//    }

    public func execute<T: JSONRequest>(request jsonRequest: T) throws -> T.ResponseType? {
//        let request = try self.request(from: jsonRequest)
        //TODO check we can handle the request
        if jsonRequest is TransactionPreviewRequest {
            //TODO: Get response here from file and serve it
            let tx = try! loadAndParseFile(fileName: "MultiSendApproveMultihopBatchSwapExactIn")

            print("---> TransactionPreviewRequest | tx: \(tx)")
            print("---> TransactionPreviewRequest | TransactionPreviewRequest....")

            //completion(.success(tx))
        } else {

            print("---> TransactionPreviewRequest | Unexpected request... -> error")
            //completion(.failure(error))
        }

        return nil
    }

    func asyncExecute<T: JSONRequest>(request: T, completion: @escaping (Result<T.ResponseType, Error>) -> ()) -> URLSessionTask? {
        //TODO check we can handle the request
        if request is TransactionPreviewRequest {
            //TODO: Get response here from file and serve it
            let tx = try! loadAndParseFile(fileName: "MultiSendApproveMultihopBatchSwapExactIn")

            print("---> TransactionPreviewRequest | tx: \(tx)")
            print("---> TransactionPreviewRequest | TransactionPreviewRequest....")

            //completion(.success(tx))
        } else {

            print("---> TransactionPreviewRequest | Unexpected request... -> error")
            //completion(.failure(error))
        }

        return nil
    }
}
