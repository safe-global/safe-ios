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
import WalletConnectRouter
import Web3
import Web3Wallet
import UIKit

class WalletConnectManager {
    let EVM_COMPATIBLE_NETWORK = "eip155"
    static let shared = WalletConnectManager()
    
    private var publishers = [AnyCancellable]()
    private var dappConnectedTrackingEvent: TrackingEvent?
    private let metadata = AppMetadata(
        name: Bundle.main.displayName + " (iOS) ",
        description: "The most trusted platform to manage digital assets on Ethereum",
        url: App.configuration.services.webAppURL.absoluteString,
        icons: ["https://app.safe.global/favicons/mstile-150x150.png",
                "https://app.safe.global/favicons/logo_120x120.png"])
    
    private init() { }
    
    func config() {
        Networking.configure(projectId: App.configuration.walletConnect.walletConnectProjectId,
                             socketFactory: SocketFactory())
        Pair.configure(metadata: metadata)
        Web3Wallet.configure(metadata: metadata, signerFactory: DummySignerFactory())
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
                approveSession(proposal: proposal)
            }.store(in: &publishers)
        
        Web3Wallet.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.global(qos: .background))
            .sink { [unowned self] request in
                handle(request: request)
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
        WalletConnectURI(string: url) != nil
    }
    
    func pairClient(url: String, trackingEvent: TrackingEvent?) {
        guard let uri = WalletConnectURI(string: url) else { return }
        dappConnectedTrackingEvent = trackingEvent
        pairClient(uri: uri)
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
                    if "\(error)" == "pairingAlreadyExist" {
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
    
    func reject(request: Request) {
        Task {
            do {
                try await Web3Wallet.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .error(.init(code: 0, message: ""))
                )
            } catch {
                print("DAPP: Respond Error: \(error.localizedDescription)")
                Task { @MainActor in
                    App.shared.snackbar.show(error: GSError.error(description: "Respond Error: ", error: error))
                }
            }
        }
    }
    
    func approveSession(proposal: Session.Proposal) {
        Task {
            guard let safe = try? Safe.getSelected() else { return }
            var chainDropped = false
            var sessionNamespaces = [String: SessionNamespace]()
            proposal.requiredNamespaces.forEach {
                let caip2Namespace = $0.key
                let proposalNamespace = $0.value
                guard let chains = proposalNamespace.chains else { return }

                let selectedSafeChain = chains.filter { chain in
                    if chain.namespace == EVM_COMPATIBLE_NETWORK && chain.reference == safe.chain?.id {
                        return true
                    } else {
                        chainDropped = true
                        return false
                    }
                }

                let accounts = Set(selectedSafeChain.compactMap {
                    Account($0.absoluteString + ":\(safe.addressValue)")
                })

                let sessionNamespace = SessionNamespace(accounts: accounts,
                                                        methods: proposalNamespace.methods,
                                                        events: proposalNamespace.events)
                sessionNamespaces[caip2Namespace] = sessionNamespace
            }
            do {
                try await Web3Wallet.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            } catch {
                print("DAPP: Approve Session error: \(error)")
                let err: DetailedLocalizedError
                if chainDropped {
                    err = GSError.WC2SessionApprovalFailedWrongChain()
                } else {
                    err = GSError.WC2SessionApprovalFailed()
                }
                Task { @MainActor in
                    App.shared.snackbar.show(error: err)
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
            print("DAPP: extending Session error: \(error)")
        }
    }

    func disconnect(session: Session) {
        Task {
            do {
                NotificationCenter.default.post(name: .wcDidDisconnectSafeServer, object: self)
                try await Web3Wallet.instance.disconnect(topic: session.topic)
            } catch {
                print("DAPP: disconnecting Session error: \(error)")
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
                // make transformation of incoming request into internal data types
                // and fetch information about safe from the request
                DispatchQueue.global(qos: .background).async {
                    guard let safeInfo = try? App.shared.clientGatewayService.syncSafeInfo(
                        safeAddress: safe.addressValue, chainId: safe.chain!.id!) else {
                        reject(request: request)
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
