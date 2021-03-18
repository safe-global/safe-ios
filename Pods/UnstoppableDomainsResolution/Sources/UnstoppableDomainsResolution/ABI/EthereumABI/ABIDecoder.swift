//
//  ABIDecoder.swift
//  resolution
//
//  Created by Serg Merenkov on 2/8/21.
//  Copyright © 2021 Unstoppable Domains. All rights reserved.
//

import Foundation
import BigInt
import EthereumAddress

public struct ABIDecoder {

}

// swiftlint:disable cyclomatic_complexity function_body_length
extension ABIDecoder {
    public static func decode(types: [ABI.Element.InOut], data: Data) -> [AnyObject]? {
        let params = types.compactMap { (el) -> ABI.Element.ParameterType in
            return el.type
        }
        return decode(types: params, data: data)
    }

    public static func decode(types: [ABI.Element.ParameterType], data: Data) -> [AnyObject]? {
        var toReturn = [AnyObject]()
        var consumed: UInt64 = 0
        for i in 0 ..< types.count {
            let (v, c) = decodeSignleType(type: types[i], data: data, pointer: consumed)
            guard let valueUnwrapped = v, let consumedUnwrapped = c else {return nil}
            toReturn.append(valueUnwrapped)
            consumed += consumedUnwrapped
        }
        guard toReturn.count == types.count else {return nil}
        return toReturn
    }

    public static func decodeSignleType(type: ABI.Element.ParameterType, data: Data, pointer: UInt64 = 0) -> (value: AnyObject?, bytesConsumed: UInt64?) {
        let (elData, nextPtr) = followTheData(type: type, data: data, pointer: pointer)
        guard let elementItself = elData, let nextElementPointer = nextPtr else {
            return (nil, nil)
        }
        switch type {
        case .uint(let bits):
            guard elementItself.count >= 32 else {break}
            let mod = BigUInt(1) << bits
            let dataSlice = elementItself[0 ..< 32]
            let v = BigUInt(dataSlice) % mod
            return (v as AnyObject, type.memoryUsage)
        case .int(let bits):
            guard elementItself.count >= 32 else {break}
            let mod = BigInt(1) << bits
            let dataSlice = elementItself[0 ..< 32]
            let v = BigInt.fromTwosComplement(data: dataSlice) % mod
            return (v as AnyObject, type.memoryUsage)
        case .address:
            guard elementItself.count >= 32 else {break}
            let dataSlice = elementItself[12 ..< 32]
            let address = EthereumAddress(dataSlice)
            return (address as AnyObject, type.memoryUsage)
        case .bool:
            guard elementItself.count >= 32 else {break}
            let dataSlice = elementItself[0 ..< 32]
            let v = BigUInt(dataSlice)
            if v == BigUInt(1) {
                return (true as AnyObject, type.memoryUsage)
            } else if v == BigUInt(0) {
                return (false as AnyObject, type.memoryUsage)
            }
        case .bytes(let length):
            guard elementItself.count >= 32 else {break}
            let dataSlice = elementItself[0 ..< length]
            return (dataSlice as AnyObject, type.memoryUsage)
        case .string:
            guard elementItself.count >= 32 else {break}
            var dataSlice = elementItself[0 ..< 32]
            let length = UInt64(BigUInt(dataSlice))
            guard elementItself.count >= 32+length else {break}
            dataSlice = elementItself[32 ..< 32 + length]
            guard let string = String(data: dataSlice, encoding: .utf8) else {break}

            return (string as AnyObject, type.memoryUsage)
        case .dynamicBytes:

            guard elementItself.count >= 32 else {break}
            var dataSlice = elementItself[0 ..< 32]
            let length = UInt64(BigUInt(dataSlice))
            guard elementItself.count >= 32+length else {break}
            dataSlice = elementItself[32 ..< 32 + length]

            return (dataSlice as AnyObject, type.memoryUsage)
        case .array(type: let subType, length: let length):
            switch type.arraySize {
            case .dynamicSize:

                if subType.isStatic {

                    guard elementItself.count >= 32 else {break}
                    var dataSlice = elementItself[0 ..< 32]
                    let length = UInt64(BigUInt(dataSlice))
                    guard elementItself.count >= 32 + subType.memoryUsage*length else {break}
                    dataSlice = elementItself[32 ..< 32 + subType.memoryUsage*length]
                    var subpointer: UInt64 = 32
                    var toReturn = [AnyObject]()
                    for _ in 0 ..< length {
                        let (v, c) = decodeSignleType(type: subType, data: elementItself, pointer: subpointer)
                        guard let valueUnwrapped = v, let consumedUnwrapped = c else {break}
                        toReturn.append(valueUnwrapped)
                        subpointer += consumedUnwrapped
                    }
                    return (toReturn as AnyObject, type.memoryUsage)
                } else {

                    guard elementItself.count >= 32 else {break}
                    var dataSlice = elementItself[0 ..< 32]
                    let length = UInt64(BigUInt(dataSlice))
                    guard elementItself.count >= 32 else {break}
                    dataSlice = Data(elementItself[32 ..< elementItself.count])
                    var subpointer: UInt64 = 0
                    var toReturn = [AnyObject]()

                    for _ in 0 ..< length {
                        let (v, c) = decodeSignleType(type: subType, data: dataSlice, pointer: subpointer)
                        guard let valueUnwrapped = v, let consumedUnwrapped = c else {break}
                        toReturn.append(valueUnwrapped)
                        subpointer += consumedUnwrapped
                    }
                    return (toReturn as AnyObject, nextElementPointer)
                }
            case .staticSize(let staticLength):

                guard length == staticLength else {break}
                var toReturn = [AnyObject]()
                var consumed: UInt64 = 0
                for _ in 0 ..< length {
                    let (v, c) = decodeSignleType(type: subType, data: elementItself, pointer: consumed)
                    guard let valueUnwrapped = v, let consumedUnwrapped = c else {return (nil, nil)}
                    toReturn.append(valueUnwrapped)
                    consumed += consumedUnwrapped
                }
                if subType.isStatic {
                    return (toReturn as AnyObject, consumed)
                } else {
                    return (toReturn as AnyObject, nextElementPointer)
                }
            case .notArray:
                break
            }
        case .tuple(types: let subTypes):

            var toReturn = [AnyObject]()
            var consumed: UInt64 = 0
            for i in 0 ..< subTypes.count {
                let (v, c) = decodeSignleType(type: subTypes[i], data: elementItself, pointer: consumed)
                guard let valueUnwrapped = v, let consumedUnwrapped = c else {return (nil, nil)}
                toReturn.append(valueUnwrapped)
                consumed += consumedUnwrapped
            }

            if type.isStatic {
                return (toReturn as AnyObject, consumed)
            } else {
                return (toReturn as AnyObject, nextElementPointer)
            }
        case .function:

            guard elementItself.count >= 32 else {break}
            let dataSlice = elementItself[8 ..< 32]

            return (dataSlice as AnyObject, type.memoryUsage)
        }
        return (nil, nil)
    }

