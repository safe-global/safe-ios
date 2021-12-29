//
//  Integers.swift
//  
//
//  Created by Dmitry Bespalov on 27.12.21.
//

import Foundation
import WordInteger

// MARK: - Sol.UInt8, Sol.Int8

extension Sol {
    public struct UInt8 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int8 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt8: WordUnsignedInteger {
    public typealias Stride = Sol.Int8
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 8 }
}

extension Sol.UInt8: SolInteger {
    // uses default implementation
}

extension Sol.Int8: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt8
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 8 }
}

extension Sol.Int8: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt16, Sol.Int16

extension Sol {
    public struct UInt16 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int16 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt16: WordUnsignedInteger {
    public typealias Stride = Sol.Int16
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 16 }
}

extension Sol.UInt16: SolInteger {
    // uses default implementation
}

extension Sol.Int16: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt16
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 16 }
}

extension Sol.Int16: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt24, Sol.Int24

extension Sol {
    public struct UInt24 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int24 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt24: WordUnsignedInteger {
    public typealias Stride = Sol.Int24
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 24 }
}

extension Sol.UInt24: SolInteger {
    // uses default implementation
}

extension Sol.Int24: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt24
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 24 }
}

extension Sol.Int24: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt32, Sol.Int32

extension Sol {
    public struct UInt32 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int32 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt32: WordUnsignedInteger {
    public typealias Stride = Sol.Int32
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 32 }
}

extension Sol.UInt32: SolInteger {
    // uses default implementation
}

extension Sol.Int32: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt32
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 32 }
}

extension Sol.Int32: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt40, Sol.Int40

extension Sol {
    public struct UInt40 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int40 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt40: WordUnsignedInteger {
    public typealias Stride = Sol.Int40
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 40 }
}

extension Sol.UInt40: SolInteger {
    // uses default implementation
}

extension Sol.Int40: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt40
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 40 }
}

extension Sol.Int40: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt48, Sol.Int48

extension Sol {
    public struct UInt48 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int48 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt48: WordUnsignedInteger {
    public typealias Stride = Sol.Int48
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 48 }
}

extension Sol.UInt48: SolInteger {
    // uses default implementation
}

extension Sol.Int48: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt48
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 48 }
}

extension Sol.Int48: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt56, Sol.Int56

extension Sol {
    public struct UInt56 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int56 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt56: WordUnsignedInteger {
    public typealias Stride = Sol.Int56
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 56 }
}

extension Sol.UInt56: SolInteger {
    // uses default implementation
}

extension Sol.Int56: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt56
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 56 }
}

extension Sol.Int56: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt64, Sol.Int64

extension Sol {
    public struct UInt64 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int64 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt64: WordUnsignedInteger {
    public typealias Stride = Sol.Int64
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 64 }
}

extension Sol.UInt64: SolInteger {
    // uses default implementation
}

extension Sol.Int64: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt64
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 64 }
}

extension Sol.Int64: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt72, Sol.Int72

extension Sol {
    public struct UInt72 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int72 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt72: WordUnsignedInteger {
    public typealias Stride = Sol.Int72
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 72 }
}

extension Sol.UInt72: SolInteger {
    // uses default implementation
}

extension Sol.Int72: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt72
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 72 }
}

extension Sol.Int72: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt80, Sol.Int80

extension Sol {
    public struct UInt80 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int80 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt80: WordUnsignedInteger {
    public typealias Stride = Sol.Int80
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 80 }
}

extension Sol.UInt80: SolInteger {
    // uses default implementation
}

extension Sol.Int80: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt80
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 80 }
}

extension Sol.Int80: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt88, Sol.Int88

extension Sol {
    public struct UInt88 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int88 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt88: WordUnsignedInteger {
    public typealias Stride = Sol.Int88
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 88 }
}

extension Sol.UInt88: SolInteger {
    // uses default implementation
}

extension Sol.Int88: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt88
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 88 }
}

extension Sol.Int88: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt96, Sol.Int96

extension Sol {
    public struct UInt96 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int96 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt96: WordUnsignedInteger {
    public typealias Stride = Sol.Int96
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 96 }
}

extension Sol.UInt96: SolInteger {
    // uses default implementation
}

extension Sol.Int96: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt96
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 96 }
}

extension Sol.Int96: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt104, Sol.Int104

extension Sol {
    public struct UInt104 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int104 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt104: WordUnsignedInteger {
    public typealias Stride = Sol.Int104
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 104 }
}

extension Sol.UInt104: SolInteger {
    // uses default implementation
}

extension Sol.Int104: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt104
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 104 }
}

extension Sol.Int104: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt112, Sol.Int112

extension Sol {
    public struct UInt112 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int112 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt112: WordUnsignedInteger {
    public typealias Stride = Sol.Int112
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 112 }
}

extension Sol.UInt112: SolInteger {
    // uses default implementation
}

extension Sol.Int112: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt112
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 112 }
}

extension Sol.Int112: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt120, Sol.Int120

extension Sol {
    public struct UInt120 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int120 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt120: WordUnsignedInteger {
    public typealias Stride = Sol.Int120
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 120 }
}

extension Sol.UInt120: SolInteger {
    // uses default implementation
}

extension Sol.Int120: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt120
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 120 }
}

extension Sol.Int120: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt128, Sol.Int128

extension Sol {
    public struct UInt128 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int128 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt128: WordUnsignedInteger {
    public typealias Stride = Sol.Int128
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 128 }
}

extension Sol.UInt128: SolInteger {
    // uses default implementation
}

extension Sol.Int128: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt128
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 128 }
}

