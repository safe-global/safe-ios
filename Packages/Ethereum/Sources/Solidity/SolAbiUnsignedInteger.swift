//
//  SolAbiUnsignedInteger.swift
//  
//
//  Created by Dmitry Bespalov on 22.12.21.
//

import Foundation

protocol SolAbiUnsignedInteger: SolAbiType, UnsignedInteger, FixedWidthInteger, CustomPlaygroundDisplayConvertible {
    static var bitWidth: Int { get }
    var store: Value { get set }

    // must be at least bitWidth long!
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

        let remainder32 = bytes.count % 32
        if remainder32 == 0 {
            return Data(bytes)
        }

        return Data(repeating: 0x00, count: 32 - remainder32) + Data(bytes)
    }
}

extension SolAbi {
    struct UInt256: SolAbiUnsignedInteger {
        static var bitWidth: Int { 256 }
        var store: BigUInt
        init() {
            store = .init()
        }
    }

    struct UInt72: SolAbiUnsignedInteger {
        static var bitWidth: Int { 72 }
        var store: BigUInt
        init() { store = .init() }
    }
}

// encode uint256

import BigInt

// the store must always have bitWidth / Word words.

extension String {
    init<T>(_ v: T, radix: Int, uppercase: Bool = false) where T: SolAbiUnsignedInteger, T.Value == BigUInt {
        self.init(v.store, radix: radix, uppercase: uppercase)
    }
}

extension SolAbiUnsignedInteger where Value == BigUInt {

    var words: [Value.Words.Element] {
        let difference = Self.requiredWordCount - store.words.count
        let words = store.words + [Words.Element](repeating: Words.Element(0), count: difference)
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
        // from end to beginning, while words are zero, sum it up
        // then, stop at the first non-zero word.

        // last index of word with at least one nonzero
        // leading zeros = all most signinficant zeros.

        // is equal to leading zeros + all zero word bits
        let lastNonZeroWordIndex = words.lastIndex(where: { $0.nonzeroBitCount > 0 }) ?? 0
        let count = words[lastNonZeroWordIndex..<words.count].map { $0.leadingZeroBitCount }.reduce(0, +)
        return count
    }

    var byteSwapped: Self {
        let wordSize: Int = Words.Element.bitWidth
        let remainder: Int = Self.bitWidth % wordSize
        if remainder == 0 {
            let swappedWords = store.words.map { word in word.byteSwapped }.reversed()
            return Self(store: BigUInt(words: swappedWords))
        } else {
            // swap-reverse all full words
            // then rotate the remainder 

            var swappedWords = store.words.map { $0.byteSwapped }
            // remove the trailing zero bytes from the highest word
            swappedWords[swappedWords.count - 1] >>= wordSize - remainder
            var result = BigUInt(words: swappedWords)
            // rotate the remainder to the left
            result = (result << remainder) | (result >> (Self.bitWidth - remainder))
            return Self(store: result)
        }
    }

    static var requiredWordCount: Int {
        1 + (Self.bitWidth - 1) / Words.Element.bitWidth
    }

    var description: String {
        store.description
    }

    var playgroundDescription: Any {
        store.playgroundDescription
    }

    init(store: BigUInt) {
        // must always have bitWidth/Word.bitWidth count
        precondition(Self.bitWidth > 0, "Bit width must be positive")
        self.init()
        self.store = store & Self.maxStore
    }

    init(_truncatingBits bits: UInt) {
        // TODO: for low bitwidth!
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
        let sum = store + rhs.store
        let overflow = sum.bitWidth > Self.bitWidth
        let partialValue = sum & Self.max.store
        return (Self(store: partialValue), overflow)
    }

    var onesComplement: Self {
        ~self
    }

    var twosComplement: Self {
        ~self &+ 1
    }

    func subtractingReportingOverflow(_ rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let difference = Self(store: (store + rhs.twosComplement.store) & Self.max.store)
        let overflow = store < rhs.store
        return (difference, overflow)
    }

