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
import Version

import SafeDeployments

class ClaimingAppController {

    struct Configuration {
        var safeToken: Sol.Address
        var userAirdrop: Sol.Address
        var ecosystemAirdrop: Sol.Address
        var delegateRegistry: Sol.Address
        var delegateId: Sol.Bytes32 = Sol.Bytes32(storage: "safe.eth".data(using: .utf8)!.rightPadded(to: 32))
        var chainId: String

        static let rinkeby = Configuration(
            safeToken: "0xCFf1b0FdE85C102552D1D96084AF148f478F964A",
            userAirdrop: "0x6C6ea0B60873255bb670F838b03db9d9a8f045c4",
            ecosystemAirdrop: "0x82F1267759e9Bea202a46f8FC04704b6A5E2Af77",
            // https://github.com/gnosis/delegate-registry/blob/main/networks.json
            delegateRegistry: "0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446",
            chainId: "4"
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
            completion(result.map({ $0.isRedeemed }))
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

    typealias Vesting = Airdrop.vestings.Returns

    func safeTransaction(to: Sol.Address, abi: Data, operation: SCGModels.Operation = .call) -> Transaction {
        safeTransaction(to: AddressString(to), abi: abi, operation: operation)
    }

    func safeTransaction(to: AddressString, abi: Data, operation: SCGModels.Operation = .call) -> Transaction {
        Transaction(
            to: to,
            value: "0",
            data: DataString(abi),
            operation: operation,
            safeTxGas: "0",
            baseGas: "0",
            gasPrice: "0",
            gasToken: .zero,
            refundReceiver: .zero,
            nonce: "0"
        )
    }

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
    func claimingTransactions(
        amount: Sol.UInt128,
        beneficiary: Address,
        delegate: Address?,
        timestamp: TimeInterval,
        allocations: [(allocation: Allocation, vesting: Vesting)],
        safeTokenPaused: Bool
    ) -> [Transaction] {
        var result = [Transaction]()
        if let delegate = delegate {
            let setDelegateCall = DelegateRegistry.setDelegate(
                id: configuration.delegateId,
                delegate: try! Sol.Address(delegate.data32)
            ).encode()
            result.append(safeTransaction(to: configuration.delegateRegistry, abi: setDelegateCall))
        }

        let CLAIM_MAX_VALUE = Sol.UInt128.max

        var remainingToClaim = amount

        for airdrop in allocations {
            if remainingToClaim == 0 { break }

            // available - how many tokens available to claim now from the contract
            let available = airdrop.vesting.vestedAmount(at: timestamp)

            let claimedShare = remainingToClaim == CLAIM_MAX_VALUE ? CLAIM_MAX_VALUE : min(available, remainingToClaim)

            // if claimed share > 0 or is MAX
            if claimedShare > 0 || claimedShare == CLAIM_MAX_VALUE {

                if !airdrop.vesting.isRedeemed {
                    let redeemCall = Airdrop.redeem(
                        curveType: Sol.UInt8(airdrop.allocation.curve),
                        durationWeeks: Sol.UInt16(airdrop.allocation.durationWeeks),
                        startDate: Sol.UInt64(airdrop.allocation.startDate),
                        amount: Sol.UInt128(airdrop.allocation.amount.value),
                        // TODO: Add proof
                        proof: Sol.Array<Sol.Bytes32>()
                    ).encode()

                    result.append(safeTransaction(to: airdrop.allocation.contract, abi: redeemCall))
                }

                // add claim share based on the safe token paused state
                // use `claimVestedTokensViaModule` or `claimVestedTokens`
                let claimCall: Data
                if safeTokenPaused {
                    claimCall = Airdrop.claimVestedTokensViaModule(
                        vestingId: Sol.Bytes32(storage: airdrop.allocation.vestingId.data),
                        beneficiary: try! Sol.Address(beneficiary.data32),
                        tokensToClaim: claimedShare
                    ).encode()
                } else {
                    claimCall = Airdrop.claimVestedTokens(
                        vestingId: Sol.Bytes32(storage: airdrop.allocation.vestingId.data),
                        beneficiary: try! Sol.Address(beneficiary.data32),
                        tokensToClaim: claimedShare
                    ).encode()
                }
                result.append(safeTransaction(to: airdrop.allocation.contract, abi: claimCall))

                // reduce remaining amount by the share of the claimed for this airdrop contract
                if claimedShare != CLAIM_MAX_VALUE {
                    remainingToClaim -= claimedShare
                }
            }
        }
        return result
    }

    // transaction combinator
    // requires: list of transactions
    // guarantees:
        // if single transaction, then will create a call to that transaction itself vai Safe taransaction
        // else will put everything in multisend and put that into a Safe transaction
    func combine(transactions: [Transaction], safe: Safe) -> Transaction? {
        guard transactions.count > 1 else { return transactions.first }

        // From MultiSend contract documentation:
        /// @param transactions Encoded transactions. Each transaction is encoded as a packed bytes of
        ///                     operation as a uint8 with 0 for a call or 1 for a delegatecall (=> 1 byte),
        ///                     to as a address (=> 20 bytes),
        ///                     value as a uint256 (=> 32 bytes),
        ///                     data length as a uint256 (=> 32 bytes),
        ///                     data as bytes.
        ///                     see abi.encodePacked for more information on packed encoding


        let packedTransactions = Sol.Bytes(storage: transactions.flatMap { tx -> [Data] in
            [Sol.UInt8(tx.operation.rawValue) as SolAbiEncodable,
             try! Sol.Address(tx.to.address.data32),
             Sol.UInt256(tx.value.value),
             Sol.UInt256((tx.data?.data ?? Data()).count),
             Sol.Bytes(storage: tx.data?.data ?? Data())
            ].map { $0.encodePacked() }
        }.reduce(Data(), +))

        let isSafe1_3_0 = safe.contractVersion != nil && Version(safe.contractVersion!)! >= Version(1, 3, 0)

        if safe.contractVersion == nil || isSafe1_3_0 {
            let multiSendCall = MultiSend_v1_3_0.multiSend(transactions: packedTransactions).encode()
            let multiSendAddress = try! SafeDeployments.Safe.Deployment.find(contract: .MultiSend, version: .v1_3_0)!.address(for: configuration.chainId)!
            return safeTransaction(to: multiSendAddress, abi: multiSendCall, operation: .delegate)
        } else {
            let multiSendCall = MultiSend_v1_1_1.multiSend(transactions: packedTransactions).encode()
            let multiSendAddress = try! SafeDeployments.Safe.Deployment.find(contract: .MultiSend, version: .v1_1_1)!.address(for: configuration.chainId)!
            return safeTransaction(to: multiSendAddress, abi: multiSendCall, operation: .delegate)
        }
    }
}

extension ClaimingAppController.Vesting {
    var isRedeemed: Bool {
        account != 0
    }

