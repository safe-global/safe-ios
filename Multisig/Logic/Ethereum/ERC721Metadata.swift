//
//  ERC721Metadata.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt

class ERC721Metadata: Contract {

    func name() throws -> String? {
        try decodeString(invoke("name()"))
    }

    func symbol() throws -> String? {
        try decodeString(invoke("symbol()"))
    }

    func decimals() throws -> Int {
        try Int(clamping: decodeUInt(invoke("decimals()")))
    }

    func tokenURI(tokenId: BigInt) throws -> String? {
        try decodeString(invoke("tokenURI(uint256)", encodeUInt(tokenId)))
    }

}
