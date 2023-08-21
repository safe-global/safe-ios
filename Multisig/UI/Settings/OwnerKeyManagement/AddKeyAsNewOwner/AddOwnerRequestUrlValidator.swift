//
//  AddOwnerRequestUrlValidator.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

struct AddOwnerRequestParameters {
    var chain: Chain
    var safeAddress: Address
    var ownerAddress: Address
    
    func link(base: URL = App.configuration.services.webAppURL) -> String {
        var url = base
            .appendingPathComponent("addOwner")
        
        let result: String
        
        let queryItems = [
            URLQueryItem(name: "safe", value: "\(chain.shortName!):\(safeAddress.checksummed)"),
            URLQueryItem(name: "address", value: ownerAddress.checksummed)
        ]
        
        if #available(iOS 16, *) {
            url.append(queryItems: queryItems)
            result = url.absoluteString
        } else {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            comps.queryItems = queryItems
            result = comps.url!.absoluteString
        }
        
        return result
    }
}

struct AddOwnerRequestValidator {

    private static var _webAppURL: URL = App.configuration.services.webAppURL
    static var webAppURL: URL {
        get {
            _webAppURL
        }
        set {
            _webAppURL = newValue
            pattern = "^\(newValue)addOwner\\?safe=([-a-zA-Z0-9]{1,20}):(0x[a-fA-F0-9]{40})&address=(0x[a-fA-F0-9]{40})$"
        }
    }
    private static var pattern = "^\(webAppURL)addOwner\\?safe=([-a-zA-Z0-9]{1,20}):(0x[a-fA-F0-9]{40})&address=(0x[a-fA-F0-9]{40})$"

    static func isValid(url: URL) -> Bool {
        guard url.absoluteString.matches(pattern: pattern) else { return false }

        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }

        guard
            matches.count == 3 &&
            // safe address at position 1
            Address(matches[1]) != nil &&
            // owner address at position 2
            Address(matches[2]) != nil
        else {
            return false
        }
        return true
    }

    static func parameters(from url: URL) -> AddOwnerRequestParameters? {
        let matches = url.absoluteString.capturedValues(pattern: pattern).flatMap { $0 }
        guard
            matches.count == 3,
            let chain = Chain.by(shortName: matches[0]),
            let safe = Address(matches[1]),
            let owner = Address(matches[2])
        else {
            return nil
        }
        return AddOwnerRequestParameters(
            chain: chain,
            safeAddress: safe,
            ownerAddress: owner
        )
    }
}