    func multipliedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        let product = store * rhs.store
        let overflow = product.bitWidth > Self.bitWidth
        let partialValue = Self(store: product)
        return (partialValue, overflow)
    }

    func dividedReportingOverflow(by rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.store.isZero {
            return (self, true)
        }
        let (quotient, _) = store.quotientAndRemainder(dividingBy: rhs.store)
        return (Self(store: quotient), false)
    }

    func remainderReportingOverflow(dividingBy rhs: Self) -> (partialValue: Self, overflow: Bool) {
        if rhs.store.isZero {
            return (self, true)
        }
        let (_, remainder) = store.quotientAndRemainder(dividingBy: rhs.store)
        return (Self(store: remainder), false)
    }

    func dividingFullWidth(_ dividend: (high: Self, low: Self)) -> (quotient: Self, remainder: Self) {
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

        return (Self(store: quotient), Self(store: remainder))
    }

    static func * (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.multipliedReportingOverflow(by: rhs)
        precondition(!overflow, "Multiplication overflow")
        return result
    }

    static func *= (lhs: inout Self, rhs: Self) {
        let result = lhs * rhs
        lhs.store = result.store
    }

    static func / (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.dividedReportingOverflow(by: rhs)
        precondition(!overflow, "Division overflow")
        return result
    }

    static func /= (lhs: inout Self, rhs: Self) {
        let result = lhs / rhs
        lhs.store = result.store
    }

    static func % (lhs: Self, rhs: Self) -> Self {
        let (result, overflow) = lhs.remainderReportingOverflow(dividingBy: rhs)
        precondition(!overflow, "Modulo overflow")
        return result
    }

    static func %= (lhs: inout Self, rhs: Self) {
        let result = lhs % rhs
        lhs.store = result.store
    }

    static func &= (lhs: inout Self, rhs: Self) {
        let result = lhs & rhs
        lhs.store = result.store
    }

    static func |= (lhs: inout Self, rhs: Self) {
        let result = lhs | rhs
        lhs.store = result.store
    }

    static func ^= (lhs: inout Self, rhs: Self) {
        let result = lhs ^ rhs
        lhs.store = result.store
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
            return Self(store: lhs.store >> rhs)
        }
    }

    static func >>= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        let result = lhs >> rhs
        lhs.store = result.store
    }

    static func << <RHS>(lhs: Self, rhs: RHS) -> Self where RHS : BinaryInteger {
//        Using a negative value for rhs performs a right shift using abs(rhs).
        if rhs < 0 {
            return lhs >> (0 - rhs)
        }
//        Using a value for rhs that is greater than or equal to the bit width of lhs is an overshift, resulting in zero.
        else if rhs >= Self.bitWidth {
            return 0
        }
        //        Using any other value for rhs performs a left shift on lhs by that amount.
        else {
            return Self(store: lhs.store << rhs)
        }
    }

    static func <<= <RHS>(lhs: inout Self, rhs: RHS) where RHS : BinaryInteger {
        let result = lhs << rhs
        lhs.store = result.store
    }

    // have to implement it otherwise default implementation hangs forever
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.store == rhs.store
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.store < rhs.store
    }

    func hash(into hasher: inout Hasher) {
        store.hash(into: &hasher)
    }


    static var maxStore: BigUInt {
        // normally, this value is BigUInt(2).power(bitWidth) - 1
        // however, that operation is slow: O((exponent * self.count)^log2(3))
        // The code below is an optimization.
        //
        // Maximum possible value = bitWidth x 1's
        // We need to account for words, so we need to deal with
        // the case when bitWidth can be divided fully by the word size
        // and with the remainder case.

        // when bitWidth % word size == 0, then all words are of 1's
        let wordSize = Words.Element.bitWidth
        if bitWidth % wordSize == 0 {
            let words = (0..<requiredWordCount).map { _ in Words.Element.max }
            return BigUInt(words: words)
        }
        else {
            // then bitWidth / wordsize words are of 1's
            // and the last one is max value (all 1's) shifted right to the wordsize - remainder
            // so that only remainder x 1's are left.
            let mostWords = (0..<bitWidth / wordSize).map { _ in Words.Element.max }
            let lastWord = Words.Element.max >> (wordSize - bitWidth % wordSize)
            return BigUInt(words: mostWords + [lastWord])
        }
    }

    static var max: Self {
        Self(store: maxStore)
    }

    static var min: Self {
        return Self(store: BigUInt.zero)
    }
}
