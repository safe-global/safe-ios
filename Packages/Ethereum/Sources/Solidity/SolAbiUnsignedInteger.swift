//
//  SolAbiUnsignedInteger.swift
//  
//
//  Created by Dmitry Bespalov on 22.12.21.
//

import Foundation

protocol SolAbiUnsignedInteger: SolAbiType, UnsignedInteger, FixedWidthInteger {
    static var bitWidth: Int { get }
    var store: Value { get }

    // must be at least bitWidth long!
    associatedtype Value: UnsignedInteger
}

extension SolAbiUnsignedInteger {
    static var isStatic: Bool { true }

    // 6. uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is multiple of 32.
    func encode() -> Data {
        // serialize
        // assert is max 32 bytes!
        // pad_left with 0x00 to 32-byte multiple
        // alternative: implement the data serialization based on binary integer interface, i.e. byte shifting and masking.

        // endianness - big endian
        fatalError()
    }
}

extension SolAbi {
    struct UInt256 {
        init(_ value: Int) {}
    }
}
// encode uint256
extension SolAbi.UInt256: SolAbiType {

    func encode() -> Data {
        // 0 < M <= 256, M % 8 == 0, i.e. max is uint256, i.e. 32 bytes already.
        fatalError()
    }

    static var isStatic: Bool { true }
}

extension SolAbiUnsignedInteger {

}

import BigInt

// the store must always have bitWidth / Word words.

struct UInt256: SolAbiUnsignedInteger {
    init(_truncatingBits bits: UInt) {
        store = .init(truncatingIfNeeded: UInt64(bits))
    }

    init(integerLiteral value: UInt64) {
        store = .init(integerLiteral: value)
    }

    var words: BigUInt.Words {
        store.words
    }

    var trailingZeroBitCount: Int {
        store.trailingZeroBitCount
    }

    var nonzeroBitCount: Int {
        // = to non-zero bits in the store, the difference words are all zeroes.
        (0..<store.bitWidth).map { store[bitAt: $0] ? 1 : 0 }.reduce(0, +)
    }

    var leadingZeroBitCount: Int {
        store.leadingZeroBitCount
    }

    var store: BigUInt

    init(store: BigUInt) {
        // must always have bitWidth/Word.bitWidth count
        precondition(Self.bitWidth > 0, "Bit width must be positive")

        // round up // Self.bitWidth / Words.Element.bitWidth
        let requiredWordCount = 1 + (Self.bitWidth - 1) / Words.Element.bitWidth

        if store.words.count == requiredWordCount {
            self.store = store
        } else if store.words.count < requiredWordCount {
            let difference = requiredWordCount - store.words.count
            let words = store.words + [Words.Element](repeating: Words.Element(0), count: difference)
            self.store = BigUInt(words: words)
        } else {
            // else store.words.count > requiredWordCount
            let difference = store.words.count - requiredWordCount
            self.store = BigUInt(words: store.words.dropLast(difference))
        }
    }

    static var bitWidth: Int { 256 }

    func addingReportingOverflow(_ rhs: UInt256) -> (partialValue: UInt256, overflow: Bool) {
        let sum = store + rhs.store
        let overflow = sum.bitWidth > bitWidth
        let partialValue = sum / magnitude.store
        return (UInt256(store: partialValue), overflow)
    }

    func subtractingReportingOverflow(_ rhs: UInt256) -> (partialValue: UInt256, overflow: Bool) {
        let difference = store.subtractingReportingOverflow(rhs.store)
        return (UInt256(store: difference.partialValue), difference.overflow)
    }

    func multipliedReportingOverflow(by rhs: UInt256) -> (partialValue: UInt256, overflow: Bool) {
        let product = store * rhs.store
        let overflow = product.bitWidth > bitWidth
        let partialValue = product / magnitude.store
        return (UInt256(store: partialValue), overflow)
    }

