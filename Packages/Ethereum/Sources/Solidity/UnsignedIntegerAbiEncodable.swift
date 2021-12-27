//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 27.12.21.
//

import Foundation

//extension WordUnsignedInteger {
//    static var isStatic: Bool { true }
//
//    // 6. uint<M>: enc(X) is the big-endian encoding of X, padded on the higher-order (left) side with zero-bytes such that the length is multiple of 32.
//    func encode() -> Data {
//        let value = bigEndian
//        let bytes = stride(from: 0, to: Self.bitWidth, by: 8).map { bitOffset in
//            UInt8((value >> bitOffset) & 0xff)
//        }
//
//        let remainderFrom32 = bytes.count % 32
//        if remainderFrom32 == 0 {
//            return Data(bytes)
//        }
//
//        return Data(repeating: 0x00, count: 32 - remainderFrom32) + Data(bytes)
//    }
//}
