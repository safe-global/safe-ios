// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.Bytes14

extension Sol {
    public struct Bytes14 {
        public var storage: Data
        public init(storage: Data) { self.storage = storage }
    }
}

extension Sol.Bytes14: SolFixedBytes {
    public static var byteCount: Int { 14 }
}

