//
//  DateDecodingStrategy+GnosisSafeServices.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 09.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

extension JSONDecoder.DateDecodingStrategy {

    static let backendFormatter1: DateFormatter = {
        // 2020-01-22T13:11:59.838510Z
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return formatter
    }()

    static let backendFormatter2: DateFormatter = {
        // 2020-01-22T13:11:48Z
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

    static let backendDateDecodingStrategy: JSONDecoder.DateDecodingStrategy =
        JSONDecoder.DateDecodingStrategy.custom { (decoder) -> Date in
            let c = try decoder.singleValueContainer()
            let str = try c.decode(String.self)
            if let date = Self.backendFormatter1.date(from: str) {
                return date
            } else if let date = Self.backendFormatter2.date(from: str) {
                return date
            } else {
                let context = DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Date! \(str)")
                throw DecodingError.dataCorrupted(context)
            }
        }

}
