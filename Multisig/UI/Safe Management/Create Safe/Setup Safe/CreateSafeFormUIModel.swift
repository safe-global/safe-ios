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
import SafeDeployments
import SafeAbi
import JsonRpc2

protocol CreateSafeFormUIModelDelegate: AnyObject {
    func updateUI(model: CreateSafeFormUIModel)
    func createSafeModelDidFinish()
    func authenticateUser(_ completion: @escaping (Bool) -> Void)
}

class CreateSafeFormUIModel {
    var name: String!
    var chain: Chain!
    var owners: [CreateSafeFormOwner] = []
    var threshold: Int = 0
    var selectedKey: KeyInfo?
    var deployerBalance: Sol.UInt256?
    var minNonce: Sol.UInt64 = 0
    var transaction: EthTransaction!
    var error: Error?
    var userTxParameters: UserDefinedTransactionParameters?
    var sectionHeaders: [CreateSafeFormSectionHeader] = []
    var safeAddress: Address?
    var state: CreateSafeFormUIState = .initial

    private var debounceTimer: Timer?
    private var estimationTask: URLSessionTask?
    private var getBalanceTask: URLSessionTask?
    private var sendingTask: URLSessionTask?
    private var receiptTask: URLSessionTask?
    private var safeInfoTask: URLSessionTask?

    private var estimationController: TransactionEstimationController!
    private var transactionSender: TransactionSender!

    weak var delegate: CreateSafeFormUIModelDelegate?

    func start() {
        update(to: .setup)
    }

    private func update(to newState: CreateSafeFormUIState) {
        assert(Thread.isMainThread)

        state = newState

        switch newState {
        case .initial:
            update(to: .setup)

        case .setup:
            setup()
            update(to: .changed)

        case .changed:
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { [weak self] _ in
                guard let self = self else { return }
                if self.error != nil {
                    self.update(to: .error)
                } else {
                    self.update(to: .estimating)
                }
            })

        case .estimating:
            estimate { [weak self] result in
                guard let self = self else { return }

                let _ = self.handleError({ try result.get() })

                if self.error != nil {
                    self.update(to: .changed)
                } else if self.selectedKey != nil {
                    self.update(to: .ready)
                } else {
                    self.update(to: .searchingKey)
                }
            }

        case .searchingKey:
            findDefaultKey { [weak self] in
                guard let self = self else { return }

                if self.selectedKey == nil {
                    self.update(to: .keyNotFound)
                } else {
                    self.update(to: .changed)
                }
            }

        case .authenticating:
            break

        case .signing:
            sign { [weak self] result in
                guard let self = self else { return }

                let _ = self.handleError({ try result.get() })

                if self.error != nil {
                    self.update(to: .changed)
                } else {
                    self.update(to: .sending)
                }
            }

        case .sending:
            send { [weak self] result in
                guard let self = self else { return }

                let _ = self.handleError({ try result.get() })

                if self.error != nil {
                    self.update(to: .changed)
                } else {
                    self.update(to: .final)
                }
            }

        case .pending:
            // if not mined, schedule timer to pending again
            // if success, go to indexing
            // else go back to ready with error
            break

        case .indexing:
            // if found, go to final
            // if not found, schedule timer to indexing again.
            break

        case .keyNotFound:
            break

        case .ready:
            break

        case .error:
            assert(error != nil)
            break

        case .final:
            // at the final state we want to update ui one more time before finishing
            // while at other states we just want to update ui after they have executed update action.
            delegate?.updateUI(model: self)
            delegate?.createSafeModelDidFinish()
            return
        }

