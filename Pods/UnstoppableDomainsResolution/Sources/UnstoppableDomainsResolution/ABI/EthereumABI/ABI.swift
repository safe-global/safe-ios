//
//  ABI.swift
//  resolution
//
//  Created by Serg Merenkov on 2/8/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

import Foundation

public struct ABI {

}

protocol ABIElementPropertiesProtocol {
    var isStatic: Bool {get}
    var isArray: Bool {get}
    var isTuple: Bool {get}
    var arraySize: ABI.Element.ArraySize {get}
    var subtype: ABI.Element.ParameterType? {get}
    var memoryUsage: UInt64 {get}
    var emptyValue: Any {get}
}

protocol ABIEncoding {
    var abiRepresentation: String {get}
}

protocol ABIValidation {
    var isValid: Bool {get}
}
