//
//  File.swift
//
//
//  Created by Dmitry Bespalov on 03.01.22.
//

import Foundation

public enum ERC20 {
    public struct transferFrom: SolContractFunction, SolKeyPathTuple {
        public var from: Sol.Address
        public var to: Sol.Address
        public var value: Sol.UInt256

        public static var keyPaths: [AnyKeyPath] = [\Self.from, \Self.to, \Self.value]

        public init() {
            from = .init()
            to = .init()
            value = .init()
        }

        public init(from: Sol.Address, to: Sol.Address, value: Sol.UInt256) {
            self.from = from
            self.to = to
            self.value = value
        }

        public struct Returns: SolKeyPathTuple {
            public var success: Sol.Bool

            public static var keyPaths: [AnyKeyPath] = [\Self.success]

            public init() {
                success = .init()
            }
            public init(success: Sol.Bool) {
                self.success = success
            }
        }

    }
}
