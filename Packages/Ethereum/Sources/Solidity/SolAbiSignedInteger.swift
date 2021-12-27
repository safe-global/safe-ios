//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 23.12.21.
//

import Foundation
import BigInt

protocol SolAbiSignedInteger: SignedInteger, FixedWidthInteger {
    static var bitWidth: Int { get }
    var storage: Value { get set }
    init()
    associatedtype Value: UnsignedInteger & FixedWidthInteger & ExpressibleByIntegerLiteral & Hashable & Comparable
}

extension SolAbi {
    struct Int256 {
        static var bitWidth: Int { 256 }
        var storage: SolAbi.UInt256
        init() {
            storage = .init()
        }
    }
}

extension SolAbi.Int256: SolAbiSignedInteger {
    typealias IntegerLiteralType = Int64
}

extension SolAbiSignedInteger {
    init(storage: Value) {
        self.init()
        self.storage = storage
    }

    static func isSameSignOverflow(x: Self, y: Self, z: Self) -> Bool {
        let argumentsHaveSameSign = x.signum() != 0 && x.signum() == y.signum()
        let signFlipped = x.signum() != z.signum()
        let overflow = argumentsHaveSameSign && signFlipped
        return overflow
    }

}

// 2's complement negative numbers.
extension SolAbiSignedInteger where
    Value: SolAbiUnsignedInteger,
    Value.Value == BigUInt,
    Magnitude == Value,
    IntegerLiteralType == Int64
{
    var isNegative: Bool {
        ((storage.storage.words.last ?? 0) >> (UInt.bitWidth - 1)) == 1
    }

    var words: [Value.Words.Element] {
        Self.words(of: storage.storage)
    }

    var nonzeroBitCount: Int {
        words.map { $0.nonzeroBitCount }.reduce(0, +)
    }

    var leadingZeroBitCount: Int {
        let firstNonZeroIndex = words.reversed().firstIndex(where: { $0.nonzeroBitCount > 0 }) ?? 0
        return words.reversed()[0...firstNonZeroIndex].map { $0.leadingZeroBitCount }.reduce(0, +)
    }

    var trailingZeroBitCount: Int {
        let lastNonZeroIndex = words.firstIndex(where: { $0.nonzeroBitCount > 0 }) ?? 0
        return words[0...lastNonZeroIndex].map { $0.trailingZeroBitCount }.reduce(0, +)
    }

    var byteSwapped: Self {
        Self(storage: storage.byteSwapped)
    }

    var magnitude: Magnitude {
        storage
    }

    // 2^(n-1) - 1
    static var max: Self {
        // the max signed integer looks like
        // 0x7fffff....ffff which is 0b0111_1111_...
        // so we just get 2^n - 1 and shift it right 1 bit
        Self(storage: Value.max >> 1)
    }

    // - 2^(n-1)
    static var min: Self {
        // min signed integer is 0b1000_000... = 0x8000_...
        // which is 1 << bitWidth - 1
        Self(storage: Value(1) << (bitWidth - 1))
    }

    init(integerLiteral value: Int64) {
        // sign-extend to 256 bits
        let v = BigUInt(integerLiteral: UInt64(bitPattern: value))
        let storage = BigUInt(words: Self.words(of: v))
        self.init(storage: Value(store: storage))
    }

    // init because otherwise program hangs

    init?<S>(_ text: S, radix: Int = 10) where S : StringProtocol {
        guard let value = BigInt(text, radix: radix) else { return nil }

        // negative = magnitude to 2's complement
        let storage = Value(store: value.magnitude)

        self.init(storage: value.sign == .minus ? storage.twosComplement : storage)
    }

    init?(_ description: String) {
        self.init(description, radix: 10)
    }

    var description: String {
        let magnitude = isNegative ? storage.twosComplement.storage : storage.storage
        let value = BigInt(sign: isNegative ? .minus : .plus, magnitude: magnitude)
        return value.description
    }

    init(_truncatingBits: UInt) {
        let v = BigUInt(integerLiteral: UInt64(_truncatingBits))
        let storage = BigUInt(words: Self.words(of: v))
        self.init(storage: Value(store: storage))
    }

    static func words(of v: BigUInt) -> [UInt] {
        let storedWords = v.words
        let isNegative = ((v.words.last ?? 0) >> (UInt.bitWidth - 1)) == 1
        let difference = Value.requiredWordCount - storedWords.count
        let words = storedWords + [Words.Element](repeating: isNegative ? .max : .min, count: difference)
        return words
    }

    func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        // so if both same sign but sign flips then it is overflow
        // or if the overflow bit is set
        let sum = storage.addingReportingOverflow(rhs.storage)
        let partialValue = Self(storage: sum.partialValue)
        let signFlipped = Self.isSameSignOverflow(x: self, y: rhs, z: partialValue)
        let overflow = sum.overflow || signFlipped
        return (partialValue, overflow)
    }

    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        // overflow if the overflow bit is set or if signs were different and the sign flipped.
        let difference = storage.subtractingReportingOverflow(rhs.storage)
        let partialValue = Self(storage: difference.partialValue)
        let signFlipped = Self.isSameSignOverflow(x: self, y: -rhs, z: partialValue)
        let overflow = difference.overflow || signFlipped
        return (partialValue, overflow)
    }

    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let product = storage.multipliedReportingOverflow(by: rhs.storage)
        let partialValue = Self(storage: product.partialValue)
        let overflow = Self.isSameSignOverflow(x: self, y: rhs, z: partialValue)
        return (partialValue, overflow)
    }

    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.storage.storage.isZero {
            return (self, true)
        }
        let (quotient, _) = storage.quotientAndRemainder(dividingBy: rhs.storage)
        return (Self(storage: quotient), false)
    }

    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.storage.storage.isZero {
            return (self, true)
        }
        let (_, remainder) = storage.quotientAndRemainder(dividingBy: rhs.storage)
        return (Self(storage: remainder), false)
    }

    func dividingFullWidth(_ dividend: (high: Self, low: Magnitude)) -> (quotient: Self, remainder: Self) {
        let result = storage.dividingFullWidth((dividend.high.storage, dividend.low))
        let (quotient, remainder) = (Self(storage: result.quotient), Self(storage: result.remainder))

        precondition(!Self.isSameSignOverflow(x: dividend.high, y: self, z: quotient),
                     "Quotient is too large for this type")

        return (quotient, remainder)
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "Addition overflow")
        return result
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "Subtraction overflow")
        return result
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Multiplication overflow")
        return result
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow, "Division overflow")
        return result
    }

    static func % (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        precondition(!overflow, "Modulo overflow")
        return result
    }

    static func *= (lhs: inout Self, rhs: Self) {
        let result = lhs * rhs
        lhs.storage = result.storage
    }

    static func /= (lhs: inout Self, rhs: Self) {
        let result = lhs / rhs
        lhs.storage = result.storage
    }

    static func %= (lhs: inout Self, rhs: Self) {
        let result = lhs % rhs
        lhs.storage = result.storage
    }

    static func &= (lhs: inout Self, rhs: Self) {
        let result = lhs & rhs
        lhs.storage = result.storage
    }

    static func |= (lhs: inout Self, rhs: Self) {
        let result = lhs | rhs
        lhs.storage = result.storage
    }

    static func ^= (lhs: inout Self, rhs: Self) {
        let result = lhs ^ rhs
        lhs.storage = result.storage
    }

    // these are implemented because otherwise the operations are slow

    prefix static func ~ (x: Self) -> Self {
        Self(storage: ~x.storage)
    }

    static func & (lhs: Self, rhs: Self) -> Self {
        Self(storage: lhs.storage & rhs.storage)
    }

    static func | (lhs: Self, rhs: Self) -> Self {
        Self(storage: lhs.storage | rhs.storage)
    }

    static func ^ (lhs: Self, rhs: Self) -> Self {
        Self(storage: lhs.storage ^ rhs.storage)
    }

    static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        Self(storage: lhs.storage << rhs)
    }

    static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        Self(storage: lhs.storage >> rhs)
    }

    static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        let result = lhs << rhs
        lhs.storage = result.storage
    }

    static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        let result = lhs >> rhs
        lhs.storage = result.storage
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs.isNegative, rhs.isNegative) {
        // both negative or both non-positive
        case (true, true), (false, false):
            return lhs.storage < rhs.storage
        // lhs non-negative and rhs negative
        case (false, true):
            return false
        // lhs negative, rhs non-negative
        case (true, false):
            return true
        }
    }

    func signum() -> Self {
        if nonzeroBitCount == 0 {
            return 0
        }
        else if leadingZeroBitCount == 0 {
            return -1
        } else {
            return 1
        }
    }
}
