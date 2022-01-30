//
//  CreateSafeFormUIModel.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 29.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import Solidity
import Ethereum
import SwiftCryptoTokenFormatter

protocol CreateSafeFormUIModelDelegate: AnyObject {
    func updateUI(model: CreateSafeFormUIModel)
}

class CreateSafeFormUIModel {
    var chain: Chain!
    var owners: [CreateSafeFormOwner] = []
    var threshold: Int = 0
    var selectedKey: KeyInfo?
    var deployerAccount: EthAccount?
    var transaction: EthTransaction!
    var error: Error?
    var isCreateEnabled: Bool = false
    var isChanged: Bool = false
    var userTxParameters: UserDefinedTransactionParameters?
    var sectionHeaders: [CreateSafeFormSectionHeader] = []
    var state: CreateSafeFormUIState = .setup

    weak var delegate: CreateSafeFormUIModelDelegate?

    func start() {
        update(to: .setup)
    }

    private func update(to newState: CreateSafeFormUIState) {
        switch newState {
        case .setup:
            state = newState
            setup()
        case .estimating:
            break
        case .searchingKey:
            break
        case .keyFound:
            break
        case .keyNotFound:
            break
        case .ready:
            break
        case .changed:
            break
        case .signing:
            break
        case .signed:
            break
        case .sending:
            break
        case .sent:
            break
        case .error:
            break
        }
    }

    // MARK: - Setup
    
    private func setup() {
        // select default chain
        chain = Chain.mainnetChain()
        owners = makeDefaultOwners()
        threshold = 1
        transaction = makeEthTransaction()
        sectionHeaders = makeSectionHeaders()
        delegate?.updateUI(model: self)
        update(to: .estimating)
    }

    private func makeDefaultOwners() -> [CreateSafeFormOwner] {
        let result = (0..<3).map { index -> CreateSafeFormOwner in
            let key = generatePrivateKey()
            let defaultName = "Generated Owner #\(index + 1)"
            let (resolvedName, imageUri) = NamingPolicy.name(
                for: key.address,
                info: nil,
                chainId: chain.id!)
            let name = resolvedName ?? defaultName
            let url = chain.browserURL(address: key.address.checksummed)
            let owner = CreateSafeFormOwner(
                prefix: chain.shortName,
                address: key.address,
                name: name,
                imageUri: imageUri,
                browseUri: url,
                keyInfo: nil,
                privateKey: key)
            return owner
        }
        return result
    }

    private func generatePrivateKey() -> PrivateKey {
        let seed = Data.randomBytes(length: 16)!
        let mnemonic = BIP39.generateMnemonicsFromEntropy(entropy: seed)!
        let privateKey: PrivateKey = try! PrivateKey(mnemonic: mnemonic, pathIndex: 0)
        return privateKey
    }

    private func makeEthTransaction() -> EthTransaction {
        // get deployment for the chain

        // get fallback handler address

        // SafeL2 or Safe?
        // get setupFunction from safe
            // set owners, threshold
            // other params to zero or nil or empty

        // generate salt

        // get proxy factory
        // create proxy with nonce
            // safe impl address
            // setup abi encoded
            // salt

        // encode to abi

        // destination is to proxy factory address

        // support eip1559 or not - create the appropriate tx

        // return result
        return Eth.TransactionEip1559()
    }

    private func makeSectionHeaders() -> [CreateSafeFormSectionHeader] {
        var result: [CreateSafeFormSectionHeader] = [
            .init(id: .network, title: "Network", tooltip: "Blockchain network where the new safe will be deployed", itemCount: 1),
            .init(id: .owners, title: "Owners", tooltip: "Owner account addresses that can approve transactions made from the new Safe", itemCount: owners.count, actionable: true),
            .init(id: .threshold, title: "Threshold", tooltip: "Number of confirmations needed to execute a transaction from the new Safe", itemCount: 1),
            .init(id: .deployment, title: "Deployment Transaction", tooltip: "Account that will deploy the new Safe contract and deployment transaction information", itemCount: 2)
        ]

        if error != nil {
            // add error
            result.append(.init(id: .error, title: "Error", tooltip: nil, itemCount: 1))
        }

        return result
    }

    // MARK: - UI Data

    var minThreshold: Int {
        owners.isEmpty ? 0 : 1
    }

    var maxThreshold: Int {
        owners.isEmpty ? 0 : owners.count
    }

    var thresholdText: String {
        "\(threshold) out of \(owners.count)"
    }

    var isLoadingDeployer: Bool {
        // estimation will also re-fetch key balance.
        state == .searchingKey || state == .estimating
    }

    var deployerAccountInfoModel: MiniAccountInfoUIModel? {
        guard let key = selectedKey else { return nil }
        let (resolvedName, imageUri) = NamingPolicy.name(
            for: key.address,
            info: nil,
            chainId: chain.id!)
        var formattedBalance: String? = nil

        if let balance = deployerAccount?.balance {
            let nativeCoinDecimals = chain.nativeCurrency!.decimals
            let nativeCoinSymbol = chain.nativeCurrency!.symbol!

            let decimalAmount = BigDecimal(Int256(balance.big()), Int(nativeCoinDecimals))
            let value = TokenFormatter().string(
                from: decimalAmount,
                decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
                thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
                forcePlusSign: false
            )

            formattedBalance = "\(value) \(nativeCoinSymbol)"
        }

        let result = MiniAccountInfoUIModel(
            prefix: chain.shortName,
            address: key.address,
            label: resolvedName,
            imageUri: imageUri,
            badge: key.keyType.imageName,
            balance: formattedBalance
        )
        return result
    }

    var isLoadingFee: Bool {
        state == .estimating
    }

    var estimatedFeeModel: EstimatedFeeUIModel? {
        guard let tx = transaction else { return nil }

        let feeInWei = tx.totalFee

        let nativeCoinDecimals = chain.nativeCurrency!.decimals
        let nativeCoinSymbol = chain.nativeCurrency!.symbol!

        let decimalAmount = BigDecimal(Int256(feeInWei.big()), Int(nativeCoinDecimals))
        let value = TokenFormatter().string(
            from: decimalAmount,
            decimalSeparator: Locale.autoupdatingCurrent.decimalSeparator ?? ".",
            thousandSeparator: Locale.autoupdatingCurrent.groupingSeparator ?? ",",
            forcePlusSign: false
        )

        let tokenAmount: String = "\(value) \(nativeCoinSymbol)"

        let model = EstimatedFeeUIModel(
            tokenAmount: tokenAmount,
            fiatAmount: nil)

        return model
    }
}

struct CreateSafeFormOwner {
    var prefix: String?
    var address: Address
    var name: String?
    var imageUri: URL?
    var browseUri: URL?
    var keyInfo: KeyInfo?
    var privateKey: PrivateKey?
}

struct CreateSafeFormSectionHeader {
    var id: CreateSafeFormSectionId
    var title: String
    var tooltip: String?
    var itemCount: Int
    var actionable: Bool = false
}

enum CreateSafeFormSectionId {
    case network
    case owners
    case threshold
    case deployment
    case error
}

struct EthAccount {
    var address: Sol.Address
    var transactionCount: Sol.UInt64
    var balance: Sol.UInt256
}

enum CreateSafeFormUIState {
    case setup
    case estimating
    case searchingKey
    case keyFound
    case keyNotFound
    case ready
    case changed
    case signing
    case signed
    case sending
    case sent
    case error
}
