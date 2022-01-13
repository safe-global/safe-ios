//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 13.01.22.
//

import Foundation

// http://graphics.stanford.edu/~seander/bithacks.html#IntegerLogObvious
// slow but works
public func log2<T>(_ v: T) -> T where T: WordSignedInteger {
    // position of the MSB
    return T(T.bitWidth - v.leadingZeroBitCount - 1)
}

// http://graphics.stanford.edu/~seander/bithacks.html#IntegerLog10
// log10(v) = log2(v) / log2(10)
public func log10<T>(_ v: T) -> T where T: WordSignedInteger {
    // log2(v) * (log2(10) = 1233/4096)
    let t = ((log2(v) + 1) * 1233) >> 12
    let powerOf10 = pow(10 as T, Int(t))
    let r = t - (v < powerOf10 ? 1 : 0)
    return r
}

public func pow<T>(_ x: T, _ y: Int) -> T where T: WordSignedInteger {
    let a = x.big()
    let b = a.power(y)
    let r = T(big: b)
    return r
}

// copy-paste for now
public func log2<T>(_ v: T) -> T where T: WordUnsignedInteger {
    // position of the MSB
    return T(T.bitWidth - v.leadingZeroBitCount - 1)
}

// http://graphics.stanford.edu/~seander/bithacks.html#IntegerLog10
// log10(v) = log2(v) / log2(10)
public func log10<T>(_ v: T) -> T where T: WordUnsignedInteger {
    // log2(v) * (log2(10) = 1233/4096)
    let t = ((log2(v) + 1) * 1233) >> 12
    let powerOf10 = pow(10 as T, Int(t))
    let r = t - (v < powerOf10 ? 1 : 0)
    return r
}

public func pow<T>(_ x: T, _ y: Int) -> T where T: WordUnsignedInteger {
    let a = x.big()
    let b = a.power(y)
    let r = T(big: b)
    return r
}
