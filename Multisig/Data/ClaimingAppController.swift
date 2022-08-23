//
//  ClaimingAppController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.08.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import SafeAbi
import Solidity

class ClaimingAppController {

    struct Configuration {
        var safeToken: Sol.Address
        var userAirdrop: Sol.Address
        var ecosystemAirdrop: Sol.Address
        var delegateRegistry: Sol.Address
        var delegateId: Sol.Bytes32 = Sol.Bytes32(storage: "safe.eth".data(using: .utf8)!.rightPadded(to: 32))

        static let rinkeby = Configuration(
            safeToken: "0xCFf1b0FdE85C102552D1D96084AF148f478F964A",
            userAirdrop: "0x6C6ea0B60873255bb670F838b03db9d9a8f045c4",
            ecosystemAirdrop: "0x82F1267759e9Bea202a46f8FC04704b6A5E2Af77",
            // https://github.com/gnosis/delegate-registry/blob/main/networks.json
            delegateRegistry: "0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446"
        )
    }

    var configuration: Configuration
    var rpcClient: RpcClient
    var claimingService: SafeClaimingService

    init(configuration: Configuration = .rinkeby, chain: Chain = .rinkebyChain()) {
        self.configuration = configuration
        self.rpcClient = RpcClient(chain: chain)
        claimingService = App.shared.claimingService
    }

    // MARK: - Static data

    func guardians(completion: @escaping (Result<[Guardian], Error>) -> Void) -> URLSessionTask? {
        claimingService.asyncGuardians(completion: completion)
    }

    func allocations(address: Address, completion: @escaping (Result<[Allocation], Error>) -> Void) -> URLSessionTask? {
        claimingService.asyncAllocations(account: address, completion: completion)
    }

    // MARK: - Safe Token Contract

    func isSafeTokenPaused(completion: @escaping (Result<Bool, Error>) -> Void) -> URLSessionTask? {
        return rpcClient.eth_call(
            to: configuration.safeToken,
            input: SafeToken.paused()
        ) { contractResult in
            let result = contractResult.map { pausedResult in
                return pausedResult._arg0.storage
            }
            completion(result)
        }
    }

    // MARK: - Airdrop Contract

    func vesting(id: Sol.Bytes32, contract: Sol.Address, completion: @escaping (Result<Airdrop.vestings.Returns, Error>) -> Void) -> URLSessionTask? {
        return rpcClient.eth_call(
            to: contract,
            input: Airdrop.vestings(_arg0: id),
            completion: completion)
    }

    func isVestingRedeemed(hash: Sol.Bytes32, contract: Sol.Address, completion: @escaping (Result<Bool, Error>) -> Void) -> URLSessionTask? {
        return vesting(id: hash, contract: contract) { result in
            completion(result.map({ $0.account != 0 }))
        }
    }

    // MARK: - Delegate Registry Contract
    func delegate(of delegator: Sol.Address, completion: @escaping (Result<Sol.Address, Error>) -> Void) -> URLSessionTask? {
        return rpcClient.eth_call(
            to: configuration.delegateRegistry,
            input: DelegateRegistry.delegation(_arg0: delegator, _arg1: configuration.delegateId)
        ) { result in
            completion(result.map({ returns in
                returns._arg0
            }))
        }
    }

    // Important: the code below allows you to claim "0" amount and set delegate
    // However, the requirements for the app state that user must put non-zero amount to the claiming field.
    // This means that claiming or setting delegate not possible if claiming 0 tokens.

    // requires:
        // safe token paused status
        // for each airdrop contract
            // allocation data
            // current vesting data
        // amount to claim
            // number in wei less or equal to the total claimable amount or MAX_VALUE
        // delegate address or nil
            // if nil, setting delegate will be skipped
        // timestamp of the claiming event (to take the vested amount)
    // guarantees: returns the set of transactions for the claiming and setting delegate
        // delegate:
            // nil - no setDelegate
            // not nil - setDelegate transaction present

        // remaining to claim = claimed amount
        // for each airdrop contract allocation:
            // if remainig is 0 then stop
            // available = how many tokens available to claim now from the contract
            // claimed share = remaining = max ? max : min(available, remaining)
            // if claimed share > 0 or is MAX
                // if not redeemed, then redeem
                // add claim share based on the safe token paused state
                    // use `claimVestedTokensViaModule` or `claimVestedTokens`
                // remaining -= claimed share = max ? 0 : claimed share

    // transaction combinator
        // requires: list of transactions
        // guarantees:
            // if single transaction, then will create a call to that transaction itself vai Safe taransaction
            // else will put everythign in multisend and put that into a Safe transaction
        // if resulting set of transactions has more than 1 transaction
            // then wraps this set in a multi-send with a delegate call
        // otherwise uses that 1 transaction
        // then uses resulting transaction as a payload to the Safe contract to create a Safe transaction

}
