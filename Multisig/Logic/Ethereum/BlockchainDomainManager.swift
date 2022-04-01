//
//  BlockchainDomainManager.swift
//  Multisig
//
//  Created by Johnny Good on 1/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation
import UnstoppableDomainsResolution

class BlockchainDomainManager {
    private(set) var ens: ENS?
    private(set) var unstoppableDomainResolution: Resolution?

    private static let networkNames = ["1": "mainnet",
                                       "3": "ropsten",
                                       "4": "rinkeby",
                                       "5": "goerli"]

    init(rpcURL: URL, chainId: String, ensRegistryAddress: AddressString?) {
        if let ensRegistryAddress = ensRegistryAddress {
            ens = ENS(registryAddress: ensRegistryAddress.address, rpcURL: rpcURL)
        }

        guard let networkName = Self.networkNames[chainId] else { return }
        do {
            self.unstoppableDomainResolution = try Resolution(
                configs: Configurations(
                    cns: NamingServiceConfig(
                        providerUrl: rpcURL.absoluteString,
                        network: networkName,
                        networking: GSNetworkingLayer()
                    )
                )
            )
        } catch {
            LogService.shared.error("Failed to configure Unstoppable Domains: \(error)")
        }
    }
    
    func resolveUD(_ domain: String) throws -> Address {
        guard let resolution = unstoppableDomainResolution else {
            throw GSError.UDUnsupportedNetwork()
        }
        
        guard domain.hasSuffix(".crypto") || domain.hasSuffix(".zil") else {
            throw GSError.UDUnsuportedName()
        }

        var address: String = ""
        var resolutionError: Error? = nil
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        resolution.addr(domain: domain, ticker: "eth") { result in
            switch result {
                case .success(let returnValue):
                    address = returnValue
                case .failure(let error):
                  resolutionError = error
            }
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        
        if let error = resolutionError as? ResolutionError {
          throw self.throwCorrectUdError(error, domain)
        } else if let error = resolutionError {
          throw error
        }

        return try Address(from: address)
    }
    
    func resolveEnsDomain(domain: String) throws -> Address {
        try ens!.address(for: domain)
    }

    func ensName(for address: Address) -> String? {
        ens!.name(for: address)
    }
    
    func throwCorrectUdError(_ error: ResolutionError, _ domain: String) -> DetailedLocalizedError {
        switch error {
        case .unregisteredDomain:
            return GSError.UDUnregisteredName()
        case .unspecifiedResolver:
            return GSError.UDResolverNotFound()
        case .unknownError(let internalError):

            switch internalError {
            case APIError.decodingError:
                return GSError.UDDecodingError()
            case APIError.encodingError:
                return GSError.UDEncodingError()
            case let detailedError as DetailedLocalizedError:
                return detailedError
            default:
                break
            }

            fallthrough
        default:
            return GSError.ThirdPartyError(
                reason: error.localizedDescription
            )
        }
    }
}

// Taken from the DefaultNetworkingLayer implementation to replace
// the error handling with more descriptive error from HTTTPClient
public struct GSNetworkingLayer: NetworkingLayer {
    public init() { }

    public func makeHttpPostRequest(url: URL,
                                    httpMethod: String,
                                    httpHeaderContentType: String,
                                    httpBody: Data,
                                    completion: @escaping(Result<JsonRpcResponseArray, Error>) -> Void) {

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod
        urlRequest.addValue(httpHeaderContentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = httpBody

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, httpError in
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let jsonData = data else {
                let error = HTTPClientError.error(urlRequest, response, data, httpError)
                completion(.failure(error))
                return
            }

            do {
                let result = try JSONDecoder().decode(JsonRpcResponseArray.self, from: jsonData)
                completion(.success(result))
            } catch {
                do {
                    let result = try JSONDecoder().decode(JsonRpcResponse.self, from: jsonData)
                    completion(.success([result]))
                } catch {
                    if let errorResponse = try? JSONDecoder().decode(NetworkErrorResponse.self, from: jsonData),
                       let errorExplained = GSNetworkingLayer.gs_parse(errorResponse: errorResponse) {
                        completion(.failure(errorExplained))
                    } else {
                        completion(.failure(APIError.decodingError))
                    }
                }
            }
        }
        dataTask.resume()
    }

    struct NetworkErrorResponse: Decodable {
        var jsonrpc: String
        var id: String
        var error: ErrorId
    }

    struct ErrorId: Codable {
        var code: Int
        var message: String
    }

    static let gs_tooManyResponsesCode = -32005
    static let gs_badRequestOrResponseCode = -32042

    static func gs_parse(errorResponse: NetworkErrorResponse) -> ResolutionError? {
        let error = errorResponse.error
        if error.code == gs_tooManyResponsesCode {
            return .tooManyResponses
        }
        if error.code == gs_badRequestOrResponseCode {
            return .badRequestOrResponse
        }
        return nil
    }
}
