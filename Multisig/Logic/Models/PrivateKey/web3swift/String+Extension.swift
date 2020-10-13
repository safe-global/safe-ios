//
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

// https://github.com/matter-labs/web3swift

extension Array {
    public func split(intoChunksOf chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            let endIndex = ($0.advanced(by: chunkSize) > self.count) ? self.count - $0 : chunkSize
            return Array(self[$0..<$0.advanced(by: endIndex)])
        }
    }
}

extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }

    func split(intoChunksOf chunkSize: Int) -> [String] {
        var output = [String]()
        let splittedString = self
            .map { $0 }
            .split(intoChunksOf: chunkSize)
        splittedString.forEach {
            output.append($0.map { String($0) }.joined(separator: ""))
        }
        return output
    }

    func interpretAsBinaryData() -> Data? {
        let padded = self.padding(toLength: ((self.count + 7) / 8) * 8, withPad: "0", startingAt: 0)
        let byteArray = padded.split(intoChunksOf: 8).map { UInt8(strtoul($0, nil, 2)) }
        return Data(byteArray)
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(self.startIndex, offsetBy: bounds.lowerBound)
        let end = index(self.startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    func stripHexPrefix() -> String {
        if self.hasPrefix("0x") {
            let indexStart = self.index(self.startIndex, offsetBy: 2)
            return String(self[indexStart...])
        }
        return self
    }

    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: NSCharacterSet.whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}
