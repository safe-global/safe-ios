//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 25.12.21.
//

import Foundation
import BigInt

// MARK: - Unsigned Integer

public protocol WordUnsignedInteger: WordInteger, UnsignedInteger, FixedWidthInteger, ExpressibleByStringLiteral where Self.Stride: WordSignedInteger, Self.IntegerLiteralType == UInt {
}

// MARK: Helper
extension WordUnsignedInteger {


    // if not enough words, then they will be sign-extended
    // if more than enough words, then extra will be dropped
    // if exact words but more bit width, then bits will be truncated.
    public init(storage: [UInt]) {
        self.init()
        self.storage = Self.storage(truncating: storage, signed: false)
    }

    public func big() -> BigUInt {
        BigUInt(words: storage)
    }

    var twosComplement: Self {
        ~self &+ 1
    }

    /// truncates the value
    public init(big v: BigUInt) {
        self.init(storage: [UInt](v.words))
    }

    /// nil if it's not representable
    public init?(exactlyBig v: BigUInt) {
        let truncated = Self(big: v)
        if truncated.big() != v {
            return nil
        }
        self = truncated
    }
}

extension WordInteger {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }
}

extension WordUnsignedInteger {
    #warning("truncates")
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(storage: [value])
    }
}

extension WordUnsignedInteger {
    public var description: String {
        return big().description
    }
}

extension WordUnsignedInteger {
    public init(stringLiteral literalValue: String) {
        let v = BigUInt(stringLiteral: literalValue)
        guard let value = Self(exactlyBig: v) else {
            preconditionFailure("The value \(literalValue) is bigger than maximum value")
        }
        self = value
    }

    public init(extendedGraphemeClusterLiteral literalValue: String) {
        let v = BigUInt(extendedGraphemeClusterLiteral: literalValue)
        guard let value = Self(exactlyBig: v) else {
            preconditionFailure("The value \(literalValue) is bigger than maximum value")
        }
        self = value
    }

    public init(unicodeScalarLiteral literalValue: UnicodeScalar) {
        let v = BigUInt(unicodeScalarLiteral: literalValue)
        guard let value = Self(exactlyBig: v) else {
            preconditionFailure("The value \(literalValue) is bigger than maximum value")
        }
        self = value
    }
}

extension WordUnsignedInteger {
    public func hash(into hasher: inout Hasher) {
        words.forEach { hasher.combine($0) }
    }
}

extension WordUnsignedInteger {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.big() < rhs.big()
    }
}

extension WordUnsignedInteger {
    public static func - (lhs: Self, rhs: Self) -> Self {
        let c = lhs.subtractingReportingOverflow(rhs)
        precondition(!c.overflow)
        return c.partialValue
    }

    public static func + (lhs: Self, rhs: Self) -> Self {
        let c = lhs.addingReportingOverflow(rhs)
        precondition(!c.overflow)
        return c.partialValue
    }

    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }
}

// The Strideable protocol provides default implementations for the equal-to (==) and less-than (<) operators that
// depend on the Stride type’s implementations. If a type conforming to Strideable is its own Stride type,
// it must provide concrete implementations of the two operators to avoid infinite recursion.
extension WordUnsignedInteger {
    // If this type’s Stride type conforms to BinaryInteger, then for a value x,
    // a distance n, and a value y = x.advanced(by: n), x.distance(to: y) == n.
    // Using this method with types that have a noninteger Stride may result in an approximation.
    // If the result of advancing by n is not representable as a value of this type, then a runtime error may occur.
    public func advanced(by n: Stride) -> Self {
        let b = Self(storage: n.storage)
        let c = self + b
        return c
    }

    // If this type’s Stride type conforms to BinaryInteger, then for two values x and y, and
    // a distance n = x.distance(to: y), x.advanced(by: n) == y. Using this method with types that have a
    // noninteger Stride may result in an approximation.
    public func distance(to other: Self) -> Stride {
        let minusSelf = twosComplement
        let distance = other + minusSelf
        return Stride(storage: distance.storage)
    }
}

extension WordUnsignedInteger {
    public var magnitude: Self {
        self
    }

    public init?<T>(exactly source: T) where T : BinaryInteger {
        if Self.bitWidth < source.bitWidth {
            return nil
        }
        let truncated = Self(storage: [UInt](source.words))
        guard truncated == source else { return nil }
        self = truncated
    }

    public static func *= (lhs: inout Self, rhs: Self) {
        lhs = lhs * rhs
    }

    public static func * (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow)
        return partialValue
    }

}

extension WordUnsignedInteger {
    public static func %= (lhs: inout Self, rhs: Self) {
        lhs = lhs % rhs
    }

    public static func /= (lhs: inout Self, rhs: Self) {
        lhs = lhs / rhs
    }

