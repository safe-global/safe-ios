//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 05.01.22.
//

import Foundation

enum Template {
    static let file =
"""
// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

<#content#>
"""

    // Contract
    static let contract =
"""
public enum <#ContractName#> {
    <#Members#>
}
"""

    // Function
    static let function =
"""
public struct <#FunctionName#>: SolContractFunction, SolKeyPathTuple {
    <#TupleBody#>

    <#Returns#>
}
"""

    // TupleBody
    static let tupleBody =
"""
<#Components#>

<#KeyPaths#>

<#MemberwiseInit#>

<#DefaultInit#>
"""

    // Tuple
    static let tuple =
"""
public struct <#TupleName#>: SolEncodableTuple, SolKeyPathTuple {
    <#TupleBody#>
}
"""

    // Tuple Component
    static let tupleComponent =
"""
public var <#name#>: <#type#>
"""

    static let keyPaths =
"""
public static var keyPaths: [AnyKeyPath] = [
<#KeyPaths#>
]
"""

    // KeyPath
    static let keyPath =
"""
\\Self.<#name#>
"""

    // Init
    static let initDeclaration =
"""
public init(<#Arguments#>) {
<#Body#>
}
"""

    // Init Declaration Argument
    static let initDeclarationArgument =
"""
<#name#> <#internalname#>: <#type#>
"""

    // Member Init
    static let memberInit =
"""
self.<#name#> = <#value#>
"""

    // Func Invocation
    static let memberFuncInvocation =
"""
<#receiver#>.<#func#>(<#args#>)
"""

    // Init Invocation Argument
    static let initInvocationArgument =
"""
<#name#>: <#value#>
"""
}
