# Generates an uint<M> int<M> integer pair representing Solidity integer types.
# Swift implementation uses WordInteger package.
# 0 < M <= 256, M % 8 == 0

template = <<-EOD
// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import WordInteger

// MARK: - Sol.UInt{{BIT_WIDTH}}

extension Sol {
    public struct UInt{{BIT_WIDTH}} {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.UInt{{BIT_WIDTH}}: WordUnsignedInteger {
    public typealias Stride = Sol.Int{{BIT_WIDTH}}
    public typealias Magnitude = Self
    public typealias IntegerLiteralType = Swift.UInt

    public static var bitWidth: Swift.Int { {{BIT_WIDTH}} }
}

extension Sol.UInt{{BIT_WIDTH}}: SolInteger {
    // uses default implementation
}

// MARK: - Sol.Int{{BIT_WIDTH}}

extension Sol {
    public struct Int{{BIT_WIDTH}} {
        public var storage: [Swift.UInt]
        public init() { storage = [] }
    }
}

extension Sol.Int{{BIT_WIDTH}}: WordSignedInteger {
    public typealias Stride = Self
    public typealias Magnitude = Sol.UInt{{BIT_WIDTH}}
    public typealias IntegerLiteralType = Swift.Int

    public static var bitWidth: Swift.Int { {{BIT_WIDTH}} }
}

extension Sol.Int{{BIT_WIDTH}}: SolInteger {
    // uses default implementation
}

EOD

filename_template = "UInt{{BIT_WIDTH}}.swift"

(0..256).step(8).drop(1).each { |bit_width|
    filename = filename_template
        .gsub(/\{\{BIT_WIDTH\}\}/, "#{bit_width}")

    content = template.gsub(/\{\{BIT_WIDTH\}\}/, "#{bit_width}")

    File.open(filename, "w") { |file|
        file.write(content)
    }
}
