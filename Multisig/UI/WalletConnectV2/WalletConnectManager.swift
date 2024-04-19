//
//  WalletConnectV2Manager.swift
//  Multisig
//
//  Created by Mouaz on 2/22/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectNetworking
import WalletConnectPairing
import Combine
import WalletConnectSign
import WalletConnectUtils
import SafeWeb3
import Web3Wallet
import UIKit
import WalletConnectRelay

class WalletConnectManager {
    static let shared = WalletConnectManager()
    
    private var publishers = [AnyCancellable]()
    private var dappConnectedTrackingEvent: TrackingEvent?
    private let metadata = AppMetadata(
        name: Bundle.main.displayName + " (iOS) ",
        description: "The most trusted platform to manage digital assets on Ethereum",
        url: App.configuration.services.webAppURL.absoluteString,
        icons: ["https://app.safe.global/favicons/mstile-150x150.png",
                "https://app.safe.global/favicons/logo_120x120.png"], 
        redirect: AppMetadata.Redirect(native: "", universal: "https://app.safe.global/"))

    // Testable interface for approving a session
    var approver: Approver = ApproverImpl()

    private init() { }
    
    func config() {
        let projectId = App.configuration.protected[.WALLETCONNECT_PROJECT_ID]
        Networking.configure(projectId: projectId, socketFactory: SocketFactory())
        Pair.configure(metadata: metadata)
        Web3Wallet.configure(metadata: metadata, crypto: NullCryptoProvider())
        setUpAuthSubscribing()
    }
    