    fileprivate static func followTheData(type: ABI.Element.ParameterType, data: Data, pointer: UInt64 = 0) -> (elementEncoding: Data?, nextElementPointer: UInt64?) {

        if type.isStatic {
            guard data.count >= pointer + type.memoryUsage else {return (nil, nil)}
            let elementItself = data[pointer ..< pointer + type.memoryUsage]
            let nextElement = pointer + type.memoryUsage

            return (Data(elementItself), nextElement)
        } else {
            guard data.count >= pointer + type.memoryUsage else {return (nil, nil)}
            let dataSlice = data[pointer ..< pointer + type.memoryUsage]
            let bn = BigUInt(dataSlice)
            if bn > UINT64_MAX || bn >= data.count {
                // there are ERC20 contracts that use bytes32 intead of string. Let's be optimistic and return some data
                if case .string = type {
                    let nextElement = pointer + type.memoryUsage
                    let preambula = BigUInt(32).abiEncode(bits: 256)!
                    return (preambula + Data(dataSlice), nextElement)
                } else if case .dynamicBytes = type {
                    let nextElement = pointer + type.memoryUsage
                    let preambula = BigUInt(32).abiEncode(bits: 256)!
                    return (preambula + Data(dataSlice), nextElement)
                }
                return (nil, nil)
            }
            let elementPointer = UInt64(bn)
            let elementItself = data[elementPointer ..< UInt64(data.count)]
            let nextElement = pointer + type.memoryUsage

            return (Data(elementItself), nextElement)
        }
    }

    public static func decodeLog(event: ABI.Element.Event, eventLogTopics: [Data], eventLogData: Data) -> [String: Any]? {
        if event.topic != eventLogTopics[0] && !event.anonymous {
            return nil
        }
        var eventContent = [String: Any]()
        eventContent["name"]=event.name
        let logs = eventLogTopics
        let dataForProcessing = eventLogData
        let indexedInputs = event.inputs.filter { (inp) -> Bool in
            return inp.indexed
        }
        if logs.count == 1 && indexedInputs.count > 0 {
            return nil
        }
        let nonIndexedInputs = event.inputs.filter { (inp) -> Bool in
            return !inp.indexed
        }
        let nonIndexedTypes = nonIndexedInputs.compactMap { (inp) -> ABI.Element.ParameterType in
            return inp.type
        }
        guard logs.count == indexedInputs.count + 1 else {return nil}
        var indexedValues = [AnyObject]()
        for i in 0 ..< indexedInputs.count {
            let data = logs[i+1]
            let input = indexedInputs[i]
            if !input.type.isStatic || input.type.isArray || input.type.memoryUsage != 32 {
                let (v, _) = ABIDecoder.decodeSignleType(type: .bytes(length: 32), data: data)
                guard let valueUnwrapped = v else {return nil}
                indexedValues.append(valueUnwrapped)
            } else {
                let (v, _) = ABIDecoder.decodeSignleType(type: input.type, data: data)
                guard let valueUnwrapped = v else {return nil}
                indexedValues.append(valueUnwrapped)
            }
        }
        let v = ABIDecoder.decode(types: nonIndexedTypes, data: dataForProcessing)
        guard let nonIndexedValues = v else {return nil}
        var indexedInputCounter = 0
        var nonIndexedInputCounter = 0
        for i in 0 ..< event.inputs.count {
            let el = event.inputs[i]
            if el.indexed {
                let name = "\(i)"
                let value = indexedValues[indexedInputCounter]
                eventContent[name] = value
                if el.name != "" {
                    eventContent[el.name] = value
                }
                indexedInputCounter += 1
            } else {
                let name = "\(i)"
                let value = nonIndexedValues[nonIndexedInputCounter]
                eventContent[name] = value
                if el.name != "" {
                    eventContent[el.name] = value
                }
                nonIndexedInputCounter += 1
            }
        }
        return eventContent
    }
}