    func vestedAmount(at timestamp: TimeInterval) -> Sol.UInt128 {
        // Convert vesting duration to seconds
        let durationSeconds = Sol.UInt64(durationWeeks) * 7 * 24 * 60 * 60

        // If contract is paused use the pausing date to calculate amount
        let vestedSeconds = pausingDate > 0
            ? pausingDate - startDate
            : Sol.UInt64(timestamp) - startDate

        let result: Sol.UInt128

        if (vestedSeconds >= durationSeconds) {
            // If vesting time is longer than duration everything has been vested
            result = amount
        } else if curveType == 0 {
            // Linear vesting
            result = calculateLinear(amount, vestedSeconds, durationSeconds);
        } else if curveType == 1 {
            // Exponential vesting
            result = calculateExponential(amount, vestedSeconds, durationSeconds);
        } else {
            // This is unreachable because it is not possible to add a vesting with an invalid curve type
            result = 0
        }
        return result
    }

    func calculateLinear(
        _ targetAmount: Sol.UInt128,
        _ elapsedTime: Sol.UInt64,
        _ totalTime: Sol.UInt64
    ) -> Sol.UInt128 {
        // Calculate vested amount on linear curve: targetAmount * elapsedTime / totalTime
        let amount = (Sol.UInt256(targetAmount) * Sol.UInt256(elapsedTime)) / Sol.UInt256(totalTime);
        return Sol.UInt128(amount)
    }

    func calculateExponential(
        _ targetAmount: Sol.UInt128,
        _ elapsedTime: Sol.UInt64,
        _ totalTime: Sol.UInt64
    ) -> Sol.UInt128 {
        // Calculate vested amount on exponential curve: targetAmount * elapsedTime^2 / totalTime^2
        let amount = (Sol.UInt256(targetAmount) * Sol.UInt256(elapsedTime) * Sol.UInt256(elapsedTime)) / (Sol.UInt256(totalTime) * Sol.UInt256(totalTime));
        return Sol.UInt128(amount);
    }

}
