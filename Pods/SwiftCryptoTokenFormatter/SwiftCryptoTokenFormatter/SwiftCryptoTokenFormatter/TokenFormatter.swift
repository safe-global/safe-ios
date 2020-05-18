//
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt

/// Formats numbers to and from string representations.
public class TokenFormatter {
    public static let defaultLocalizedLiterals = (millions: NSLocalizedString("amount_millions", comment: "M"),
                                                  billions: NSLocalizedString("amount_billions", comment: "B"),
                                                  trillions: NSLocalizedString("amount_trillions", comment: "T"))
    public static let defaultLiterals = (millions: "M", billions: "B", trillions: "T")
    public static let decimalSeparators = ".,٫"

    public var roundingBehavior = RoundingBehavior.cutoff

    public enum RoundingBehavior {
        case cutoff
        case roundUp
    }

    public init() {}

    /// Converts string to a BigDecimal with a known precision.
    ///
    /// Stringified number can contain whitespaces in the middle or at both ends, newlines at both ends.
    ///
    /// The default decimal separators are '.,٫'. If more than one separator is in the middle of the number,
    /// then only the last one is used as such.
    ///
    /// Empty strings are treated as zero.
    ///
    /// Invalid numbers result in nil conversion.
    ///
    /// - Parameters:
    ///   - input: Stringified decimal number
    ///   - precision: Precision of the resulting decimal number
    ///   - decimalSeparators: String with possible decimal separators to look for
    /// - Returns: number parsed from the input, or nil if the input was not a number.
    public func number(from input: String,
                       precision: Int,
                       decimalSeparators: String = TokenFormatter.decimalSeparators) -> BigDecimal? {
        let string = input.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
        if string == "0" { return .zero(precision) }
        var parts = string.components(separatedBy: CharacterSet(charactersIn: decimalSeparators))
        if parts.isEmpty { return .zero(precision) }
        if parts.count == 1 { parts.append("0") }
        if parts.count > 2 { parts = [parts[0..<parts.count - 1].joined(), parts.last!] }
        let integer = parts[0]
        let fractional = parts[1].removingTrailingZeroes
        guard let integerNumber = BigInt(integer), let fractionalNumber = BigInt(fractional) else { return nil }
        let value = integerNumber * BigInt(10).power(precision) +
            fractionalNumber * BigInt(10).power(precision - fractional.count)
        return BigDecimal(value, precision)
    }

    public func localizedString(from number: BigDecimal,
                                locale: Locale = Locale.autoupdatingCurrent,
                                forcePlusSign: Bool = false,
                                shortFormat: Bool = true) -> String {
        return string(from: number,
                      decimalSeparator: locale.decimalSeparator ?? ".",
                      thousandSeparator: locale.groupingSeparator ?? ",",
                      literals: TokenFormatter.defaultLocalizedLiterals,
                      forcePlusSign: forcePlusSign,
                      shortFormat: shortFormat)
    }

