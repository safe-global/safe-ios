// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.Bytes32

extension Sol {
    public struct Bytes32 {
        public var storage: Data
        public init(storage: Data) { self.storage = storage }
    }
}

extension Sol.Bytes32: SolFixedBytes {
    public static var byteCount: Int { 32 }
}


