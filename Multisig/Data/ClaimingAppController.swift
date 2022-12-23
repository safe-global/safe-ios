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

        static let goerli = Configuration(
            safeToken: "0x61fD3b6d656F39395e32f46E2050953376c3f5Ff",
            userAirdrop: "0x07dA2049Fa8127eF6280631BCbc56881d764C8Ee",
            ecosystemAirdrop: "0xEc6449091Ae23A92f856702F9452011E31E66C63",
            // https://github.com/gnosis/delegate-registry/blob/main/networks.json
            delegateRegistry: "0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446",
            chainId: "5"
        )

        static let mainnet = Configuration(
            safeToken: "0x5aFE3855358E112B5647B952709E6165e1c1eEEe",
            userAirdrop: "0xA0b937D5c8E32a80E3a8ed4227CD020221544ee6",
            ecosystemAirdrop: "0x29067F28306419923BCfF96E37F95E0f58ABdBBe",
            // https://github.com/gnosis/delegate-registry/blob/feature/fix_deployment/networks.json
            delegateRegistry: "0x469788fE6E9E9681C6ebF3bF78e7Fd26Fc015446",
            chainId: "1"
        )
    }

    var configuration: Configuration
    var rpcClient: RpcClient
    var claimingService: SafeClaimingService

    var chain: Chain {
        rpcClient.chain
    }

    init?(chain: Chain) {
        if chain.id == Chain.ChainID.ethereumMainnet {
            self.configuration = .mainnet
        } else if chain.id == Chain.ChainID.goerli {
            self.configuration = .goerli
        } else {
            return nil
        }
        self.rpcClient = RpcClient(chain: chain)
        claimingService = App.shared.claimingService
    }

    static func isAvailable(chain: Chain) -> Bool {
        let isChainSupported = chain.id == Chain.ChainID.goerli || chain.id == Chain.ChainID.ethereumMainnet
        let isEnabledInConfig = NSString(string: FirebaseRemoteConfig.shared.value(key: .safeClaimEnabled) ?? "false").boolValue
        return isChainSupported && isEnabledInConfig
    }

    // MARK: - Static data

    func guardians(completion: @escaping (Result<[Guardian], Error>) -> Void) -> URLSessionTask? {
        claimingService.asyncGuardians(completion: completion)
    }

    func guardians(for address: Address, completion: @escaping (Result<(guardians: [Guardian], delegate: Address?), Error>) -> Void) {
        DispatchQueue.global().async { [unowned self] in

            var errors: [Error] = []
            var resultGuardians: [Guardian]!
            var resultDelegate: Address?

            let group = DispatchGroup()

            group.enter()
            _ = guardians { result in
                do {
                    resultGuardians = try result.get()
                } catch {
                    errors.append(error)
                }
                group.leave()
            }

            group.enter()
            _ = try! delegate(of: Sol.Address(address.data32)) { result in
                do {
                    let resultingAddress = try result.get()
                    resultDelegate = resultingAddress == 0 ? nil : Address(resultingAddress)
                } catch {
                    errors.append(error)
                }
                group.leave()
            }

            let waitResult = group.wait(timeout: .now() + .seconds(60))

            if waitResult == .timedOut {
                dispatchOnMainThread(completion(.failure(GSError.TimeOut())))
                return
            }

            if let error = errors.first {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            dispatchOnMainThread(completion(.success((resultGuardians, resultDelegate))))
        }
    }

    func allocations(address: Address, completion: @escaping (Result<[Allocation], Error>) -> Void) -> URLSessionTask? {
        claimingService.asyncAllocations(account: address, chainId: chain.id!, completion: completion)
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

    func vesting(id: Sol.Bytes32, contract: Sol.Address, completion: @escaping (Result<Vesting, Error>) -> Void) -> URLSessionTask? {
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

    struct ClaimingData {
        var account: Address = .zero
        var allocations: [Allocation] = []
        // vestings by id = `allocation.contract.checksummed`_`allocation.vestingId`
        var vestings: [String: Vesting] = [:]
        var tokenPaused: Bool = true
        var delegate: Sol.Address? = nil
        var guardians: [Guardian] = []

        var isEligible: Bool {
            !allocations.isEmpty
        }

        var isRedeemed: Bool {
            vestings.allSatisfy { _, value in
                value.isRedeemed
            }
        }

        var delegateAddress: Address? {
            delegate.map(Address.init)
        }

        func guardian(for address: Address?) -> Guardian? {
            guard let address = address else {
                return nil
            }
            return guardians.first { g in
                g.address.address == address
            }
        }

        var allocationsData: [(allocation: Allocation, vesting: Vesting)] {
            var result: [(allocation: Allocation, vesting: Vesting)] = []

            for allocation in allocations {
                let vestingDictId = allocation.contract.address.checksummed + "_" + allocation.vestingId.description
                if let vesting = vestings[vestingDictId] {
                    result.append((allocation, vesting))
                }
            }

            return result
        }

        func findError() -> String? {
            let OK: String? = nil

            if account.isZero {
                return "Incorrect data configuration"
            }

            if allocations.isEmpty {
                return "No allocations found in the data"
            }

            if allocations.count != vestings.count {
                return "Vestings do not match allocations"
            }

            if allocationsData.count != allocations.count {
                return "Allocation data is missing some allocations"
            }

            return OK
        }

        func totalAllocatedAmount(of allocationData: [(allocation: Allocation, vesting: Vesting)], at timestamp: TimeInterval) -> Sol.UInt128 {
            let sum = allocationData.map {
                vesting(from: $0).amount
            }.reduce(0, +)
            return sum
        }

        func totalAvailableAmount(of allocationData: [(allocation: Allocation, vesting: Vesting)], at timestamp: TimeInterval) -> Sol.UInt128 {
            let sum = allocationData.map {
                availableAmount(for: $0, at: timestamp) ?? 0
            }.reduce(0, +)
            return sum
        }

        func vesting(from allocationData: (allocation: Allocation, vesting: Vesting)) -> Vesting {
            let result = allocationData.vesting.account == 0 ? Vesting(allocationData.allocation) : allocationData.vesting
            return result
        }

        func availableAmount(for allocationData: (allocation: Allocation, vesting: Vesting)?, at timestamp: TimeInterval) -> Sol.UInt128? {
            guard let allocationData = allocationData else {
                return nil
            }

            let vesting = vesting(from: allocationData)
            let result = vesting.available(at: timestamp)
            return result
        }

        func totalUnvestedAmount(of allocationData: [(allocation: Allocation, vesting: Vesting)], at timestamp: TimeInterval) -> Sol.UInt128 {
            let sum = allocationData.map {
                unvestedAmount(for: $0, at: timestamp) ?? 0
            }.reduce(0, +)
            return sum
        }

        func unvestedAmount(for allocationData: (allocation: Allocation, vesting: Vesting)?, at timestamp: TimeInterval) -> Sol.UInt128? {
            guard let allocationData = allocationData else {
                return nil
            }

            let vesting = vesting(from: allocationData)
            let result = vesting.amount - vesting.available(at: timestamp) - vesting.amountClaimed
            return result
        }
    }

    func asyncFetchData(account: Address, timeout: TimeInterval = 60, completion: @escaping (Result<ClaimingData, Error>) -> Void) {
        DispatchQueue.global().async { [unowned self] in
            fetchData(account: account, timeout: timeout, completion: completion)
        }
    }

    func fetchData(account: Address, timeout: TimeInterval = 60, completion: @escaping (Result<ClaimingData, Error>) -> Void) {
        //          | -> allocations -> [vestings] -> |
        // account  | -> is paused                 -> | -> all data loaded
        //          | -> delegate                  -> |
        //            -> guardians                 ->
        // any error -> everything fails
        var data = ClaimingData(account: account)
        var errors: [Error] = []


        let group = DispatchGroup()

        // get allocations
        group.enter()
        _ = allocations(address: account) { [weak self] result in
            guard let self = self else { return }
            do {
                data.allocations = try result.get()

                // get contract vesting data for each allocation
                for allocation in data.allocations {

                    // async get current vesting for the allocation
                    let vestingDictId = allocation.contract.address.checksummed + "_" + allocation.vestingId.description

                    group.enter()
                    _ = self.vesting(
                        id: Sol.Bytes32(storage: allocation.vestingId.data),
                        contract: try! Sol.Address(data: allocation.contract.data32)
                    ) { vestingResult in
                        do {
                            data.vestings[vestingDictId] = try vestingResult.get()
                        } catch {
                            errors.append(error)
                        }
                        group.leave()
                    }
                }
            } catch {
                errors.append(error)
            }
            group.leave()
        }

        // get is paused
        group.enter()
        _ = isSafeTokenPaused(completion: { result in
            do {
                data.tokenPaused = try result.get()
            } catch {
                errors.append(error)
            }
            group.leave()
        })

        // get delegate
        group.enter()
        _ = delegate(of: try! Sol.Address(data: account.data32), completion: { result in
            do {
                let delegate = try result.get()
                data.delegate = delegate == 0 ? nil : delegate
            } catch {
                errors.append(error)
            }
            group.leave()
        })

        // get guardians
        group.enter()
        _ = guardians { result in
            do {
                data.guardians = try result.get()
            } catch {
                errors.append(error)
            }
            group.leave()
        }

        // wait for all requests to complete
        let waitResult = group.wait(timeout: .now() + .seconds(Int(timeout)))

        guard case DispatchTimeoutResult.success = waitResult else {
            dispatchOnMainThread(completion(.failure(GSError.TimeOut())))
            return
        }

        if let error = errors.first {
            dispatchOnMainThread(completion(.failure(error)))
            return
        }

        // otherwise, complete with success
        dispatchOnMainThread(completion(.success(data)))
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

    func claimingTransaction(
        safe: Safe,
        amount: Sol.UInt128,
        delegate: Address?,
        data: ClaimingData,
        timestamp: TimeInterval = Date().timeIntervalSince1970
    ) -> Transaction? {
        let transactions = claimingTransactions(
            amount: amount,
            beneficiary: safe.addressValue,
            delegate: delegate,
            timestamp: timestamp,
            allocations: data.allocationsData,
            safeTokenPaused: data.tokenPaused
        )
        let result = combine(transactions: transactions, safe: safe)
        return result
    }

    // requires:
        // safe token paused status
        // for each airdrop contract
            // allocation data
                // account
                // vestingId
                // contract
                // chainId
                // durationWeeks
                // amount
                // curve
            // current vesting data
                // account
                // curveType
                // managed
                // durationWeeks
                // startDate
                // amount
                // amountClaimed
                // pausingDate
                // cancelled
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
            let setDelegateCall = setDelegateCallData(delegate)
            result.append(safeTransaction(to: configuration.delegateRegistry, abi: setDelegateCall))
        }

        let CLAIM_MAX_VALUE = Sol.UInt128.max

        var remainingAmount = amount

        for (allocation, currentVesting) in allocations {
            if remainingAmount == 0 { break }

            // account == 0 when the vesting is not redeemed yet, so we'll create it from allocation data
            // so that we can calculate available token amount.
            let vesting = currentVesting.account == 0 ? Vesting(allocation) : currentVesting

            let availableAmount = vesting.available(at: timestamp)

            let claimedAmount = remainingAmount == CLAIM_MAX_VALUE ? CLAIM_MAX_VALUE : min(availableAmount, remainingAmount)

            if claimedAmount > 0 || claimedAmount == CLAIM_MAX_VALUE {

                if !currentVesting.isRedeemed {
                    let redeemCall = redeemCallData(allocation)
                    result.append(safeTransaction(to: allocation.contract, abi: redeemCall))
                }

                let claimCall = claimCallData(safeTokenPaused, allocation, beneficiary, claimedAmount)
                result.append(safeTransaction(to: allocation.contract, abi: claimCall))

                if claimedAmount != CLAIM_MAX_VALUE {
                    remainingAmount -= claimedAmount
                }
            }
        }
        return result
    }

    fileprivate func setDelegateCallData(_ delegate: Address) -> Data {
        return DelegateRegistry.setDelegate(
            id: configuration.delegateId,
            delegate: try! Sol.Address(delegate.data32)
        ).encode()
    }

    fileprivate func redeemCallData(_ allocation: Allocation) -> Data {
        return Airdrop.redeem(
            curveType: Sol.UInt8(allocation.curve),
            durationWeeks: Sol.UInt16(allocation.durationWeeks),
            startDate: Sol.UInt64(allocation.startDate),
            amount: Sol.UInt128(allocation.amount.value),
            proof: Sol.Array<Sol.Bytes32>(elements: allocation.proof?.map { data in
                Sol.Bytes32(storage: data.data)
            } ?? [])
        ).encode()
    }

    fileprivate func claimCallData(_ safeTokenPaused: Bool, _ allocation: Allocation, _ beneficiary: Address, _ claimedShare: Sol.UInt128) -> Data {
        // add claim share based on the safe token paused state
        // use `claimVestedTokensViaModule` or `claimVestedTokens`
        let claimCall: Data
        if safeTokenPaused {
            claimCall = Airdrop.claimVestedTokensViaModule(
                vestingId: Sol.Bytes32(storage: allocation.vestingId.data),
                beneficiary: try! Sol.Address(beneficiary.data32),
                tokensToClaim: claimedShare
            ).encode()
        } else {
            claimCall = Airdrop.claimVestedTokens(
                vestingId: Sol.Bytes32(storage: allocation.vestingId.data),
                beneficiary: try! Sol.Address(beneficiary.data32),
                tokensToClaim: claimedShare
            ).encode()
        }
        return claimCall
    }

    // transaction combinator
    // requires: list of transactions
    // guarantees:
        // if single transaction, then will create a call to that transaction itself vai Safe taransaction
        // else will put everything in multisend and put that into a Safe transaction
    func combine(transactions: [Transaction], safe: Safe) -> Transaction? {
        if transactions.isEmpty { return nil }
        if transactions.count == 1 {
            let result = Transaction(
                safeAddress: safe.addressValue,
                chainId: safe.chain!.id!,
                toAddress: transactions[0].to.address,
                contractVersion: safe.contractVersion!,
                amount: nil,
                data: transactions[0].data?.data ?? Data(),
                safeTxGas: nil,
                nonce: "0",
                operation: .call
            )
            return result
        }

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

        // MultisendCallOnly is preferred to use for all contract versions
        let data = MultiSendCallOnly_v1_3_0.multiSend(transactions: packedTransactions).encode()
        let to = try! Address(SafeDeployments.Safe.Deployment.find(contract: .MultiSendCallOnly, version: .v1_3_0)!.address(for: configuration.chainId)!)

        let result = Transaction(
            safeAddress: safe.addressValue,
            chainId: safe.chain!.id!,
            toAddress: to,
            contractVersion: safe.contractVersion!,
            amount: nil,
            data: data,
            safeTxGas: nil,
            nonce: "0",
            operation: .delegate)
        return result
    }
}

extension ClaimingAppController.Vesting {

    init(_ allocation: Allocation) {
        self.init(
            account: try! Sol.Address(allocation.account.address.data32),
            curveType: Sol.UInt8(clamping: allocation.curve),
            managed: false,
            durationWeeks: Sol.UInt16(clamping: allocation.durationWeeks),
            startDate: Sol.UInt64(clamping: allocation.startDate),
            amount: Sol.UInt128(clamping: allocation.amount.value),
            amountClaimed: 0,
            pausingDate: 0,
            cancelled: false
        )
    }

    var isRedeemed: Bool {
        account != 0
    }

    func available(at timestamp: TimeInterval) -> Sol.UInt128 {
        // The used timestamp (CurrentTimestamp - 30) it caused sometimes that vestedAmount is less than claimed
        let vestedAmount = vestedAmount(at: timestamp)
        if vestedAmount > amountClaimed {
            return vestedAmount - amountClaimed
        }

        return 0
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