    func setUpAuthSubscribing() {
        Web3Wallet.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    NotificationCenter.default.post(name: .wcDidConnectSafeServer, object: self)
                } else {
                    NotificationCenter.default.post(name: .wcDidDisconnectSafeServer, object: self)
                }
            }.store(in: &publishers)
        
        Web3Wallet.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] proposal in
                approveSession(proposal: proposal.proposal)
            }.store(in: &publishers)
        
        Web3Wallet.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] request in
                handle(request: request.request)
            }.store(in: &publishers)
        
        Web3Wallet.instance.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] sessions in
                sessions.forEach { session in
                    session.namespaces.forEach {
                        $0.value.accounts.forEach {
                            if let safe = Safe.by(address: $0.address, chainId: $0.reference) {
                                safe.addSession(topic: session.topic)
                            }
                        }
                    }
                    
                    if let dappConnectedTrackingEvent = dappConnectedTrackingEvent, !session.peer.name.isEmpty {
                        let dappName = session.peer.name.prefix(100)
                        Tracker.trackEvent(dappConnectedTrackingEvent, parameters: ["dapp_name": dappName])
                    }
                }
                
                dappConnectedTrackingEvent = nil
                NotificationCenter.default.post(name: .wcDidConnectSafeServer, object: self)
            }.store(in: &publishers)
        
        Web3Wallet.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] (topic, _) in
                deleteStoredSession(topic: topic)
                NotificationCenter.default.post(name: .wcDidDisconnectSafeServer, object: self)
            }.store(in: &publishers)
    }
    
    func canConnect(url: String) -> Bool {
        wcURI(string: url) != nil
    }
    
    func pairClient(url: String, trackingEvent: TrackingEvent?) {
        guard let uri = wcURI(string: url) else { return }
        dappConnectedTrackingEvent = trackingEvent
        pairClient(uri: uri)
    }
    
    private func wcURI(string: String) -> WalletConnectURI? {
        if string.hasPrefix("safe://wc?uri=") {
            let wcString = string.replacingOccurrences(of: "safe://wc?uri=", with: "wc://wc?uri=").removingPercentEncoding!
            let url = URL(string: wcString)!
            return WalletConnectURI(deeplinkUri: url)
        } else {
            return WalletConnectURI(string: string)
        }
    }
    
    func pairClient(uri: WalletConnectURI) {
        Task {
            do {
                disconnectUnusedPairings()
                try await Web3Wallet.instance.pair(uri: uri)
                NotificationCenter.default.post(name: .wcConnectingSafeServer, object: self)
            } catch {
                LogService.shared.error("DAPP: Pairing failed: \(error)")
                Task { @MainActor in
                    if "\(error)".hasPrefix("pairingAlreadyExist") {
                        App.shared.snackbar.show(error: GSError.WC2PairingAlreadyExists())
                    } else {
                        App.shared.snackbar.show(error: GSError.WC2PairingFailed())
                    }
                    
                }
            }
        }
    }
    
    private func sign(request: Request, response: AnyCodable) {
        Task {
            do {
                try await Web3Wallet.instance.respond(topic: request.topic, requestId: request.id, response: .response(response))
            } catch {
                print("DAPP: Respond Error: \(error.localizedDescription)")
                Task { @MainActor in
                    App.shared.snackbar.show(error: GSError.error(description: "Respond Error: ", error: error))
                }
            }
        }
    }
    
    func reject(request: Request, error: JSONRPCError = JSONRPCError(code: 0, message: "")) {
        Task {
            do {
                try await Web3Wallet.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .error(error)
                )
            } catch {
                print("DAPP: Respond Error: \(error.localizedDescription)")
                Task { @MainActor in
                    App.shared.snackbar.show(error: GSError.error(description: "Respond Error: ", error: error))
                }
            }
        }
    }
    
    let NAMESPACE_ID = "eip155"

    // Approves required chains and a chain where selected safe resides.
    //
    // For reference:
    //  - https://chainagnostic.org/CAIPs/caip-10
    //  - https://chainagnostic.org/CAIPs/caip-2
    //
    // Requires:
    //   - session proposal
    // Guarantees:
    //   - connection approved if safe's chain is in the proposal
    //   - if no such chain found in proposal, connection will fail
    func approveSession(proposal: Session.Proposal) {
        guard
            let address = approver.safe?.address,
            let chainId = approver.safe?.chain,
            let blockchain = Blockchain(namespace: NAMESPACE_ID, reference: chainId)
        else {
            approver.reject(.preconditionsNotSatisfied(id: proposal.id))
            return
        }
        
        var chains = [Blockchain]()
        var methods = [String]()
        var events = [String]()
        
        // approved proposal must contain all of the required namespaces
        if let ns = proposal.requiredNamespaces[NAMESPACE_ID] {
            chains.append(contentsOf: ns.chains ?? [])
            methods.append(contentsOf: ns.methods)
            events.append(contentsOf: ns.events)
        }
        
        // depending on the dApp, the chain we're looking for will be in the optional namespaces
        if let ns = proposal.optionalNamespaces?[NAMESPACE_ID], ns.chains?.contains(blockchain) == true {
            chains.append(blockchain)
            methods.append(contentsOf: ns.methods)
            events.append(contentsOf: ns.events)
        }
        
        guard chains.contains(blockchain) else {
            approver.reject(.chainNotFound(id: proposal.id))
            return
        }
        
        // WalletConnect requires to support accounts at least for all required chains
        let accounts = chains.compactMap { Account(blockchain: $0, address: address) }
        
        let creme = SessionNamespace(
            chains: Set(chains),
            accounts: Set(accounts),
            methods: Set(methods),
            events: Set(events)
        )
        
        let treat: [String: SessionNamespace] = [
            NAMESPACE_ID: creme
        ]

        approver.approve(proposalId: proposal.id, namespaces: treat)
    }
        
    class Approver {
        enum ApprovalFailure: Equatable {
            case preconditionsNotSatisfied(id: String)
            case chainNotFound(id: String)
        }
        
        struct Account {
            var address: String
            var chain: String
        }
        
        var safe: Account? {
            nil
        }
        
        func reject(_ failure: ApprovalFailure) {
        }
        
        func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
        }
    }
    
    class ApproverImpl: Approver {

        override var safe: Account? {
            guard let safe = try? Safe.getSelected(),
                  let address = safe.address,
                  let chain = safe.chain,
                  let chainId = chain.id
            else {
                return nil
            }
            return Account(address: address, chain: chainId)
        }
        
        override func reject(_ failure: ApprovalFailure) {
            Task { @MainActor in
                switch failure {
                case .preconditionsNotSatisfied(let id):
                    App.shared.snackbar.show(error: GSError.WC2SessionApprovalFailed())
                    try? await Web3Wallet.instance.reject(proposalId: id, reason: .userRejected)

                case .chainNotFound(let id):
                    App.shared.snackbar.show(error: GSError.WC2SessionApprovalFailedWrongChain())
                    try? await Web3Wallet.instance.reject(proposalId: id, reason: .userRejectedChains)
                }
            }
        }
        
        override func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
            Task { @MainActor in
                do {
                    try await Web3Wallet.instance.approve(proposalId: proposalId, namespaces: namespaces)
                } catch {
                    LogService.shared.error("Approval failed: \(error)")
                    App.shared.snackbar.show(error: GSError.WC2SessionApprovalFailed())
                }
            }
        }
    }

    
    /// By default, session lifetime is set for 7 days and after that time user's session will expire.
    /// This method will extend the session for 7 days
    func extend(session: Session) async {
        do {
            try await Web3Wallet.instance.extend(topic: session.topic)
        } catch {
            Task { @MainActor in
                App.shared.snackbar.show(error: GSError.error(description: error.localizedDescription, error: error))
            }
            LogService.shared.error("DAPP: extending Session error: \(error)")
        }
    }
    
    func disconnect(session: Session) {
        Task {
            do {
                NotificationCenter.default.post(name: .wcDidDisconnectSafeServer, object: self)
                try await Web3Wallet.instance.disconnect(topic: session.topic)
            } catch {
                LogService.shared.error("DAPP: disconnecting Session error: \(error)")
                Task { @MainActor in
                    App.shared.snackbar.show(error: GSError.error(description: "Disconnecting Session error", error: error))
                }
                
                
            }
            disconnectUnusedPairings()
        }
    }
    
    func deleteStoredSession(topic: String) {
        precondition(Thread.isMainThread)
        Safe.removeSession(topic: topic)
        disconnectUnusedPairings()
    }
    
    // After deleting a session we do this to find and disconnect all unused pairings
    private func disconnectUnusedPairings() {
        var pairings = Web3Wallet.instance.getPairings()
        let sessions = Web3Wallet.instance.getSessions()
        
        sessions.forEach { session in
            pairings = pairings.filter { pairing in
                session.pairingTopic != pairing.topic
            }
        }
        pairings.forEach { pairing in
            Task {
                try await Web3Wallet.instance.disconnectPairing(topic: pairing.topic)
            }
        }
    }
    
    func getSessions(topics: [String]) -> [Session] {
        Web3Wallet.instance.getSessions().filter({ topics.contains($0.topic) })
    }
    
    private func handle(request: Request) {
        dispatchPrecondition(condition: .notOnQueue(.main))
        
        guard let session = getSessions(topics: [request.topic]).first else {
            reject(request: request)
            return
        }
        
        DispatchQueue.main.async { [unowned self] in
            guard let safe = Safe.by(topic: request.topic) else {
                reject(request: request)
                return
            }
            
            if request.method == "eth_sendTransaction" {
                guard 
                    let idString = safe.chain?.id,
                    let safeChainId = Blockchain(namespace: NAMESPACE_ID, reference: safe.chain!.id!),
                    request.chainId == safeChainId
                else {
                    DispatchQueue.main.async {
                        App.shared.snackbar.show(message: "Please select dApp chain matching with the safe's chain")
                    }
                    reject(request: request, 
                           error: JSONRPCError(code: -33012, message: "Please select a different chain"))
                    return
                }

                // make transformation of incoming request into internal data types
                // and fetch information about Safe Accout from the request
                DispatchQueue.global(qos: .background).async { [weak self] in
                    guard let safeInfo = try? App.shared.clientGatewayService.syncSafeInfo(
                        safeAddress: safe.addressValue, chainId: safe.chain!.id!) else {
                        self?.reject(request: request)
                        return
                    }
                    safe.update(from: safeInfo)
                }
                guard let ethereumTransaction = try? request.params.get([EthereumTransaction].self).first,
                      let transaction = Transaction(transaction: ethereumTransaction, safe: safe)
                else {
                    reject(request: request)
                    return
                }
                
                guard !safe.isReadOnly else {
                    DispatchQueue.main.async {
                        App.shared.snackbar.show(message: "Please import Safe Owner Key to initiate WalletConnect transactions")
                    }
                    reject(request: request)
                    return
                }
                
                DispatchQueue.main.async { [unowned self] in
                    // present confirmation controller
                    let confirmationController = WCIncomingTransactionRequestViewController(
                        transaction: transaction,
                        safe: safe,
                        dAppName: session.peer.name,
                        dAppIconURL: URL(string: session.peer.icons.first ?? ""))
                    
                    confirmationController.onReject = { [unowned self] in
                        reject(request: request)
                    }
                    
                    confirmationController.onSubmit = { nonce, safeTxHash in
                        self.sign(request: request, response: AnyCodable(safeTxHash))
                    }
                    
                    let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
                    sceneDelegate.present(ViewControllerFactory.modal(viewController: confirmationController))
                }
            } else {
                DispatchQueue.global(qos: .background).async {
                    do {
                        let rpcURL = safe.chain!.authenticatedRpcUrl
                        let result = try AnyCodable(any: App.shared.nodeService.rawCall(payload: request.asJSONEncodedString(),
                                                                                        rpcURL: rpcURL))
                        self.sign(request: request, response: result)
                    } catch {
                        DispatchQueue.main.async {
                            App.shared.snackbar.show(
                                error: GSError.error(description: "Could not handle WalletConnect request", error: error)
                            )
                        }
                    }
                }
            }
        }
    }
}

extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Safe Multisig"
    }
}
