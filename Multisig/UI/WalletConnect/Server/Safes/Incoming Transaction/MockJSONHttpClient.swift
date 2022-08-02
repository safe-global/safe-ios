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

    func asyncExecute<T: JSONRequest>(request: T, completion: @escaping (Result<T.ResponseType, Error>) -> ()) -> URLSessionTask? {
        //Check if we can handle the request
        // TODO: Remove because it's not needed 
        if request is TransactionPreviewRequest {
            let txData = jsonData("MultiSendApproveMultihopBatchSwapExactIn")
            do {
                let output: T.ResponseType = try self.response(from: txData)
                completion(.success(output))
            } catch {
                completion(.failure(error))
            }
        } else {
            print("---> TransactionPreviewRequest | Unexpected request... -> InvalidRequestError")
            completion(.failure("InvalidRequestError"))
        }

        return nil
    }

    private func response<T: Decodable>(from data: Data) throws -> T {
        var json = data
        if json.isEmpty {
            json = "{}".data(using: .utf8)!
        }
        let response: T
        do {
            response = try decoder.decode(T.self, from: json)
        } catch {
            print("Failed to decode response: \(error)")
            throw error
        }
        return response
    }

}

//class InvalidRequestError: Error {
//
//}