    func dividedReportingOverflow(by rhs: UInt256) -> (partialValue: UInt256, overflow: Bool) {
//        let (quotient, remainder) = store.quotientAndRemainder(dividingBy: rhs.store)
        // self = dividend,
        // rhs = divisor
        // self / rhs = (quotient, remainder)
        // if rhs > self, then quotient is 0, remainder is not zero
        // if rhs is << self, then quotient may be very large!

//        A tuple containing the result of the division along with a Boolean value indicating whether overflow occurred. If the overflow component is false, the partialValue component contains the entire quotient. If the overflow component is true, an overflow occurred and the partialValue component contains either the truncated quotient or, if the quotient is undefined, the dividend.
//        Discussion
//
//        Dividing by zero is not an error when using this method. For a value x, the result of x.dividedReportingOverflow(by: 0) is (x, true).
        if rhs.store.isZero {
            return (self, true)
        }

        let (quotient, _) = store.quotientAndRemainder(dividingBy: rhs.store)

        return (UInt256(store: quotient), false)
    }

    func remainderReportingOverflow(dividingBy rhs: UInt256) -> (partialValue: UInt256, overflow: Bool) {
        if rhs.store.isZero {
            return (self, true)
        }
        let (_, remainder) = store.quotientAndRemainder(dividingBy: rhs.store)
        return (UInt256(store: remainder), false)
    }

    func dividingFullWidth(_ dividend: (high: UInt256, low: UInt256)) -> (quotient: UInt256, remainder: UInt256) {
//        let (quotient, remainder) = store.quotientAndRemainder(dividingBy: rhs.store)
//        let dividend = dividend.high.store + dividend.low.store
        // low.words + high.words --> double-width
        let dividendWords = [Words.Element](dividend.low.words) + dividend.high.words
        let dividendStore = BigUInt(words: dividendWords)

        // dividend = double width
        // divisor = self

        // if double width / 1 then result is double width!
        // the remainder is 0

        // this will never overflow
        // remainder is within the size of the dividend
        // so it can be bigger than this type
        let (quotient, remainder) = dividendStore.quotientAndRemainder(dividingBy: store)

        // If the quotient of dividing dividend by this value is too large to represent in the type, a runtime error may occur.
        let overflowQuotient = quotient.bitWidth > bitWidth
        precondition(!overflowQuotient, "Quotient is too large for this type")
        // remainder is always less than the divisor

        return (UInt256(store: quotient), UInt256(store: remainder))
    }

    var byteSwapped: UInt256 {
        // (012 345 678) -> (210 543 876) -> (876 543 210)
        let swappedWords = store.words.map { word in word.byteSwapped }.reversed()
        return UInt256(store: BigUInt(words: swappedWords))
    }

    static func * (lhs: UInt256, rhs: UInt256) -> UInt256 {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Multiplication overflow")
        return result
    }

    static func *= (lhs: inout UInt256, rhs: UInt256) {
        let result = lhs * rhs
        lhs.store = result.store
    }

    static func / (lhs: UInt256, rhs: UInt256) -> UInt256 {
        let (result, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow, "Division overflow")
        return result
    }

    static func /= (lhs: inout UInt256, rhs: UInt256) {
        let result = lhs / rhs
        lhs.store = result.store
    }

    static func % (lhs: UInt256, rhs: UInt256) -> UInt256 {
        let (result, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        precondition(!overflow, "Modulo overflow")
        return result
    }

    static func %= (lhs: inout UInt256, rhs: UInt256) {
        let result = lhs % rhs
        lhs.store = result.store
    }

    static func &= (lhs: inout UInt256, rhs: UInt256) {
        let result = lhs.store & rhs.store
        lhs.store = result
    }

    static func |= (lhs: inout UInt256, rhs: UInt256) {
        let result = lhs.store | rhs.store
        lhs.store = result
    }

    static func ^= (lhs: inout UInt256, rhs: UInt256) {
        let result = lhs.store ^ rhs.store
        lhs.store = result
    }

    static func - (lhs: UInt256, rhs: UInt256) -> UInt256 {
        let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "Subtraction overflow")
        return result
    }

    static func + (lhs: UInt256, rhs: UInt256) -> UInt256 {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "Addition overflow")
        return result
    }
}
