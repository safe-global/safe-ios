//
//  Proposal.swift
//  Multisig
//
//  Created by Mouaz on 2/22/23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import WalletConnectSign

struct Proposal {
    let proposerName: String
    let proposerDescription: String
    let proposerURL: String
    let iconURL: String
    let permissions: [Namespace]

    struct Namespace: Hashable {
        let chains: [String]
        let methods: [String]
        let events: [String]
    }

    internal init(proposal: Session.Proposal) {
        self.proposerName = proposal.proposer.name
        self.proposerDescription = proposal.proposer.description
        self.proposerURL = proposal.proposer.url
        self.iconURL = proposal.proposer.icons.first ?? "https://avatars.githubusercontent.com/u/37784886"
        self.permissions = [
            Namespace(
                chains: ["eip155:1"],
                methods: ["eth_sendTransaction", "personal_sign", "eth_signTypedData"],
                events: ["accountsChanged", "chainChanged"])]
    }

    internal init(proposerName: String,
                  proposerDescription: String,
                  proposerURL: String,
                  iconURL: String,
                  permissions: [Proposal.Namespace]) {
        self.proposerName = proposerName
        self.proposerDescription = proposerDescription
        self.proposerURL = proposerURL
        self.iconURL = iconURL
        self.permissions = permissions
    }
}