    /// Formats a BigDecimal number.
    ///
    /// # Supported formats
    /// ## Full
    /// Full format shows all significant digits after decimal point,
    /// without any limitations.
    ///
    /// ## Short
    /// Short format cuts decimal digits based on the following rules, based on the number's magnitude:
    ///
    ///   - N < 1000 - displays 5 decimal digits (without rounding)
    ///   - N < 10 thousands - displays 4 decimal digits
    ///   - N < 100 thousands - displays 3 decimal digits
    ///   - N < 1 million - displays 2 ecimal digits
    ///   - N < 10 millions - displays 1 decimal digit
    ///   - N < 100 millions - only integer part is displayed
    ///   - N < 1 billion - displays number of millions with 3 decimal places with 'M' at the end (e.g. 100.001M)
    ///   - N < 1 trillion - displays number of billions with 3 decimal places with 'B' at the end (e.g. 100.001B)
    ///   - N < 1000 trillions - displays number of trillions with
    ///     3 decimal places with 'T' at the end (e.g. 100.001T)
    ///   - N >= 1000 trillions - displays '> 999T' for positive values, and '< -999T' for negative values
    ///
    ///  Negative values will have minus '-' sign as a prefix. Zero is always displayed without sign.
    ///
    /// # Styling
    /// You can change the separators, sign display, and provide your own literals for M, B, and T suffixes.
    ///
    /// - Parameters:
    ///   - number: a decimal number to format. Number has integer value and precision - number of significant digits
    ///   - decimalSeparator: separator to use for the decimal point. Default is dot '.'.
    ///   - thousandSeparator: separtor to use for grouping thousands. Default is comma ','.
    ///   - forcePlusSign: if true, positive numbers will have '+' sign. Default is false.
    ///   - shortFormat: if true, then uses short formatting, otherwise uses full formatting. Default is true.
    /// - Returns: Formatted number as a string.
    public func string(from number: BigDecimal,
                       decimalSeparator: String = ".",
                       thousandSeparator: String = ",",
                       literals: (millions: String, billions: String, trillions: String)
                            = TokenFormatter.defaultLiterals,
                       forcePlusSign: Bool = false,
                       shortFormat: Bool = true) -> String {
        // The implementation is working with base-10 String representation of the number.
        //
        // The idea is to split the number into integer and fractional parts, and then format each
        // according to rules. Short format, starting with millions, will disregard fractional part
        // and override it with new fractional part (showing thousands). Billions and trillions are similar.
        //
        // An alternative algorithm would use the number and algebraic operations to count needed
        // number of zeroes, or decide on the rules for millions/billions formatting. This would require
        // the log10() function for the BigInt type, which we do not have. That is why the String-based
        // operations have been chosen.

        var numberString = String(abs(number.value))
        let leadingZeroesForSmallNumbers = String(repeating: "0",
                                                  count: max(0, number.precision - numberString.count + 1))
        numberString = leadingZeroesForSmallNumbers + numberString

        var fractional = String(numberString.suffix(number.precision))
        var integer = String(numberString.prefix(numberString.count - fractional.count))

        let isNegative = number.value < 0
        let negativeSign = isNegative ? "-" : ""
        let positiveSign = (!isNegative && forcePlusSign ? "+" : "")

        var literal = ""
        var degree = 0

        if shortFormat {

            switch integer.count {
            case (0...8):
                let fractionalDigitCount = min(max(0, 8 - integer.count), 5)

                let cutoffFractional = String(fractional.prefix(fractionalDigitCount))

                // TODO: refactor with algorithm that takes number of desired fractional digits
                // this will remove the duplication and may make things simpler.

                if roundingBehavior == .roundUp {
                    let remainderDigitCount = max(fractional.count - cutoffFractional.count, 0)
                    let remainder = String(fractional.suffix(remainderDigitCount))
                    let zeroRemainder = String(repeating: "0", count: remainder.count)
                    let needsRoundUp = !remainder.isEmpty && remainder != zeroRemainder
                    if needsRoundUp {
                        let roundUpUnit = "1" + zeroRemainder
                        let newNumber = BigInt(integer + cutoffFractional + zeroRemainder)! + BigInt(roundUpUnit)!
                        return string(from: BigDecimal(newNumber, number.precision),
                                      decimalSeparator: decimalSeparator,
                                      thousandSeparator: thousandSeparator,
                                      literals: literals,
                                      forcePlusSign: forcePlusSign,
                                      shortFormat: shortFormat)
                    }
                }

                fractional = cutoffFractional.removingTrailingZeroes
            case 9:
                literal = literals.millions
                degree = 6
            case 10..<13:
                literal = literals.billions
                degree = 9
            case 13..<16:
                literal = literals.trillions
                degree = 12
            default:
                return isNegative ? "< -999" + literals.trillions
                    : ("> " + positiveSign + "999" + literals.trillions)
            }

            if degree > 0 {

                let cutoffFractional = String(integer.suffix(degree).prefix(3))
                let newInteger = String(integer.prefix(integer.count - degree))

                if roundingBehavior == .roundUp {
                    let remainder = String(integer.suffix(degree - 3)) + fractional
                    let zeroRemainder = String(repeating: "0", count: remainder.count)
                    let needsRoundUp = !remainder.isEmpty && remainder != zeroRemainder
                    if needsRoundUp {
                        let roundUpUnit = "1" + zeroRemainder
                        let newNumber = BigInt(newInteger + cutoffFractional + zeroRemainder)! + BigInt(roundUpUnit)!
                        return string(from: BigDecimal(newNumber, number.precision),
                                      decimalSeparator: decimalSeparator,
                                      thousandSeparator: thousandSeparator,
                                      literals: literals,
                                      forcePlusSign: forcePlusSign,
                                      shortFormat: shortFormat)
                    }
                }

                fractional = cutoffFractional
                integer = newInteger
            }
        }

        fractional = fractional.removingTrailingZeroes

        let integerGroupped = groups(string: integer, size: 3).joined(separator: thousandSeparator)
        let magnitude = fractional.isEmpty ? integerGroupped : integerGroupped + decimalSeparator + fractional
        let sign = magnitude != "0" ? (isNegative ? negativeSign : positiveSign) : ""
        return sign + magnitude + literal
    }

    /// Splits base-10 integer String into groups of `size` characters, starting from the end of string.
    ///
    /// For example:
    ///
    ///     groups(string: "1000", size: 3) // ["1", "000"]
    ///     groups(string: "1000", size: 2) // ["10", "00"]
    ///     groups(string: "1", size: 3) // ["1"]
    ///
    /// - Parameters:
    ///   - string: A string to split
    ///   - size: maximum size of the group
    /// - Returns: Groups of characters. The first item's length might be less than `size`.
    private func groups(string: String, size: Int) -> [String] {
        if string.count <= size { return [string] }
        // example result: [0, 3, 6, 9, 10]
        let groupBoundaries = stride(from: 0, to: string.count, by: size) + [string.count]
        // example result: [(9..<10), (6..<9), (3..<6), (0..<3)]
        let ranges = (0..<groupBoundaries.count - 1).map { groupBoundaries[$0]..<groupBoundaries[$0 + 1] }.reversed()
        // ranges used as offsets from the end of the string to get substrings:
        // example result: ["1", "000", "000", "000"]
        let groups = ranges.map { range -> String in
            let lowerIndex = string.index(string.endIndex, offsetBy: -range.upperBound)
            let upperIndex = string.index(string.endIndex, offsetBy: -range.lowerBound)
            return String(string[lowerIndex..<upperIndex])
        }
        return groups
    }
}


/// Represents a decimal number as a BigInt value with a known maximum number of digits after decimal point (precision).
public struct BigDecimal: Hashable {
    public var value: BigInt
    public var precision: Int

    public init(_ value: BigInt, _ precision: Int) {
        self.value = value
        self.precision = precision
    }

    public static func zero(_ precision: Int) -> BigDecimal {
        return BigDecimal(0, precision)
    }
}

extension String {
    var removingTrailingZeroes: String {
        var result = self
        while result.last == "0" {
            result.removeLast()
        }
        return result
    }

    var removingLeadingZeroes: String {
        var result = self
        while result.first == "0" {
            result.removeFirst()
        }
        return result
    }
}
