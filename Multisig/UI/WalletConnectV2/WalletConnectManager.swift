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

class WalletConnectManager {
    static let shared = WalletConnectManager()
    
    private var publishers = [AnyCancellable]()

    private let metadata = AppMetadata(
        name: Bundle.main.displayName,
        description: "The most trusted platform to manage digital assets on Ethereum",
        url: App.configuration.services.webAppURL.absoluteString,
        icons: ["https://app.safe.global/favicons/mstile-150x150.png",
                "https://app.safe.global/favicons/logo_120x120.png"])

    private init() { }

    func config() {
        Networking.configure(projectId: App.configuration.walletConnect.walletConnectProjectId,
                             socketFactory: SocketFactory())

        Pair.configure(metadata: metadata)
        setUpAuthSubscribing()
    }

    func setUpAuthSubscribing() {
        Sign.instance.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status == .connected {
                    NotificationCenter.default.post(name: .wcDidConnectSafeServer, object: self)
                } else {
                    NotificationCenter.default.post(name: .wcDidDisconnectSafeServer, object: self)
                }
            }.store(in: &publishers)

        Sign.instance.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] proposal in
                approveSession(proposal: proposal)
            }.store(in: &publishers)

        Sign.instance.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] sessionRequest in
                // TODO: Handle incomming request
            }.store(in: &publishers)

        Sign.instance.sessionsPublisher
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
                }
                if let dappConnectedTrackingEvent = dappConnectedTrackingEvent {
                    // parameter names should not exceed 100 chars
                    let dappName = session.peer.name.prefix(100)
                    Tracker.trackEvent(dappConnectedTrackingEvent, parameters: ["dapp_name" : dappName])
                    self.dappConnectedTrackingEvent = nil
                }
                
                NotificationCenter.default.post(name: .wcDidConnectSafeServer, object: self)
            }.store(in: &publishers)

        Sign.instance.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] response in
                deleteStoredSession(topic: response.0)
                NotificationCenter.default.post(name: .wcDidDisconnectSafeServer, object: self)
            }.store(in: &publishers)
    }

    func canConnect(url: String) -> Bool {
        WalletConnectURI(string: url) != nil
    }

    func pairClient(url: String,trackingEvent: TrackingEvent?) {
        guard let uri = WalletConnectURI(string: url) else { return }
        pairClient(uri: uri)
    }

    func pairClient(uri: WalletConnectURI) {
        Task {
            do {
                try await Sign.instance.pair(uri: uri)
                NotificationCenter.default.post(name: .wcConnectingSafeServer, object: self)
            } catch {
                LogService.shared.error("DAPP: Failed to register to remote notifications \(error)")
            }
        }
    }

    private func sign(request: Request, response: AnyCodable) {
        Task {
            do {
                try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(response))
            } catch {
                print("DAPP: Respond Error: \(error.localizedDescription)")
            }
        }
    }

    func reject(request: Request) {
        Task {
            do {
                try await Sign.instance.respond(
                    topic: request.topic,
                    requestId: request.id,
                    response: .error(.init(code: 0, message: ""))
                )
            } catch {
                print("DAPP: Respond Error: \(error.localizedDescription)")
            }
        }
    }

    func approveSession(proposal: Session.Proposal) {
        Task {
            guard let safe = try? Safe.getSelected() else { return }
            var sessionNamespaces = [String: SessionNamespace]()
            proposal.requiredNamespaces.forEach {
                let caip2Namespace = $0.key
                let proposalNamespace = $0.value
                let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(safe.addressValue)") })

                let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
                sessionNamespaces[caip2Namespace] = sessionNamespace
            }
            do {
                try await Sign.instance.approve(proposalId: proposal.id, namespaces: sessionNamespaces)
            } catch {
                print("DAPP: Approve Session error: \(error)")
            }
        }
    }

    /// By default, session lifetime is set for 7 days and after that time user's session will expire.
    /// This method will extend the session for 7 days
    func extend(session: Session) async {
        do {
            try await Web3Wallet.instance.extend(topic: session.topic)
        } catch {
            print("DAPP: extending Session error: \(error)")
        }
    }

    func disconnect(session: Session) {
        Task {
            do {
                NotificationCenter.default.post(name: .wcDidDisconnectSafeServer, object: self)
                try await Sign.instance.disconnect(topic: session.topic)
            } catch {
                print("DAPP: disconnectting Session error: \(error)")
            }
        }
    }

    func deleteStoredSession(topic: String) {
        precondition(Thread.isMainThread)
        Safe.removeSession(topic: topic)
    }
    
    func getSessions(topics: [String]) -> [Session] {
        Sign.instance.getSessions().filter({topics.contains($0.topic)})
    }
}

extension Bundle {
    var displayName: String {
        return object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Safe Multisig"
    }
}

