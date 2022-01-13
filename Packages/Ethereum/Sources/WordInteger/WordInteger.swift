//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 13.01.22.
//

import Foundation

public protocol WordInteger {
    static var bitWidth: Int { get }
    var storage: [UInt] { get set }
    init()
    init(storage: [UInt])
}

extension WordInteger {
    static func storage(truncating storage: [UInt], signed: Bool) -> [UInt] {
        let wordCount = (Self.bitWidth - 1) / UInt.bitWidth + 1

        precondition(wordCount > 0)
        var result: [UInt]

        if storage.count == wordCount {
            result = storage
        } else if storage.count < wordCount {
            // extend to words
            let difference = wordCount - storage.count

            let signExtension: UInt
            // negative integers are in 2's complement, so we extend sign bit
            if signed && !storage.isEmpty {
                let isNegative = storage[storage.count - 1].leadingZeroBitCount == 0
                signExtension = isNegative ? .max : 0
            } else {
                signExtension = 0
            }

            let padding = [UInt](repeating: signExtension, count: difference)

            result = storage + padding
        } else {
            // more than enough words: truncate words
            result = Array(storage[0..<wordCount])
        }

        // truncate to bitWidth
        var bitMask = [UInt](repeating: .max, count: wordCount)
        bitMask[wordCount - 1] >>= wordCount * UInt.bitWidth - Self.bitWidth

        result = zip(result, bitMask).map(&)

        return result
    }

}
