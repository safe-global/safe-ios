//
//  Configuration.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 2/16/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

import Foundation

public struct NamingServiceConfig {
    let network: String
    let providerUrl: String
    let networking: NetworkingLayer

    public init(
        providerUrl: String,
        network: String = "",
        networking: NetworkingLayer = DefaultNetworkingLayer()
    ) {
        self.network = network
        self.providerUrl = providerUrl
        self.networking = networking
    }
}

public struct Configurations {
    let cns: NamingServiceConfig
    let zns: NamingServiceConfig
    let ens: NamingServiceConfig

    public init(
        cns: NamingServiceConfig = NamingServiceConfig(
            providerUrl: "https://mainnet.infura.io/v3/3c25f57353234b1b853e9861050f4817",
            network: "mainnet"),
        ens: NamingServiceConfig = NamingServiceConfig(
            providerUrl: "https://mainnet.infura.io/v3/d423cf2499584d7fbe171e33b42cfbee",
            network: "mainnet"),
        zns: NamingServiceConfig = NamingServiceConfig(
            providerUrl: "https://api.zilliqa.com",
            network: "mainnet")
    ) {
        self.ens = ens
        self.cns = cns
        self.zns = zns
    }
}
