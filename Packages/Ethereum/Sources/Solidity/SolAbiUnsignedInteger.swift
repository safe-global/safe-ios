//
//  SolAbiUnsignedInteger.swift
//  
//
//  Created by Dmitry Bespalov on 22.12.21.
//

import Foundation

protocol SolAbiUnsignedInteger: SolAbiType, UnsignedInteger, FixedWidthInteger, CustomPlaygroundDisplayConvertible {
    static var bitWidth: Int { get }
    var storage: Value { get set }

    associatedtype Value: UnsignedInteger & ExpressibleByIntegerLiteral & Hashable & Comparable
    init()
}

extension SolAbiUnsignedInteger {
    static var isStatic: Bool { true }

    // 6. uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is multiple of 32.
    func encode() -> Data {
        let value = bigEndian
        let bytes = stride(from: 0, to: Self.bitWidth, by: 8).map { bitOffset in
            UInt8((value >> bitOffset) & 0xff)
        }

        let remainderFrom32 = bytes.count % 32
        if remainderFrom32 == 0 {
            return Data(bytes)
        }

        return Data(repeating: 0x00, count: 32 - remainderFrom32) + Data(bytes)
    }
}

extension SolAbi {
    struct UInt256: SolAbiUnsignedInteger {
        static var bitWidth: Int { 256 }
        var storage: BigUInt
        init() {
            storage = .init()
        }
    }

    struct UInt72: SolAbiUnsignedInteger {
        static var bitWidth: Int { 72 }
        var storage: BigUInt
        init() { storage = .init() }
    }
}

import BigInt

extension String {
    init<T>(_ v: T, radix: Int, uppercase: Bool = false) where T: SolAbiUnsignedInteger, T.Value == BigUInt {
        self.init(v.storage, radix: radix, uppercase: uppercase)
    }
}

extension SolAbiUnsignedInteger where Value == BigUInt {

    var words: [Value.Words.Element] {
        let difference = Self.requiredWordCount - storage.words.count
        let words = storage.words + [Words.Element](repeating: Words.Element(0), count: difference)
        return words
    }

    var trailingZeroBitCount: Int {
        // equal to the number of zeros from the beginning plus last such number
        let firstNonZeroWordIndex = words.firstIndex(where: { $0.nonzeroBitCount > 0 }) ?? (words.count - 1)
        let count = words[0...firstNonZeroWordIndex].map { $0.trailingZeroBitCount }.reduce(0, +)
        return count
    }

    var nonzeroBitCount: Int {
        // = to non-zero bits in the store, the difference words are all zeroes.
        let count = words.map { $0.nonzeroBitCount }.reduce(0, +)
        return count
    }

    var leadingZeroBitCount: Int {
        // is equal to leading zeros + all zero word bits
        let lastNonZeroWordIndex = words.lastIndex(where: { $0.nonzeroBitCount > 0 }) ?? 0
        let count = words[lastNonZeroWordIndex..<words.count].map { $0.leadingZeroBitCount }.reduce(0, +)
        return count
    }

    var byteSwapped: Self {
        // swap-reverse all words and then remove the trailing zero bytes
        let swappedWords = words.map { $0.byteSwapped }.reversed()
        var result = BigUInt(words: swappedWords)

        // after swapping there will be trailing zeroes if the bit width is not a factor of word bit width
        // so we remove those zero bytes
        let wordBitWidth: Int = Words.Element.bitWidth
        let remainderBitWidth: Int = Self.bitWidth % wordBitWidth
        if remainderBitWidth > 0 {
            result >>= wordBitWidth - remainderBitWidth
        }

        result &= Self.maxStore
        return Self(store: result)
    }

    static var requiredWordCount: Int {
        1 + (Self.bitWidth - 1) / Words.Element.bitWidth
    }

    var description: String {
        storage.description
    }

    var playgroundDescription: Any {
        storage.playgroundDescription
    }

    init(store: BigUInt) {
        // must always have bitWidth/Word.bitWidth count
        precondition(Self.bitWidth > 0, "Bit width must be positive")
        self.init()
        self.storage = store & Self.maxStore
    }

    init(_truncatingBits bits: UInt) {
        let store = BigUInt(integerLiteral: UInt64(bits))
        self.init(store: store)
    }

    init(integerLiteral value: UInt64) {
        let store = BigUInt(integerLiteral: value)
        self.init(store: store)
    }

    init?<T>(exactly source: T) where T : BinaryInteger {
        guard let store = BigUInt(exactly: source) else { return nil }
        self.init(store: store)
    }

    init<T>(truncatingIfNeeded source: T) where T : BinaryInteger {
        self.init(store: .init(truncatingIfNeeded: source))
    }

    init<T>(_ source: T) where T : BinaryInteger {
        self.init(store: .init(source))
    }

    init<T>(clamping source: T) where T : BinaryInteger {
        self.init(store: .init(clamping: source))
    }

    init?<S>(_ text: S, radix: Int = 10) where S : StringProtocol {
        guard let store = BigUInt(text, radix: radix) else { return nil }
        self.init(store: store)
    }

