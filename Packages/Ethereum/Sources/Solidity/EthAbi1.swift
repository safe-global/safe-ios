//
//  EthAbi.swift
//  
//
//  Created by Dmitry Bespalov on 20.12.21.
//

import Foundation


// Data is encoded according to its type, as described in this specification. The encoding is not self describing and thus requires a schema in order to decode.
// We assume the interface functions of a contract are strongly typed, known at compilation time and static. We assume that all contracts will have the interface definitions of any contracts they call available at compile-time.
// This specification does not address contracts whose interface is dynamic or otherwise known only at run-time.

// constructor - doesn't have name or outputs
// fallback - doesnt' have inputs, can be virtual, can overrdie, can have modifiers.
// receive - no arguments, no return, must be external and payable. can be virtual, can override, can have modifiers

/*
 Dependencies:
 https://github.com/attaswift/BigInt
 https://github.com/bitcoin-core/secp256k1
 https://github.com/coruus/keccak-tiny

 Data <-> Hex String

 Data
 Type
 Schema
 Interface Function
 Contract
 Interface Definition
 Dynamic Interface
 Static Interface

 Call Data
 Function Call
 Function Selector
    first (left, high-order in big-endian) four bytes of keccak-256(function signature)
 Function Signature
    canonical expression of the basic prototype without data location specifier
        function name with the parenthesised list of parameter types split by single comma w/o spaces
    return type is not part of signature.

 Method Identifier

 Function Arguments
 Return Values
 Event Arguments

 Types
 Elementary Types
    uint<M>, 0 < M <= 256, M % 8 == 0, unsigned integer
    int<M>, 0 < M <= 256, M % 8 == 0, 2's complement signed integer
    address, =uint160. selector name: address
    uint, int = uint256, int256, selector names: uint256, int256
    bool, =uint8 with 0 or 1 only. selector names: bool
    fixed<M>x<N>, 8 <= M <= 256, M % 8 == 0, 0 < N <= 80, =v/10^N signed fixed-point decimal
    ufixed<M>x<N>, unsigned variant of fixed<M>x<N>
    fixed, ufixed, =fixed128x18, =ufixed128x18, selector names: fixed128x18,ufixed128x18
    bytes<M>, 0 < M <= 32 binary type of M bytes
    function: address followed by function selector (4 bytes). Encoded identical to bytes24

 Fixed-size Array Types:
    <type>[M]: fixed-length array of M elements, M>=0. 0-element arrays not supported by compiler (0.8.10)

 Non-fixed-size Types:
    bytes, dynamic sized byte sequence
    string, dynamic sized unicode string assummed in UTF-8
    <type>[]: variable-length array of elements of a given type

    (T1,T2,...,Tn):  tuple of types T1, ..., Tn, n >= 0. Nested tuples, arrays, and 0 tuples are possible.

 Solidity <--> ABI
    address payable = address
    contract = address
    enum = uint8
    user defined value types = underlying value type
    struct = tuple
    (before 0.8.0) enum = smallest integer big enough to hold value of any member

 Event
    name
    args
    anonymous?
    indexed args
    non indexed args

 Log entry
    address
    topics[0]
        canonical_type_of()
    topics[n]
    data

 Error (revert) - as function call) // The error selectors 0x00000000 and 0xffffffff are reserved for future use
    // Never trust error data. The error data by default bubbles up through the chain of external calls, which means that a contract may receive an error not defined in any of the contracts it calls directly. Furthermore, any contract can fake any error by returning data that matches an error signature, even if the error is not defined anywhere.


 abi_encode
    len(a): number of bytes in a binary string a, returns uint256
    enc(): encoding function
    head(X)
    tail(X)
    pad_right(X)
    enc_utf8(X)
    function_selector(f)

    strict encoding mode
    non-standard packed mode: abi.encodePacked()
         types shorter than 32 bytes are neither zero padded nor sign extended and
         dynamic types are encoded in-place and without the length.
         array elements are padded, but still encoded in-place
         Furthermore, structs as well as nested arrays are not supported.
         During the encoding, everything is encoded in-place. This means that there is no distinction between head and tail, as in the ABI encoding, and the length of an array is not encoded.
         The direct arguments of abi.encodePacked are encoded without padding, as long as they are not arrays (or string or bytes).
         The encoding of an array is the concatenation of the encoding of its elements with padding.
         Dynamically-sized types like string, bytes or uint[] are encoded without their length field.
         The encoding of string or bytes does not apply padding at the end unless it is part of an array or struct (then it is padded to a multiple of 32 bytes).

    encoding of indexed event params
         the encoding of a bytes and string value is just the string contents without any padding or length prefix.
         the encoding of a struct is the concatenation of the encoding of its members, always padded to a multiple of 32 bytes (even bytes and string).
         the encoding of an array (both dynamically- and statically-sized) is the concatenation of the encoding of its elements, always padded to a multiple of 32 bytes (even bytes and string) and without any length prefix

        The encoding of a struct is ambiguous if it contains more than one dynamically-sized array. Because of that, always re-check the event data and do not rely on the search result based on the indexed parameters alone.

 decode - reverse function of abi_encode

 parse(function sel + signature), parse return type

 Json of a contract interface: [function_descr, event_descr, error_descr]
 function descr
    type
    name
    inputs
        name
        type
        components
    outputs
    stateMutability

 event descr
    type
    name
    inputs
        name
        type
        components
        indexed
    anonymous

 error descr
    type
    name
    inputs
        name
        type
        components


 (Contract metadata)
 NatSpec https://docs.soliditylang.org/en/v0.8.10/natspec-format.html
 source verification: https://www.npmjs.com/package/source-verify

 */