extension Sol.Int128: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt136, Sol.Int136

extension Sol {
    public struct UInt136 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int136 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt136: WordUnsignedInteger {
    public typealias Stride = Sol.Int136
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 136 }
}

extension Sol.UInt136: SolInteger {
    // uses default implementation
}

extension Sol.Int136: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt136
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 136 }
}

extension Sol.Int136: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt144, Sol.Int144

extension Sol {
    public struct UInt144 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int144 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt144: WordUnsignedInteger {
    public typealias Stride = Sol.Int144
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 144 }
}

extension Sol.UInt144: SolInteger {
    // uses default implementation
}

extension Sol.Int144: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt144
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 144 }
}

extension Sol.Int144: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt152, Sol.Int152

extension Sol {
    public struct UInt152 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int152 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt152: WordUnsignedInteger {
    public typealias Stride = Sol.Int152
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 152 }
}

extension Sol.UInt152: SolInteger {
    // uses default implementation
}

extension Sol.Int152: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt152
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 152 }
}

extension Sol.Int152: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt160, Sol.Int160

extension Sol {
    public struct UInt160 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int160 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt160: WordUnsignedInteger {
    public typealias Stride = Sol.Int160
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 160 }
}

extension Sol.UInt160: SolInteger {
    // uses default implementation
}

extension Sol.Int160: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt160
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 160 }
}

extension Sol.Int160: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt168, Sol.Int168

extension Sol {
    public struct UInt168 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int168 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt168: WordUnsignedInteger {
    public typealias Stride = Sol.Int168
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 168 }
}

extension Sol.UInt168: SolInteger {
    // uses default implementation
}

extension Sol.Int168: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt168
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 168 }
}

extension Sol.Int168: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt176, Sol.Int176

extension Sol {
    public struct UInt176 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int176 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt176: WordUnsignedInteger {
    public typealias Stride = Sol.Int176
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 176 }
}

extension Sol.UInt176: SolInteger {
    // uses default implementation
}

extension Sol.Int176: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt176
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 176 }
}

extension Sol.Int176: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt184, Sol.Int184

extension Sol {
    public struct UInt184 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int184 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt184: WordUnsignedInteger {
    public typealias Stride = Sol.Int184
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 184 }
}

extension Sol.UInt184: SolInteger {
    // uses default implementation
}

extension Sol.Int184: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt184
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 184 }
}

extension Sol.Int184: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt192, Sol.Int192

extension Sol {
    public struct UInt192 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int192 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt192: WordUnsignedInteger {
    public typealias Stride = Sol.Int192
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 192 }
}

extension Sol.UInt192: SolInteger {
    // uses default implementation
}

extension Sol.Int192: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt192
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 192 }
}

extension Sol.Int192: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt200, Sol.Int200

extension Sol {
    public struct UInt200 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int200 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt200: WordUnsignedInteger {
    public typealias Stride = Sol.Int200
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 200 }
}

extension Sol.UInt200: SolInteger {
    // uses default implementation
}

extension Sol.Int200: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt200
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 200 }
}

extension Sol.Int200: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt208, Sol.Int208

extension Sol {
    public struct UInt208 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int208 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt208: WordUnsignedInteger {
    public typealias Stride = Sol.Int208
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 208 }
}

extension Sol.UInt208: SolInteger {
    // uses default implementation
}

extension Sol.Int208: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt208
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 208 }
}

extension Sol.Int208: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt216, Sol.Int216

extension Sol {
    public struct UInt216 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int216 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt216: WordUnsignedInteger {
    public typealias Stride = Sol.Int216
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 216 }
}

extension Sol.UInt216: SolInteger {
    // uses default implementation
}

extension Sol.Int216: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt216
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 216 }
}

extension Sol.Int216: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt224, Sol.Int224

extension Sol {
    public struct UInt224 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int224 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt224: WordUnsignedInteger {
    public typealias Stride = Sol.Int224
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 224 }
}

extension Sol.UInt224: SolInteger {
    // uses default implementation
}

extension Sol.Int224: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt224
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 224 }
}

extension Sol.Int224: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt232, Sol.Int232

extension Sol {
    public struct UInt232 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int232 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt232: WordUnsignedInteger {
    public typealias Stride = Sol.Int232
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 232 }
}

extension Sol.UInt232: SolInteger {
    // uses default implementation
}

extension Sol.Int232: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt232
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 232 }
}

extension Sol.Int232: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt240, Sol.Int240

extension Sol {
    public struct UInt240 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int240 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt240: WordUnsignedInteger {
    public typealias Stride = Sol.Int240
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 240 }
}

extension Sol.UInt240: SolInteger {
    // uses default implementation
}

extension Sol.Int240: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt240
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 240 }
}

extension Sol.Int240: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt248, Sol.Int248

extension Sol {
    public struct UInt248 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int248 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt248: WordUnsignedInteger {
    public typealias Stride = Sol.Int248
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 248 }
}

extension Sol.UInt248: SolInteger {
    // uses default implementation
}

extension Sol.Int248: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt248
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 248 }
}

extension Sol.Int248: SolInteger {
    // uses default implementation
}

// MARK: - Sol.UInt256, Sol.Int256

extension Sol {
    public struct UInt256 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }

    public struct Int256 {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt256: WordUnsignedInteger {
    public typealias Stride = Sol.Int256
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { 256 }
}

extension Sol.UInt256: SolInteger {
    // uses default implementation
}

extension Sol.Int256: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt256
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { 256 }
}

extension Sol.Int256: SolInteger {
    // uses default implementation
}

