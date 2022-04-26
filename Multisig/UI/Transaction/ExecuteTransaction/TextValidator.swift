//
//  TextValidator.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 13.01.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

protocol TextValidator {
    /// input: partial text
    /// output: corrected partial text
    func validated(oldValue: String?, newPartialValue: String?) -> String?
}

class IdentityTextValidator: TextValidator {
    /// allways validates to the same newPartialValue
    func validated(oldValue: String?, newPartialValue: String?) -> String? {
        newPartialValue
    }
}

class IntegerTextValidator: TextValidator {
    /// validates partial value to be part of a non-negative integer without a sign
    func validated(oldValue: String?, newPartialValue: String?) -> String? {
        guard let partialValue = newPartialValue, !partialValue.isEmpty else {
            return newPartialValue
        }

        let isDigits = partialValue.numberOfMatches(pattern: "^\\d+$") == 1

        guard isDigits else {
            return oldValue
        }

        let droppedLeadingZeroes = partialValue.drop(while: { $0 == "0" })

        let result = droppedLeadingZeroes.isEmpty ? "0" : droppedLeadingZeroes

        return String(result)
    }
}

class DecimalTextValidator: TextValidator {
    /// validates partial value to be part of a non-negative decimal number without a sign
    func validated(oldValue: String?, newPartialValue: String?) -> String? {
        guard let partialValue = newPartialValue, !partialValue.isEmpty else {
            return newPartialValue
        }
        let dot = "[.,٫]"
        let pattern = "^(\\d*\(dot)\\d*|\\d+)$"
        let isPartialDecimal = partialValue.numberOfMatches(pattern: pattern) == 1

        guard isPartialDecimal else {
            return oldValue
        }

        var result = partialValue
        // can have different type of decimal separator, replace it with dot
        result = result.replacingMatches(pattern: dot, with: ".")

        // can have leading zeroes - drop them
        result = String(result.drop(while: { $0 == "0" }))
        result = result.isEmpty ? "0" : result

        // can start with a dot - add leding zero
        result = result.hasPrefix(".") ? "0" + result : result

        return result
    }
}

extension String {
    /// pattern must be a valid regular expression or this will crash
    func numberOfMatches(pattern: String) -> Int {
        do {
            let regexp = try NSRegularExpression(pattern: pattern, options: [])
            let matchCount = regexp.numberOfMatches(in: self, options: [], range: NSRange(location: 0, length: count))
            return matchCount
        } catch {
            preconditionFailure("Invalid regexp pattern: \(pattern): \(error)")
        }
    }

    /// pattern must be a valid regular expression or this will crash
    func replacingMatches(pattern: String, with template: String) -> String {
        do {
            let regexp = try NSRegularExpression(pattern: pattern, options: [])
            let result = regexp.stringByReplacingMatches(in: self,
                                                         options: [],
                                                         range: NSRange(location: 0, length: count),
                                                         withTemplate: template)
            return result
        } catch {
            preconditionFailure("Invalid regexp pattern: \(pattern): \(error)")
        }
    }

    func matches(pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }

    func capturedValues(pattern: String) -> [[String]] {
        do {
            let regexp = try NSRegularExpression(pattern: pattern, options: [])
            var result = [[String]]()
            regexp.enumerateMatches(in: self, options: [], range: NSRange(location: 0, length: count)) { match, _, _ in
                guard let match = match else {
                    return
                }
                var matches = [String]()
                for i in 1..<match.numberOfRanges {
                    let range = match.range(at: i)
                    guard range.location != NSNotFound else { continue }
                    let value = (self as NSString).substring(with: range)
                    matches.append(value)
                }
                result.append(matches)
            }
            return result
        } catch {
            preconditionFailure("Invalid regexp pattern: \(pattern): \(error)")
        }
    }

    func namedCapturedValues(pattern: String, names: [String]) -> [String: [String]] {
        do {
            let regexp = try NSRegularExpression(pattern: pattern, options: [])
            var result: [String: [String]] = Dictionary(uniqueKeysWithValues: names.map { ($0, [String]()) })
            regexp.enumerateMatches(in: self, options: [], range: NSRange(location: 0, length: count)) { match, _, _ in
                guard let match = match else {
                    return
                }
                for name in names {
                    let range = match.range(withName: name)
                    guard range.location != NSNotFound else { continue }
                    let value = (self as NSString).substring(with: range)
                    result[name]?.append(value)
                }
            }
            return result
        } catch {
            preconditionFailure("Invalid regexp pattern: \(pattern): \(error)")
        }
    }
}
