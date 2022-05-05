//
//  SafeOwnerEditingController.swift
//  Multisig
//
//  Created by Moaaz on 4/26/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import Ethereum
import SafeAbi
import JsonRpc2

class SafeTransactionController {
    static let shared = SafeTransactionController()

    private init() { }

    func addOwnerWithThresholdTransaction(safe: Safe, safeTxGas: UInt256String?, nonce: UInt256String, owner: Address, threshold: Int) -> Transaction? {
        guard let data = addOwnerWithThresholdData(owner: owner, threshold: threshold) else { return nil }
        let tx = Transaction(safeAddress: safe.addressValue,
                             chainId: safe.chain!.id!,
                             toAddress: safe.addressValue,
                             contractVersion: safe.contractVersion!,
                             amount: "0",
                             data: data,
                             safeTxGas: safeTxGas ?? "0",
                             nonce: nonce)

        return tx
    }

    func addOwnerWithThresholdData(owner: Address, threshold: Int) -> Data? {
        guard let owner = Sol.Address.init(maybeData:owner.data32) else { return nil }
        let threshold = Sol.UInt256.init(threshold)
        return GnosisSafe_v1_3_0.addOwnerWithThreshold(owner: owner, _threshold: threshold).encode()
    }

    func replaceOwner(safe: Safe, prevOwner: Address?, oldOwner: Address, newOwner: Address, safeTxGas: UInt256String?, nonce: UInt256String) -> Transaction? {
        guard let data = replaceOwnerData(prevOwner: prevOwner, oldOwner: oldOwner, newOwner: newOwner) else { return nil }
        let tx = Transaction(safeAddress: safe.addressValue,
                             chainId: safe.chain!.id!,
                             toAddress: safe.addressValue,
                             contractVersion: safe.contractVersion!,
                             amount: "0",
                             data: data,
                             safeTxGas: safeTxGas ?? "0",
                             nonce: nonce)

        return tx
    }

    func replaceOwnerData(prevOwner: Address?, oldOwner: Address, newOwner: Address) -> Data? {
        guard let newOwner = Sol.Address.init(maybeData:newOwner.data32),
              let oldOwner = Sol.Address.init(maybeData:oldOwner.data32),
              let prevOwner = prevOwner == nil ? Sol.Address.init(maybeData: Address.init(exactly: "0x1").data32) :  Sol.Address.init(maybeData:prevOwner!.data32)
        else { return nil }

        return GnosisSafe_v1_3_0.swapOwner(prevOwner: prevOwner, oldOwner: oldOwner, newOwner: newOwner).encode()
    }

    func proposeTransaction(transaction: Transaction,
                            sender: Address,
                            chainId: String,
                            signature: String,
                            completion: @escaping (Result<SCGModels.TransactionDetails, Error>) -> Void) -> URLSessionTask? {
        let task = App.shared.clientGatewayService.asyncProposeTransaction(transaction: transaction,
                                                                sender: AddressString(sender),
                                                                signature: signature,
                                                                chainId: chainId) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                switch result {
                case .failure(let error):
                    if (error as NSError).code == URLError.cancelled.rawValue &&
                        (error as NSError).domain == NSURLErrorDomain {
                        // Estimation was canceled, ignore.
                        return
                    }

                default: break
                }

                completion(result)
            }
        }
        return task
    }

    func getOwners(safe: Address, chain: Chain, completion: @escaping (Result<[Address], Error>) -> Void) -> URLSessionTask? {
        let rpcClient = JsonRpc2.Client(transport: JsonRpc2.ClientHTTPTransport(url: chain.authenticatedRpcUrl.absoluteString), serializer: JsonRpc2.DefaultSerializer())

        let tx: EthTransaction = Eth.TransactionEip1559(
            to: Sol.Address(maybeData: safe.data32)!,
            input: Sol.Bytes(storage: GnosisSafe_v1_3_0.getOwners().encode())
        )

        // latest is the default for web3 js lib, replicating it here
        let block: EthRpc1.BlockSpecifier = .tag(.latest)

        let ethCall = EthRpc1.eth_callLegacyApi(transaction: EthRpc1.EstimateGasLegacyTransaction(tx), block: block)


        let request: JsonRpc2.Request
        do {
            request = try ethCall.request(id: .int(0))
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        let task = rpcClient.send(request: request) { response in
            guard let response = response else {
                dispatchOnMainThread(completion(.failure("No response")))
                return
            }

            if let error = response.error {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            guard let result = response.result else {
                dispatchOnMainThread(completion(.failure("No result")))
                return
            }

            do {
                let contractResponse = try ethCall.result(from: result).storage

                let returns = try GnosisSafe_v1_3_0.getOwners.Returns.init(contractResponse)
                let addresses = returns._arg0.elements.compactMap(Address.init)
                dispatchOnMainThread(completion(.success(addresses)))
            } catch {
                dispatchOnMainThread(completion(.failure(error)))
            }
        }

        return task
    }
}