        delegate?.updateUI(model: self)
    }

    // MARK: - UI Events

    var isEditingEnabled: Bool {
        state == .ready || state == .changed || state == .error || state == .keyNotFound
    }

    var isCreateEnabled: Bool {
        state == .ready && owners.count > 0
    }

    var isLoadingDeployer: Bool {
        // estimation will also re-fetch key balance, so it should have loading state
        state == .searchingKey || state == .estimating
    }

    var isLoadingFee: Bool {
        state == .estimating
    }

    func didEdit() {
        guard isEditingEnabled else { return }
        // remove errors after editing
        if state == .error {
            self.error = nil
        }
        update(to: .changed)
    }

    func didCreate() {
        guard isCreateEnabled else { return }
        update(to: .signing)
    }

    // MARK: - Setup
    
    private func setup() {
        // select default chain
        name = "My Safe"
        chain = Chain.mainnetChain()
        owners = []
        threshold = 1
        transaction = handleError(try makeEthTransaction())
        sectionHeaders = makeSectionHeaders()
    }

    func setName(_ name: String) {
        self.name = name
        didEdit()
    }

    func setChainId(_ chainId: String) {
        guard chainId != chain.id, let newChain = Chain.by(chainId) else { return }
        chain = newChain
        // needs updating because the chain prefix will change and potentially address name from address book
        updateOwners()
        didEdit()
    }

    func addOwnerAddress(_ string: String?) {
        guard let string = string, let address = Address(string, checksummed: true) else {
            let error = "Value '\(string ?? "")' seems to have a typo or is not a valid address. Please try again."
            App.shared.snackbar.show(message: error)
            return
        }
        guard !owners.contains(where: { owner in owner.address == address }) else {
            let error = "The owner \(address) is already in the list. Please add a different owner."
            App.shared.snackbar.show(message: error)
            return
        }
        let newOwner = self.owner(from: address)
        owners.append(newOwner)
        // update item count in sections
        sectionHeaders = makeSectionHeaders()
        didEdit()
    }

    func deleteOwnerAt(_ index: Int) {
        guard index < owners.count else { return }
        owners.remove(at: index)
        sectionHeaders = makeSectionHeaders()
        didEdit()
    }

    func owner(from address: Address, defaultName: String? = nil) -> CreateSafeFormOwner {
        let (resolvedName, imageUri) = NamingPolicy.name(
                for: address,
                info: nil,
                chainId: chain.id!)
        let name = resolvedName ?? defaultName
        let url = chain.browserURL(address: address.checksummed)
        let keyInfo = try? KeyInfo.firstKey(address: address)
        let owner = CreateSafeFormOwner(
                prefix: chain.shortName,
                address: address,
                name: name,
                imageUri: imageUri,
                browseUri: url,
                keyInfo: keyInfo,
                privateKey: nil,
                badgeName: keyInfo?.keyType.imageName)
        return owner
    }

    func updateOwners() {
        owners = owners.map(\.address).map { owner(from: $0, defaultName: nil) }
    }

    private func handleError<T>(_ closure: @autoclosure () throws -> T) -> T? {
        do {
            return try closure()
        } catch {
            self.error = error
            return nil
        }
    }

    private func makeEthTransaction() throws -> EthTransaction {
        // get deployments for the chain
        let deploymentVersion = SafeDeployments.Safe.Version.v1_3_0
        let proxyFactoryAddress = try address(of: .ProxyFactory, version: deploymentVersion)
        let fallbackHandlerAddress = try address(of: .CompatibilityFallbackHandler, version: deploymentVersion)
        let safeL1Address = try address(of: .GnosisSafe, version: deploymentVersion)
        let safeL2Address = try address(of: .GnosisSafeL2, version: deploymentVersion)

        // get setupFunction from safe
            // set owners, threshold
            // other params to zero or nil or empty
        let setupFunctionType: GnosisSafeSetup_v1_3_0.Type = chain.l2 ? GnosisSafeL2_v1_3_0.setup.self : GnosisSafe_v1_3_0.setup.self

        let ownerAddresses: [Sol.Address]
        do {
            ownerAddresses = try owners.map { owner -> Sol.Address in
                try Sol.Address(owner.address.data32)
            }
        } catch {
            throw CreateSafeError(errorCode: -5, message: "Failed to create owner addresses", cause: error)
        }

        let setupFunction = setupFunctionType.init(
            _owners: Sol.Array<Sol.Address>(elements: ownerAddresses),
            _threshold: Sol.UInt256(threshold),
            to: 0,
            data: Sol.Bytes(),
            fallbackHandler: fallbackHandlerAddress,
            paymentToken: 0,
            payment: 0,
            paymentReceiver: 0
        )
        let setupAbi = setupFunction.encode()

        // generate salt
        var saltBytes: [UInt8] = .init(repeating: 0, count: 32)
        let randomSaltResult = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)

        guard randomSaltResult == errSecSuccess else {
            throw CreateSafeError(errorCode: -6, message: "Failed to create random salt (sec error \(randomSaltResult))")
        }

        let saltNonce: Sol.UInt256

        do {
            saltNonce = try Sol.UInt256(Data(saltBytes))
        } catch {
            throw CreateSafeError(errorCode: -7, message: "Failed to create random salt from bytes", cause: error)
        }

        // create proxy with nonce
        let createFunction = GnosisSafeProxyFactory_v1_3_0.createProxyWithNonce(
            _singleton: chain.l2 ? safeL2Address : safeL1Address,
            initializer: Sol.Bytes(storage: setupAbi),
            saltNonce: saltNonce
        )

        // encode to abi
        let createAbi = createFunction.encode()

        // create safe creation transaction
            // destination is proxy factory
            // data is the create call abi

        let result: EthTransaction

        let chainId = Sol.UInt256(chain.id!)!

        let isEIP1559 = chain.features?.contains("EIP1559") ?? false
        if isEIP1559 {
            result = Eth.TransactionEip1559(
                chainId: chainId,
                to: proxyFactoryAddress,
                input: Sol.Bytes(storage: createAbi),
                fee: .init(maxPriorityFee: Self.defaultMinerTip)
            )
        } else {
            result = Eth.TransactionLegacy(
                chainId: chainId,
                to: proxyFactoryAddress,
                input: Sol.Bytes(storage: createAbi)
            )
        }

        return result
    }

    private func address(of contract: SafeDeployments.Safe.ContractId, version: SafeDeployments.Safe.Version) throws -> Sol.Address {
        let deployment: SafeDeployments.Safe.Deployment?
        do {
            deployment = try SafeDeployments.Safe.Deployment.find(contract: contract, version: version)
        } catch {
            throw CreateSafeError(errorCode: -1, message: "Safe deployment search failed for: \(contract.rawValue)", cause: error)
        }

        guard let deployment = deployment else {
            throw CreateSafeError(errorCode: -2, message: "Safe deployment not found for: \(contract.rawValue)", cause: error)
        }

        guard let address = deployment.address(for: chain.id!) else {
            throw CreateSafeError(errorCode: -3, message: "Contract address not found: \(contract.rawValue), for chain: \(chain.id!)", cause: error)
        }
        return address
    }

    private func makeSectionHeaders() -> [CreateSafeFormSectionHeader] {
        var result: [CreateSafeFormSectionHeader] = [
            .init(id: .name, title: "Safe Name", itemCount: 1),
            .init(id: .network, title: "Network", tooltip: "Safe will only exist on the selected network.", itemCount: 2),
            // we have 2 additional cells:
            // 'add owner' button cell
            // and help text cell
            .init(id: .owners, title: "Owners", tooltip: "Owner account addresses that can approve transactions made from the new Safe", itemCount: owners.count + 2, actionable: true),
            // we have 1 cell for threshold and 1 cell for help text
            .init(id: .threshold, title: "Required Confirmations", tooltip: "Number of confirmations needed to execute a transaction from the new Safe", itemCount: 2),
            .init(id: .deployment, title: "Payment Details", tooltip: "Account that will deploy the new Safe contract and deployment transaction information", itemCount: 1)
        ]

        if error != nil {
            // add error
            result.append(.init(id: .error, title: "Error", tooltip: nil, itemCount: 1))
        }

        return result
    }

    // MARK: - Estimate

    static let defaultMinerTip: Sol.UInt256 = 1_500_000_000

    func estimate(_ completion: @escaping (Result<Void, Error>) -> Void) {

        precondition(chain != nil, "Chain not set")

        do {
            transaction = try makeEthTransaction()
        } catch {
            completion(.failure(error))
        }

        estimationController = TransactionEstimationController(
            rpcUri: chain.authenticatedRpcUrl.absoluteString,
            chain: chain
        )

        estimationTask?.cancel()
        estimationTask = estimationController.estimateTransactionWithRpc(tx: transaction) { [weak self] result in
            guard let self = self else { return }

            do {
                let estimationResults = try result.get()
                let gas = try self.userTxParameters?.gas ?? estimationResults.gas.get()
                let gasPrice = try self.userTxParameters?.gasPrice ?? self.userTxParameters?.maxFeePerGas ?? estimationResults.gasPrice.get()
                let txCount = try self.userTxParameters?.nonce ?? estimationResults.transactionCount.get()

                // TODO: handle the tx call result which will have the contract address
                self.minNonce = try estimationResults.transactionCount.get()
                self.transaction.update(gas: gas, transactionCount: txCount, baseFee: gasPrice)

                completion(.success(()))
            } catch {
                completion(.failure(CreateSafeError(errorCode: -8, message: "Estimation failed", cause: error)))
            }
        }
    }

    // MARK: - Find Default Key

    // TODO: generalize / refactor with a different key selection policy
    func findDefaultKey(_ completion: @escaping () -> Void) {
        // get all keys
        let keys = executionKeys()

        guard !keys.isEmpty else {
            completion()
            return
        }

        // get all balances
        let balancesFetcher = DefaultAccountBalanceLoader(chain: chain)
        balancesFetcher.requiredBalance = transaction.requiredBalance

        getBalanceTask?.cancel()
        getBalanceTask = balancesFetcher.loadBalances(for: keys, completion: { [weak self] result in
            guard let self = self else { return }

            do {
                let balances = try result.get()

                let balancesSortedDesc = zip(keys, balances)
                    .map { (key: $0, balanceModel: $1) }
                    .filter { $0.balanceModel.amount != nil }
                    .sorted { lhs, rhs in
                        lhs.balanceModel.amount! > rhs.balanceModel.amount!
                    }

                // get the topmost key
                if let highestBalance = balancesSortedDesc.first {
                    self.selectedKey = highestBalance.key
                    self.deployerBalance = highestBalance.balanceModel.amount
                }

                completion()
            } catch {
                LogService.shared.error("Failed to fetch balances: \(error)")
                completion()
            }
        })
    }

    // TODO: generalize / refactor
    // returns the execution keys valid for executing this transaction
    func executionKeys() -> [KeyInfo] {
        // all keys that can sign this tx on its chain.
            // currently, only wallet connect keys are chain-specific, so we filter those out.
        guard let allKeys = try? KeyInfo.all(), !allKeys.isEmpty else {
            return []
        }

        let validKeys = allKeys.filter { keyInfo in
            // if it's a wallet connect key which chain doesn't match then do not use it
            if keyInfo.keyType == .walletConnect,
               let data = keyInfo.metadata,
               let connection = KeyInfo.WalletConnectKeyMetadata.from(data: data),
               // when chainId is 0 then it is 'any' chain
               connection.walletInfo.chainId != 0 &&
                String(describing: connection.walletInfo.chainId) != chain.id {
                return false
            }
            // else use the key
            return true
        }
        .filter {
            // filter out the ledger keys until they are supported
            return $0.keyType != .ledgerNanoX
        }

        return validKeys
    }

    // MARK: - Authenticating

    func authenticate(_ completion: @escaping (Bool) -> Void) {
        let AUTHENTICATED = true
        guard App.shared.auth.isPasscodeSetAndAvailable && AppSettings.passcodeOptions.contains(.useForConfirmation) else {
            completion(AUTHENTICATED)
            return
        }

        delegate?.authenticateUser(completion)
    }

    // MARK: - Signing

    func sign(_ completion: @escaping (Result<Void, Error>) -> Void) {
        // ask delegate to sign
        // response can be either signature or transaction hash directly. We actually want it to be signature only.
        // then update the signature in transsaction.
        // success.
    }

    // MARK: - Sending
    func send(_ completion: @escaping (Result<Void, Error>) -> Void) {
        transactionSender = TransactionSender(chain: chain)
        sendingTask?.cancel()
        sendingTask = transactionSender.send(tx: transaction, completion: { [weak self] result in
            guard let self = self else { return }
            do {
                self.transaction.hash = try result.get()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        })
    }

    // MARK: - Pending
    private var rpcClient: JsonRpc2.Client!
    // get response
        // can be null - json rpc bug right now...
            // then schedule one-time timer
// encapsulate algorithm to get waiting time.
// if has receipt and failure, go back to ready with error.
// if success, get the safe address, go to indexing

    func fetchReceipt(_ completion: @escaping (Bool?) -> Void) {
        let FAILED = false
        let SUCCESS = true
        let NOT_MINED: Bool? = nil

        rpcClient = JsonRpc2.Client(
            transport: JsonRpc2.ClientHTTPTransport(url: chain.authenticatedRpcUrl.absoluteString),
            serializer: JsonRpc2.DefaultSerializer()
        )
        let hash = EthRpc1.Data(transaction.hash!)
        let method = EthRpc1.eth_getTransactionReceipt(transactionHash: hash)
        let request: JsonRpc2.Request
        do {
            request = try method.request(id: .int(0))
        } catch {
            completion(FAILED)
            return
        }
        // send request
        receiptTask?.cancel()
        receiptTask = rpcClient.send(request: request, completion: { response in
            guard
                let result = response?.result,
                let receipt = (try? method.result(from: result)),
                let status = receipt.status
            else {
                completion(NOT_MINED)
                return
            }
            if status == "0x1" {
                completion(SUCCESS)
            } else {
                completion(FAILED)
            }
        })
    }

    // MARK: - Indexing

    // check for safe info by address
    // if not found or any error, schedule timer to retry
    // if found, then add safe
    // use some generated name for that safe.
    // then go to final state.
    func fetchSafeInfo(_ completion: @escaping (Bool) -> Void) {
        let FOUND: Bool = true
        let NOT_FOUND: Bool = false
        App.shared.clientGatewayService.asyncSafeInfo(safeAddress: safeAddress!, chainId: chain.id!) { result in
            //
            do {
                let _ = try result.get()
                completion(FOUND)
            } catch {
                completion(NOT_FOUND)
            }
        }
    }

    // MARK: - UI Data

    var minThreshold: Int {
        owners.isEmpty ? 0 : 1
    }

    var maxThreshold: Int {
        owners.isEmpty ? 0 : owners.count
    }

    var thresholdText: String {
        if owners.isEmpty {
            return "0 out of 0"
        } else {
            return "\(threshold) out of \(owners.count)"
        }
    }

    var deployerAccountInfoModel: MiniAccountInfoUIModel? {
        guard let key = selectedKey else { return nil }
        let (resolvedName, imageUri) = NamingPolicy.name(
            for: key.address,
            info: nil,
            chainId: chain.id!)
        var formattedBalance: String? = nil

        if let balance = deployerBalance {
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
    var badgeName: String?
}

struct CreateSafeFormSectionHeader {
    var id: CreateSafeFormSectionId
    var title: String
    var tooltip: String?
    var itemCount: Int
    var actionable: Bool = false
}

enum CreateSafeFormSectionId {
    case name
    case network
    case owners
    case threshold
    case deployment
    case error
}

enum CreateSafeFormUIState {
    case initial
    case setup
    case changed
    case estimating
    case ready
    case searchingKey
    case keyNotFound
    case authenticating
    case signing
    case sending
    case pending
    case indexing
    case error
    case final
}

struct CreateSafeError: CustomNSError {
    static var errorDomain: String { "io.gnosis.safe.createSafeModel" }
    var errorCode: Int
    var message: String
    var cause: Error? = nil

    var errorUserInfo: [String : Any] {
        var result: [String: Any] = [NSLocalizedDescriptionKey: message]
        if let cause = cause {
            result[NSUnderlyingErrorKey]  = cause
        }
        return result
    }
}
