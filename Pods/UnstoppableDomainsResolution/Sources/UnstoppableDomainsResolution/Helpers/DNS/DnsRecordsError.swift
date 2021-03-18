//
//  DnsRecordsError.swift
//  UnstoppableDomainsResolution
//
//  Created by Johnny Good on 12/18/20.
//  Copyright © 2020 Unstoppable Domains. All rights reserved.
//

import Foundation

public enum DnsRecordsError: Error {
    case dnsRecordCorrupted(recordType: DnsType)
    case inconsistentTtl(recordType: DnsType)
}