    public static func / (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow)
        return partialValue
    }

    public static func % (lhs: Self, rhs: Self) -> Self {
        let (partialValue, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        precondition(!overflow)
        return partialValue
    }

    public static func &= (lhs: inout Self, rhs: Self) {
        lhs.storage = zip(lhs.storage, rhs.storage).map(&)
    }

    public static func |= (lhs: inout Self, rhs: Self) {
        lhs.storage = zip(lhs.storage, rhs.storage).map(|)
    }

    public static func ^= (lhs: inout Self, rhs: Self) {
        lhs.storage = zip(lhs.storage, rhs.storage).map(^)
    }

    // implemented, otherwise infinite recursion
    public static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let a = lhs.big()
        let b = a << rhs
        return Self(big: b)
    }

    // implemented, otherwise infinite recursion
    public static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs = lhs << rhs
    }

    // implemented, otherwise infinite recursion
    public static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        let a = lhs.big()
        let b = a >> rhs
        return Self(big: b)
    }

    // implemented, otherwise infinite recursion
    public static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        lhs = lhs >> rhs
    }

    public var words: [UInt] {
        storage
    }

    public var trailingZeroBitCount: Int {
        var count = 0
        for (i, word) in storage.enumerated() {
            count += word.trailingZeroBitCount
            if i == storage.count - 1 && word.nonzeroBitCount == 0 {
                count -= storage.count * Words.Element.bitWidth - Self.bitWidth
            }
            if word.nonzeroBitCount != 0 {
                break
            }
        }
        return count
    }
}

extension WordUnsignedInteger {
    public prefix static func ~ (x: Self) -> Self {
        Self(storage: x.storage.map(~))
    }
}

extension WordUnsignedInteger {
    public func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let c = big() + rhs.big()
        let overflow = c.bitWidth > Self.bitWidth
        let partialValue = Self(big: c)
        return (partialValue, overflow)
    }

    public func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let a = big()
        let b = rhs.big()
        let minusB = rhs.twosComplement.big()
        let c = a + minusB
        let partialValue = Self(big: c)
        let overflow = a < b
        return (partialValue, overflow)
    }

    public func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let a = big()
        let b = rhs.big()
        let c = a * b
        let overflow = c.bitWidth > Self.bitWidth
        let partialValue = Self(big: c)
        return (partialValue, overflow)
    }

    public func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs == 0 {
            return (self, true)
        }
        let a = big()
        let b = rhs.big()
        let (c, _) = a.quotientAndRemainder(dividingBy: b)
        let partialValue = Self(big: c)
        return (partialValue, false)
    }

    public func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs == 0 {
            return (self, true)
        }
        let a = big()
        let b = rhs.big()
        let (_, c) = a.quotientAndRemainder(dividingBy: b)
        let partialValue = Self(big: c)
        return (partialValue, false)
    }

    public func dividingFullWidth(_ dividend: (high: Self, low: Self)) -> (quotient: Self, remainder: Self) {
        // we must merge words in case the bitWidth is not aligned to word size.
        // we can't use the 'low' directly because the result of merge
        // will overflow the Self.
        var low = dividend.low.storage
        var high = dividend.high
        let bitRemainder = Self.bitWidth % Words.Element.bitWidth
        if bitRemainder > 0 {
            // merge least significant portion of high with most significant
            // portion of low
            low[low.count - 1] |= high.storage[0] << bitRemainder
            // then remove the merged part from high
            high >>= bitRemainder
        }
        let a = BigUInt(words: low + high.storage)
        let b = big()
        let (q, r) = a.quotientAndRemainder(dividingBy: b)
        let overflow = q.bitWidth > Self.bitWidth
        precondition(!overflow)
        let result = (Self(big: q), Self(big: r))
        return result
    }

    public var nonzeroBitCount: Int {
        // equal to each word's nonzerobitcount
        storage.map(\.nonzeroBitCount).reduce(0, +)
    }

    public var leadingZeroBitCount: Int {
        var count = 0
        for (i, word) in storage.reversed().enumerated() {
            count += word.leadingZeroBitCount
            if i == 0 { // is last word
                count -= storage.count * Words.Element.bitWidth - Self.bitWidth
            }
            if word.nonzeroBitCount != 0 {
                break
            }
        }
        return count
    }

    public var byteSwapped: Self {
        var result: Self = 0
        for offset in stride(from: 0, to: Self.bitWidth, by: 8) {
            result |= ((self >> offset) & 0xff) << (Self.bitWidth - 8 - offset)
        }
        return result
    }

    public init(_truncatingBits value: UInt) {
        self.init(storage: [value])
    }
}

// initializers implemented because Swift's default implementation goes into infinite loop
extension WordUnsignedInteger {
    public init?<S: StringProtocol>(_ text: S, radix: Int = 10) {
        guard let big = BigUInt(text, radix: radix) else { return nil }
        self.init(exactlyBig: big)
    }

    public init<T: BinaryInteger>(truncatingIfNeeded source: T) {
        self.init(storage: [UInt](source.words))
    }
}
