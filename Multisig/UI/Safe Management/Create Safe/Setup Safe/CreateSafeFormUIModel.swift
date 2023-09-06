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
import Json

protocol CreateSafeFormUIModelDelegate: AnyObject {
    func updateUI(model: CreateSafeFormUIModel)
    func createSafeModelDidFinish()
}

class CreateSafeFormUIModel {
    var name: String?
    var chain: Chain!
    var owners: [CreateSafeFormOwner] = []
    var threshold: Int = 1
    var selectedKey: KeyInfo?
    var deployerBalance: Sol.UInt256?
    var minNonce: Sol.UInt64 = 0
    var transaction: EthTransaction!
    var error: Error?
    var gsError: DetailedLocalizedError?
    var userTxParameters = UserDefinedTransactionParameters()
    var sectionHeaders: [CreateSafeFormSectionHeader] = []
    var state: CreateSafeFormUIState = .initial
    var futureSafeAddress: Address?
    var userSelectedPaymentMethod: Transaction.PaymentMethod? = nil
    var relaysRemaining = 0
    var relaysLimit = 0

    private var debounceTimer: Timer?
    private var estimationTask: URLSessionTask?
    private var getBalanceTask: URLSessionTask?
    private var sendingTask: URLSessionTask?
    private var relayingTask: URLSessionTask?
    private var receiptTask: URLSessionTask?
    private var safeInfoTask: URLSessionTask?

    var estimationController: TransactionEstimationController!
    let relayerService: SafeGelatoRelayService = App.shared.relayService

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
            update(to: .searchingKey)

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

                let _ = self.handleError { try result.get() }

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

