//
//  DnsType.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 12/17/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//
// swiftlint:disable identifier_name

import Foundation

public enum DnsType: String {
    case A
    case AAAA
    case AFSDB
    case APL
    case CAA
    case CDNSKEY
    case CDS
    case CERT
    case CNAME
    case CSYNC
    case DHCID
    case DLV
    case DNAME
    case DNSKEY
    case DS
    case EUI48
    case EUI64
    case HINFO
    case HIP
    case HTTPS
    case IPSECKEY
    case KEY
    case KX
    case LOC
    case MX
    case NAPTR
    case NS
    case NSEC
    case NSEC3
    case NSEC3PARAM
    case OPENPGPKEY
    case PTR
    case RP
    case RRSIG
    case SIG
    case SMIMEA
    case SOA
    case SRV
    case SSHFP
    case SVCB
    case TA
    case TKEY
    case TLSA
    case TSIG
    case TXT
    case URI
    case ZONEMD

    static func getCryptoRecords(types: [DnsType], ttl: Bool) -> [String] {
        var cryptoRecords: [String] = []
        if ttl {
            cryptoRecords.append("dns.ttl")
        }
        for type in types {
            if ttl {
                cryptoRecords.append(self.getCryptoRecord(type: type, with: ttl))
            }
            cryptoRecords.append(self.getCryptoRecord(type: type))
        }
        return cryptoRecords
    }

    static func getCryptoRecord(type: DnsType, with ttl: Bool = false) -> String {
        if ttl {
            return "dns.\(type).ttl"
        }
        return "dns.\(type)"
    }
}
