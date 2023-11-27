//
//  WCV2DappToWalletController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 24.11.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import UIKit
import Foundation
import WalletConnectSign
import Combine

// K Wallets - K Sessions -> N accounts on M chains -> N KeyInfos

class WCV2DappToWalletController {
    
    static let shared = WCV2DappToWalletController()
    
    var uris: [WalletConnectURI] = []
    var sessions: [Session] = []
    var pendingProposals: [(proposal: Session.Proposal, context: VerifyContext?)] = []
    var pendingRequests: [(request: Request, context: VerifyContext?)] = []
    
    private var subs = Set<AnyCancellable>()
    
    func configure() {
        let s = Sign.instance
        
        sessions = s.getSessions()
        pendingProposals = s.getPendingProposals()
        pendingRequests = s.getPendingRequests()
        
        LogService.shared.debug("{WC} Sessions (\(sessions.count)): \(sessions.map(\.topic))")
        LogService.shared.debug("{WC} Proposals (\(pendingProposals.count)): \(pendingProposals.map(\.proposal.id))")
        LogService.shared.debug("{WC} Requests (\(pendingRequests.count)): \(pendingRequests.map(\.request.method))")

        s.socketConnectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { (status: SocketConnectionStatus) in
                LogService.shared.debug("{WC} Socket: \(status)")
            }
            .store(in: &subs)
        
        s.pingResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { topic in
                LogService.shared.debug("{WC} Ping: \(topic)")
            }
            .store(in: &subs)
        
        s.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { (sessions: [Session]) in
                LogService.shared.debug("{WC} Sessions Updated (\(sessions.count)): \(sessions.map(\.topic))")
            })
            .store(in: &subs)
        
        s.sessionProposalPublisher
            .receive(on: DispatchQueue.main)
            .sink { (proposal: Session.Proposal, context: VerifyContext?) in
                LogService.shared.debug("{WC} Proposal: \(proposal.id) \(context as Any)")
            }
            .store(in: &subs)
                
        s.sessionSettlePublisher
            .receive(on: DispatchQueue.main)
            .sink { (session: Session) in
                LogService.shared.debug("{WC} Session Settled: \(session.topic)")
            }
            .store(in: &subs)
        
        s.sessionRejectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { (proposal: Session.Proposal, reason: Reason) in
                LogService.shared.debug("{WC} Session Rejected: \(proposal.id) \(reason)")
            }
            .store(in: &subs)
        
        s.sessionUpdatePublisher
            .receive(on: DispatchQueue.main)
            .sink { (sessionTopic: String, namespaces: [String : SessionNamespace]) in
                LogService.shared.debug("{WC} Session Update: \(sessionTopic) \(namespaces)")
            }
            .store(in: &subs)
        
        s.sessionEventPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { (event: Session.Event, sessionTopic: String, chainId: Blockchain?) in
                LogService.shared.debug("{WC} Session Event Occurred: \(event) \(sessionTopic) \(chainId as Any)")
            })
            .store(in: &subs)
        
        s.sessionExtendPublisher
            .receive(on: DispatchQueue.main)
            .sink { (sessionTopic: String, date: Date) in
                LogService.shared.debug("{WC} Session Extended: \(sessionTopic) \(date)")
            }
            .store(in: &subs)

        s.sessionDeletePublisher
            .receive(on: DispatchQueue.main)
            .sink { (topic: String, reason: Reason) in
                LogService.shared.debug("{WC} Session Deleted: \(topic) \(reason)")
            }
            .store(in: &subs)

        s.sessionRequestPublisher
            .receive(on: DispatchQueue.main)
            .sink { (request: Request, context: VerifyContext?) in
                LogService.shared.debug("{WC} Request: \(request) \(context as Any)")
            }
            .store(in: &subs)
        
        s.sessionResponsePublisher
            .receive(on: DispatchQueue.main)
            .sink { (response: Response) in
                LogService.shared.debug("{WC} Response: \(response)")
            }
            .store(in: &subs)
    }
    
    // TODO: provide registry account
    // TODO: notify caller of the result
    // TODO: persistence and connecting to the database objects (key info, web connection)
    // TODO: multiple keyinfo/accounts to a single session is possible
    @MainActor
    func connect() {
        Task {
            // WalletConnect's Networking.instance is configured in the `WalletConnectManager` on app startup, no need
            // to do it here.
            let uri = try await Pair.instance.create()
            uris.append(uri)
            try await Sign.instance.connect(
                requiredNamespaces: [
                    "eip155": ProposalNamespace(
                        chains: [Blockchain("eip155:1")!],
                        methods: ["eth_sendTransaction", "eth_signTypedData", "eth_sign"],
                        events: ["accountsChanged", "chainChanged"]
                    )
                ],
                topic: uri.topic
            )
            // TODO: use universal link scheme
            let link = uri.deeplinkUri
            let walletUrl = URL(string: "metamask://wc?uri=\(link)")!
            LogService.shared.debug("{WC} opening '\(walletUrl.absoluteString)'")
            
            let didOpen = await UIApplication.shared.open(walletUrl)
            LogService.shared.debug("{WC} Did open url: \(didOpen)")
        }
    }
    
}
