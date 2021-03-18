//
//  DnsUtils.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 12/18/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public struct DnsRecord: Equatable {
    var ttl: Int
    var type: String
    var data: String

    static public func == (lhs: DnsRecord, rhs: DnsRecord) -> Bool {
        return lhs.ttl == rhs.ttl && lhs.type == rhs.type && lhs.data == rhs.data
    }
}

public class DnsUtils {
    init() {}

    static let DefaultTtl: Int = 300

    public func toList(map: [String: String]) throws -> [DnsRecord] {
        let dnsTypes = self.getAllDnsTypes(map: map)
        var recordList: [DnsRecord] = []
        for type in dnsTypes {
            recordList += try self.constructDnsRecord(map: map, type: type)
        }
        return recordList
    }

    public func toMap(records: [DnsRecord]) throws -> [String: String] {
        var map: [String: String] = [:]
        for record in records {

            if let ttlInMap = map["dns.\(record.type).ttl"],
               let ttl = Int(ttlInMap) {

                guard ttl == record.ttl else {
                    throw DnsRecordsError.inconsistentTtl(recordType: DnsType(rawValue: record.type)!)
                }
            }

            guard let dnsArrayInMap: String = map["dns.\(record.type)"] else {
                map["dns.\(record.type)"] = self.toJsonString(from: [record.data])
                map["dns.\(record.type).ttl"] = String(record.ttl)
                continue
            }
            var dnsArray = try toStringArray(fromJsonString: dnsArrayInMap)
            dnsArray.append(record.data)
            map["dns.\(record.type)"] = toJsonString(from: dnsArray)
        }
        return map
    }

    private func constructDnsRecord(map: [String: String], type: DnsType) throws -> [DnsRecord] {
        var dnsRecords: [DnsRecord] = []
        let ttl: Int = self.parseTtl(map: map, type: type)
        guard let jsonValueString: String = map["dns.\(type)"] else {
            return []
        }
        do {
            let recordDataArray = try self.toStringArray(fromJsonString: jsonValueString)
            for record in recordDataArray {
                dnsRecords.append(DnsRecord(ttl: ttl, type: "\(type)", data: record))
            }
            return dnsRecords
        } catch {
            throw DnsRecordsError.dnsRecordCorrupted(recordType: type)
        }
    }

    private func getAllDnsTypes(map: [String: String]) -> [DnsType] {
        var types: Set<DnsType> = []
        for (key, _) in map {
            let chunks: [String] = key.components(separatedBy: ".")
            if chunks.count >= 1 && chunks[1] != "ttl" {
                if let type = DnsType(rawValue: chunks[1]) {
                    types.insert(type)
                }
            }
        }
        return Array(types)
    }

    private func parseTtl(map: [String: String], type: DnsType) -> Int {
        if let recordTtl = Int(map["dns.\(type).ttl"]!) {
            return recordTtl
        }
        if let defaultRecordTtl = Int(map["dns.ttl"]!) {
            return defaultRecordTtl
        }
        return DnsUtils.DefaultTtl
    }

    private func toJsonString(from object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }

    private func toStringArray(fromJsonString str: String) throws -> [String] {
        let data = Data(str.utf8)
        // swiftlint:disable force_cast
        return try JSONSerialization.jsonObject(with: data) as! [String]
        // swiftlint:enable force_cast
    }
}