        default:
            break
        }

        sectionHeaders = makeSectionHeaders()

        delegate?.updateUI(model: self)
    }

    // MARK: - UI Events

    var isEditingEnabled: Bool {
        state == .ready || state == .changed || state == .error || state == .keyNotFound
    }

    // TODO: Refactor this and introduce new state to reflect relaying state
    var isCreateEnabled: Bool {
        name != nil &&
        !name!.isEmpty &&
        chain != nil &&
        !owners.isEmpty &&
        threshold > 0 &&
        threshold <= owners.count &&
        transaction != nil &&
        error == nil &&
        ((state == .ready &&
          selectedKey != nil &&
          deployerBalance != nil &&
          deployerBalance! >= transaction.requiredBalance) ||
         (!userSelectedSigner &&
          chainSupportsRelayer &&
          relaysLeft))
    }

    var userSelectedSigner: Bool {
        return userSelectedPaymentMethod == .signerAccount
    }

    var chainSupportsRelayer: Bool {
        return chain.isSupported(feature: .relayingMobile)
    }

    var relaysLeft: Bool {
        return relaysRemaining > ReviewExecutionViewController.MIN_RELAY_TXS_LEFT
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

        creationParameters = nil
        update(to: .changed)
    }

    // MARK: - Setup
    
    private func setup() {
        if creationParameters == nil {
            chain = Chain.mainnetChain()
            owners = []
            threshold = 1
        }
        transaction = handleError { try makeEthTransaction() }
        sectionHeaders = makeSectionHeaders()
    }

    func setName(_ name: String) {
        self.name = name
        didEdit()
    }

    func setChain(_ scgChain: SCGModels.Chain) {
        let newChain = Chain.createOrUpdate(scgChain)
        if chain.id != newChain.id {
            selectedKey = nil
            deployerBalance = nil
        }
        chain = newChain

        if chain.isSupported(feature: .relayingMobile) {
            userSelectedPaymentMethod = nil  // prefer sponsored payment
        }
        // needs updating because the chain prefix will change and potentially address name from address book
        updateOwners()
        didEdit()
    }

    func addOwnerAddress(_ address: Address) {
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
        let min = min(threshold, owners.count)
        if min > 0 {
             threshold = min
        } else {
            threshold = 1
        }
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
                badgeName: keyInfo?.keyType.badgeName)
        return owner
    }

    func updateOwners() {
        owners = owners.map(\.address).map { owner(from: $0, defaultName: nil) }
    }

    private func handleError<T>(_ closure: () throws -> T) -> T? {
        do {
            return try closure()
        } catch {
            self.error = error
            return nil
        }
    }

    private var deploymentVersion: SafeDeployments.Safe.Version!
    private var proxyFactoryAddress: Sol.Address!
    private var fallbackHandlerAddress: Sol.Address!
    private var singletonAddress: Sol.Address!
    private var saltNonce: Sol.UInt256!

    private func setupTransactionParameters() throws {
        deploymentVersion = SafeDeployments.Safe.Version.v1_3_0
        proxyFactoryAddress = try address(of: .ProxyFactory, version: deploymentVersion)
        fallbackHandlerAddress = try address(of: .CompatibilityFallbackHandler, version: deploymentVersion)
        let safeL1Address = try address(of: .GnosisSafe, version: deploymentVersion)
        let safeL2Address = try address(of: .GnosisSafeL2, version: deploymentVersion)
        singletonAddress = chain.l2 ? safeL2Address : safeL1Address
        try generateSalt()
    }

    func generateSalt() throws {
        do {
            // generate salt
            var saltBytes: [UInt8] = .init(repeating: 0, count: 32)
            let randomSaltResult = SecRandomCopyBytes(kSecRandomDefault, saltBytes.count, &saltBytes)

            guard randomSaltResult == errSecSuccess else {
                throw CreateSafeError(errorCode: -6, message: "Failed to create random salt (sec error \(randomSaltResult))")
            }

            saltNonce = try Sol.UInt256(Data(saltBytes))
        } catch {
            throw CreateSafeError(errorCode: -7, message: "Failed to create random salt from bytes", cause: error)
        }
    }

    private func makeEthTransaction() throws -> EthTransaction {
        if creationParameters == nil {
            try setupTransactionParameters()
        } else {
            // No need to recreate transaction parameters
            // because they are already created from creationParameters when this screen is initialized

            if saltNonce == nil {
                try generateSalt()
            }
        }

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


        // create proxy with nonce
        let createFunction = GnosisSafeProxyFactory_v1_3_0.createProxyWithNonce(
            _singleton: singletonAddress,
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
                from: (selectedKey?.address.data32).flatMap(Sol.Address.init(maybeData:)),
                to: proxyFactoryAddress,
                data: Sol.Bytes(storage: createAbi),
                fee: .init(maxPriorityFee: userTxParameters.maxPriorityFee ??  Self.defaultMinerTip)
            )
        } else {
            result = Eth.TransactionLegacy(
                chainId: chainId,
                from: (selectedKey?.address.data32).flatMap(Sol.Address.init(maybeData:)),
                to: proxyFactoryAddress,
                data: Sol.Bytes(storage: createAbi)
            )
        }

        return result
    }

    func updateEthTransactionWithUserValues() {
        // take the values only if they were set by user (not nil)
        switch transaction {
        case var ethTx as Eth.TransactionLegacy:
            ethTx.fee.gas = userTxParameters.gas ?? ethTx.fee.gas
            ethTx.fee.gasPrice = userTxParameters.gasPrice ?? ethTx.fee.gasPrice
            ethTx.nonce = userTxParameters.nonce ?? ethTx.nonce

            self.transaction = ethTx

        case var ethTx as Eth.TransactionEip1559:
            ethTx.fee.gas = userTxParameters.gas ?? ethTx.fee.gas
            ethTx.fee.maxFeePerGas = userTxParameters.maxFeePerGas ?? ethTx.fee.maxFeePerGas
            ethTx.fee.maxPriorityFee = userTxParameters.maxPriorityFee ?? ethTx.fee.maxPriorityFee
            ethTx.nonce = userTxParameters.nonce ?? ethTx.nonce

            self.transaction = ethTx

        default:
            break
        }
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
            .init(id: .name, title: "Safe Account Name", itemCount: 1),
            .init(id: .network, title: "Network", tooltip: "Safe Account will only exist on the selected network.", itemCount: 2),
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
            result.append(.init(id: .error, title: "", tooltip: nil, itemCount: 1))
        }

        return result
    }

    // MARK: - Estimate

    static let defaultMinerTip: Sol.UInt256 = 1_500_000_000

    func estimate(_ completion: @escaping (Result<Void, Error>) -> Void) {

        precondition(chain != nil, "Chain not set")

        do {
            transaction = try makeEthTransaction()
            updateEthTransactionWithUserValues()
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
                let results = try result.get()

                let gas = try results.gas.get()
                let callResult = try results.ethCall.get()
                let safeAddress = try Sol.Address(data: callResult)
                let gasPrice = try results.gasPrice.get()
                let txCount = try results.transactionCount.get()
                let balance = try results.balance.get()

                self.futureSafeAddress = Address(safeAddress)
                self.minNonce = txCount
                self.deployerBalance = balance
                self.transaction.update(gas: gas, transactionCount: txCount, baseFee: gasPrice)

                self.updateEthTransactionWithUserValues()

                if balance < self.transaction.requiredBalance && self.userSelectedPaymentMethod == .signerAccount {
                    completion(.failure(CreateSafeError(errorCode: -9, message: "Insufficient balance for network fees")))
                } else {
                    completion(.success(()))
                }
            } catch {
                self.updateEthTransactionWithUserValues()
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
               let chainId = keyInfo.walletConnections?.first?.chainId,
               // when chainId is 0 then it is 'any' chain
               chainId != 0 && String(chainId) != chain.id {
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

    // MARK: - UI Data

    var minThreshold: Int {
        1
    }

    var maxThreshold: Int {
        owners.isEmpty ? 1 : owners.count
    }

    var thresholdText: String {
        if owners.isEmpty {
            return "1 out of 1"
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
            badge: key.keyType.badgeName,
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

    func userDidSubmit() {
        lazy var trackingParameters: [String : Any] = { ["chain_id": chain.id!, "keyType": selectedKey!.keyType.trackingValue] }()
        Tracker.trackEvent(.createSafeTxSubmitted, parameters: trackingParameters)
        update(to: .sending)
        let _ = send(completion: { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.didSubmitFailed(error)
                Tracker.trackEvent(.createSafeTxFailed, parameters: trackingParameters)

            case .success:
                self.didSubmitSuccess()
                Tracker.trackEvent(.createSafeTxSuccedded, parameters: trackingParameters)
            }
        })
    }

    func relaySubmit() {
        relayingTask?.cancel()
        relayingTask = relay(completion: { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                Tracker.trackEvent(.relayUserFailure)
                self.didSubmitFailed(error)
            case .success(let taskId):
                Tracker.trackEvent(.relayUserSuccess)
                self.didSubmitSuccess(taskId: taskId)
            }
        })
    }

     func relay(completion: @escaping (Result<String, Error>) -> Void) -> URLSessionTask? {
        guard let tx = transaction else { return nil }
        let task = relayerService.asyncRelayTransaction(chainId: chain!.id!,
                                                        to: Address(tx.to),
                                                        txData: tx.data.storage.toHexStringWithPrefix()
        ) { [weak self] response in
            guard let self = self else { return }
            switch(response) {
            case .success:
                guard let taskId = try? response.get().taskId else {
                    dispatchOnMainThread(completion(.failure(TransactionExecutionError(code: -7, message: "Missing taskId"))))
                    return
                }
                DispatchQueue.main.async {
                    self.didSubmitTransaction(txHash: Eth.Hash(tx.txHash().storage))
                    completion(.success((taskId)))
                }
            case .failure(let error):
                dispatchOnMainThread(completion(.failure(error)))
            }
        }
        return task
    }

    // this creates a tx and sends it to infura for execution
    func send(completion: @escaping (Result<Void, Error>) -> Void) -> URLSessionTask? {

        Tracker.trackEvent(.relayUserExecTxPaymentSigner)
        guard let tx = transaction else { return nil }

        let rawTransaction = tx.rawTransaction()

        let sendRawTxMethod = EthRpc1.eth_sendRawTransaction(transaction: rawTransaction)

        let request: JsonRpc2.Request

        do {
            request = try sendRawTxMethod.request(id: .int(1))
        } catch {
            dispatchOnMainThread(completion(.failure(error)))
            return nil
        }

        let client = estimationController.rpcClient

        let task = client.send(request: request) { [weak self] response in
            guard let self = self else { return }

            guard let response = response else {
                let error = TransactionExecutionError(code: -4, message: "No response from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            if let error = response.error {
                let jsonError = (try? error.data?.convert(to: Json.NSError.self))?.nsError() ?? (error as NSError)
                dispatchOnMainThread(completion(.failure(jsonError)))
                return
            }

            guard let result = response.result else {
                let error = TransactionExecutionError(code: -5, message: "No result from server")
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            let txHash: EthRpc1.Data
            do {
                txHash = try sendRawTxMethod.result(from: result)
            } catch {
                dispatchOnMainThread(completion(.failure(error)))
                return
            }

            DispatchQueue.main.async {
                self.didSubmitTransaction(txHash: Eth.Hash(txHash.storage))
                completion(.success(()))
            }
        }
        return task
    }

    private var creationParameters: SafeCreationCall?

    func saveCreationParameters() throws {
        let context = App.shared.coreDataStack.viewContext

        let params: SafeCreationCall = SafeCreationCall(context: context)
        params.chainId = chain.id
        params.deployerAddress = selectedKey?.address.checksummed
        params.fallbackHandlerAddress = Address(fallbackHandlerAddress).checksummed
        params.name = name
        params.owners = owners.map(\.address.checksummed).joined(separator: ",")
        params.proxyFactoryAddress = Address(proxyFactoryAddress).checksummed
        params.safeAddress = futureSafeAddress!.checksummed
        params.saltNonce = String(saltNonce)
        params.singletonAddress = Address(singletonAddress).checksummed
        params.threshold = String(threshold)

        // these two are for debugging purposes
        params.transactionData = transaction.data.storage
        params.transactionHash = transaction.txHash().storage.storage.toHexStringWithPrefix()

        params.version = deploymentVersion.rawValue

        App.shared.coreDataStack.saveContext()
    }

    func updateWithSafeCall(call: SafeCreationCall) {
        if let chainId = call.chainId {
            chain = Chain.by(chainId)
        }

        if let deployerAddressString = call.deployerAddress,
           let address = Address(deployerAddressString) {
            selectedKey = try? KeyInfo.firstKey(address: address)
        }

        if let fallbackHandlerAddressString = call.fallbackHandlerAddress,
           let address = Address(fallbackHandlerAddressString) {
            fallbackHandlerAddress = Sol.Address.init(maybeData: address.data32)
        }

        name = call.name
        owners = call.owners?
            .split(separator: ",")
            .map(String.init)
            .compactMap(Address.init)
            .map { owner(from: $0) } ?? []


        if let proxyFactoryAddressString = call.proxyFactoryAddress,
           let address = Address(proxyFactoryAddressString) {
            proxyFactoryAddress = Sol.Address.init(maybeData: address.data32)
        }

        // we re-generate the salt because otherwise the same safe address will be produced.
        // This leads to the reverted transaction, hence the estimation will fail and user needs to
        // refresh or change Safe Account parameters to re-generate the salt.
        try? generateSalt()

        if let singletonAddressString = call.singletonAddress,
           let address = Address(singletonAddressString) {
            singletonAddress = Sol.Address.init(maybeData: address.data32)
        }

        threshold = call.threshold.flatMap(Int.init) ?? 1

        deploymentVersion = call.version.flatMap(SafeDeployments.Safe.Version.init(rawValue:))

        creationParameters = call
    }

    func didSubmitTransaction(txHash: Eth.Hash) {
        transaction.hash = txHash
    }

    func didSubmitFailed(_ error: Error?) {
        self.error = error
        self.gsError = GSError.CreateSafeFailed()
        update(to: .error)
    }

    func didSubmitSuccess(taskId: String? = nil) {
        defer {
            update(to: .final)
            delegate?.createSafeModelDidFinish()
        }

        assert(transaction.hash != nil)
        assert(futureSafeAddress != nil)
        assert(name != nil)
        // create a safe
        guard let address = futureSafeAddress, let txHash = transaction.hash
        else {
           return
        }
        Safe.create(
            address: address.checksummed,
            version: "1.3.0",
            name: name!,
            chain: chain,
            selected: false,
            status: .deploying
        )

        // save the tx information for monitoring purposes
        let context = App.shared.coreDataStack.viewContext
        let ethTxHash = txHash.storage.storage.toHexStringWithPrefix()

        // prevent duplicates
        CDEthTransaction.removeWhere(ethTxHash: ethTxHash, chainId: chain.id!)

        let cdTx = CDEthTransaction(context: context)
        cdTx.ethTxHash = txHash.storage.storage.toHexStringWithPrefix()
        cdTx.safeTxHash = nil
        cdTx.taskId = taskId
        cdTx.status = SCGModels.TxStatus.pending.rawValue
        cdTx.safeAddress = address.checksummed
        cdTx.chainId = chain.id
        cdTx.dateSubmittedAt = Date()
        App.shared.coreDataStack.saveContext()

        try? saveCreationParameters()

        App.shared.notificationHandler.safeAdded(address: address)
        CompositeNavigationRouter.shared.navigate(to: NavigationRoute.showAssets(address.checksummed, chainId: chain.id))
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
    case sending
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
