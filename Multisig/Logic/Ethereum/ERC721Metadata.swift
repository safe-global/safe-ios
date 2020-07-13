//
//  ERC721Metadata.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

class ERC721: ERC165 {

    enum Selectors {
        static let safeTransferFrom = "safeTransferFrom(address,address,uint256)"
    }

    func name() throws -> String? {
        try decodeString(invoke("name()"))
    }

    func symbol() throws -> String? {
        try decodeString(invoke("symbol()"))
    }

    func decimals() throws -> UInt256 {
        try decodeUInt(invoke("decimals()"))
    }

    func tokenURI(tokenId: UInt256) throws -> String? {
        try decodeString(invoke("tokenURI(uint256)", encodeUInt(tokenId)))
    }

}
