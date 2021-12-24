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
}

// 2's complement negative numbers.
extension SolAbiSignedInteger where
    Value: SolAbiUnsignedInteger,
    Value.Value == BigUInt,
    Magnitude == Value,
    IntegerLiteralType == Int64
{

    var words: [Value.Words.Element] {
        // must have enough words to fit bitWidth
        // but BigInt/UInt have minimum words to fit the number
        // so we must add more if needed

        // since we've implemented enough words in the UnsignedInteger
        // and we're using it as a storage
        // then we just return it as a result.
        storage.words
    }

    var nonzeroBitCount: Int {
        storage.nonzeroBitCount
    }

    var leadingZeroBitCount: Int {
        storage.leadingZeroBitCount
    }
    var trailingZeroBitCount: Int {
        storage.trailingZeroBitCount
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

    init(integerLiteral value: IntegerLiteralType) {
        self.init(storage: .init(integerLiteral: UInt64(bitPattern: value)))
    }

    init(_truncatingBits: UInt) {
        self.init(storage: .init(_truncatingBits: _truncatingBits))
    }

    func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        // so if both same sign but sign flips then it is overflow
        // or if the overflow bit is set
        let sum = storage.addingReportingOverflow(rhs.storage)
        let partialValue = Self(storage: sum.partialValue)
        let signFlipped = self.signum() == rhs.signum() &&
            self.signum() != 0 &&
            partialValue.signum() != self.signum()

        let overflow = sum.overflow || signFlipped
        return (partialValue, overflow)
    }

    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        // overflow if the overflow bit is set or if signs were different and the sign flipped.
        let difference = storage.subtractingReportingOverflow(rhs.storage)
        let partialValue = Self(storage: difference.partialValue)
        let signFlipped = self.signum() != 0 &&
            self.signum() != rhs.signum() &&
            partialValue.signum() != self.signum()
        let overflow = difference.overflow || signFlipped
        return (partialValue, overflow)
    }

    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        fatalError()
    }

    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        fatalError()
    }

    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        fatalError()
    }

    func dividingFullWidth(_ dividend: (high: Self, low: Magnitude)) -> (quotient: Self, remainder: Self) {
        fatalError()
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    static func % (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    static func /= (lhs: inout Self, rhs: Self) {
        fatalError()
    }

    static func %= (lhs: inout Self, rhs: Self) {
        fatalError()
    }

    static func *= (lhs: inout Self, rhs: Self) {
        fatalError()
    }

    static func &= (lhs: inout Self, rhs: Self) {
        fatalError()
    }

    static func |= (lhs: inout Self, rhs: Self) {
        fatalError()
    }

    static func ^= (lhs: inout Self, rhs: Self) {
        fatalError()
    }

    // these are implemented because otherwise the oper operations are slow

    static func | (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    static func & (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    static func ^ (lhs: Self, rhs: Self) -> Self {
        fatalError()
    }

    prefix static func ~ (x: Self) -> Self {
        fatalError()
    }

    static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        fatalError()
    }

    static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        fatalError()
    }

    static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        fatalError()
    }

    static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        fatalError()
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        fatalError()
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        fatalError()
    }
}
