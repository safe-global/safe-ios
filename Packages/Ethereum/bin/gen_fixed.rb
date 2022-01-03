# Generate ufixedMxN and fixedMxN pair of types for Solidity Contract ABI
# Swift implementation uses solidity integer types.

template = <<-EOD
// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.UFixed{{BIT_WIDTH}}x{{EXPONENT}}

extension Sol {
    public struct UFixed{{BIT_WIDTH}}x{{EXPONENT}} {
        public var storage: Sol.UInt{{BIT_WIDTH}}
        public init() { storage = 0 }
        public init(storage: Sol.UInt{{BIT_WIDTH}}) { self.storage = storage }
    }
}

extension Sol.UFixed{{BIT_WIDTH}}x{{EXPONENT}}: SolUnsignedFixedPointDecimal {
    public static var bitWidth: Int { {{BIT_WIDTH}} }
    public static var exponent: Int { {{EXPONENT}} }
}

// MARK: - Sol.Fixed{{BIT_WIDTH}}x{{EXPONENT}}

extension Sol {
    public struct Fixed{{BIT_WIDTH}}x{{EXPONENT}} {
        public var storage: Sol.Int{{BIT_WIDTH}}
        public init() { storage = 0 }
        public init(storage: Sol.Int{{BIT_WIDTH}}) { self.storage = storage }
    }
}

extension Sol.Fixed{{BIT_WIDTH}}x{{EXPONENT}}: SolSignedFixedPointDecimal {
    public static var bitWidth: Int { {{BIT_WIDTH}} }
    public static var exponent: Int { {{EXPONENT}} }
}

EOD

filename_template = "UFixed{{BIT_WIDTH}}x{{EXPONENT}}.swift"

# 0 < M <= 256, M % 8 == 0; 0 < N <= 80
(0..256).step(8).drop(1).each { |bit_width|
    (0..80).drop(1).each { |exponent|
        filename = filename_template
            .gsub(/\{\{BIT_WIDTH\}\}/, "#{bit_width}")
            .gsub(/\{\{EXPONENT\}\}/, "#{exponent}")
        content = template
            .gsub(/\{\{BIT_WIDTH\}\}/, "#{bit_width}")
            .gsub(/\{\{EXPONENT\}\}/, "#{exponent}")

        File.open(filename, "w") { |file|
            file.write(content)
        }
    }   
}