    func addingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let sum = storage + rhs.storage
        let overflow = sum.bitWidth > Self.bitWidth
        let partialValue = sum & Self.max.storage
        return (Self(store: partialValue), overflow)
    }

    var onesComplement: Self {
        ~self
    }

    var twosComplement: Self {
        ~self &+ 1
    }

    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let difference = Self(store: (storage + rhs.twosComplement.storage) & Self.max.storage)
        let overflow = storage < rhs.storage
        return (difference, overflow)
    }

    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let product = storage * rhs.storage
        let overflow = product.bitWidth > Self.bitWidth
        let partialValue = Self(store: product)
        return (partialValue, overflow)
    }

    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.storage.isZero {
            return (self, true)
        }
        let (quotient, _) = storage.quotientAndRemainder(dividingBy: rhs.storage)
        return (Self(store: quotient), false)
    }

    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.storage.isZero {
            return (self, true)
        }
        let (_, remainder) = storage.quotientAndRemainder(dividingBy: rhs.storage)
        return (Self(store: remainder), false)
    }

    func dividingFullWidth(_ dividend: (high: Self, low: Self)) -> (quotient: Self, remainder: Self) {
        let dividendWords = [Words.Element](dividend.low.words) + dividend.high.words
        let dividendStore = BigUInt(words: dividendWords)
        let (quotient, remainder) = dividendStore.quotientAndRemainder(dividingBy: storage)
        // If the quotient of dividing dividend by this value is too large to represent in the type, a runtime error may occur.
        let overflowQuotient = quotient.bitWidth > bitWidth
        precondition(!overflowQuotient, "Quotient is too large for this type")
        return (Self(store: quotient), Self(store: remainder))
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Multiplication overflow")
        return result
    }

    static func *= (lhs: inout Self, rhs: Self) {
        let result = lhs * rhs
        lhs.storage = result.storage
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow, "Division overflow")
        return result
    }

    static func /= (lhs: inout Self, rhs: Self) {
        let result = lhs / rhs
        lhs.storage = result.storage
    }

    static func % (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        precondition(!overflow, "Modulo overflow")
        return result
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

    static func - (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.subtractingReportingOverflow(rhs)
        precondition(!overflow, "Subtraction overflow")
        return result
    }

    static func + (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        precondition(!overflow, "Addition overflow")
        return result
    }

    prefix static func ~ (x: Self) -> Self {
        let words = x.words.map { ~$0 }
        return Self(store: BigUInt(words: words))
    }

    static func ^ (lhs: Self, rhs: Self) -> Self {
        let words = zip(lhs.words, rhs.words).map { $0 ^ $1 }
        return Self(store: BigUInt(words: words))
    }

    static func & (lhs: Self, rhs: Self) -> Self {
        let words = zip(lhs.words, rhs.words).map { $0 & $1 }
        return Self(store: BigUInt(words: words))
    }

    static func | (lhs: Self, rhs: Self) -> Self {
        let words = zip(lhs.words, rhs.words).map { $0 | $1 }
        return Self(store: BigUInt(words: words))
    }

    static func >> <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        // negative performs left shift using abs(rhs)
        if rhs < 0 {
            return lhs << (0 - rhs)
        }
        // rhs >= bit width is overshift: -1 for negative value, 0 for nonnegative value.
        else if rhs >= Self.bitWidth {
            return 0
        }
        // any other - right shift of lhs.
        else {
            return Self(store: lhs.storage >> rhs)
        }
    }

    static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        let result = lhs >> rhs
        lhs.storage = result.storage
    }

    static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
        // Using a negative value for rhs performs a right shift using abs(rhs).
        if rhs < 0 {
            return lhs >> (0 - rhs)
        }
        // Using a value for rhs that is greater than or equal to the bit width of lhs is an overshift, resulting in zero.
        else if rhs >= Self.bitWidth {
            return 0
        }
        // Using any other value for rhs performs a left shift on lhs by that amount.
        else {
            return Self(store: lhs.storage << rhs)
        }
    }

    static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        let result = lhs << rhs
        lhs.storage = result.storage
    }

    // have to implement it otherwise default implementation hangs forever
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.storage == rhs.storage
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.storage < rhs.storage
    }

    func hash(into hasher: inout Hasher) {
        storage.hash(into: &hasher)
    }

    static var maxStore: BigUInt {
        // normally, this value is BigUInt(2).power(bitWidth) - 1
        // however, that operation is slow: O((exponent * self.count)^log2(3))
        //
        // so we construct the maximum value out of all '0xff' bytes
        // by creating enough words and shifting bits to reduce it to the required bit width
        let words = [Words.Element](repeating: .max, count: requiredWordCount)
        let wordSize = Words.Element.bitWidth
        let maxValue = BigUInt(words: words) >> (requiredWordCount * wordSize - bitWidth)
        return maxValue
    }

    static var max: Self {
        Self(store: maxStore)
    }

    static var min: Self {
        return Self(store: BigUInt.zero)
    }
}
