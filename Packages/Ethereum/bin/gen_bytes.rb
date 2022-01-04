# Generates bytes<M> types for Contract ABI

template = <<-EOD
// Created by Dmitry Bespalov on 01.01.2022

// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation

// MARK: - Sol.Bytes{{BYTE_COUNT}}

extension Sol {
    public struct Bytes{{BYTE_COUNT}} {
        public var storage: Data
        public init(storage: Data) { self.storage = storage }
    }
}

extension Sol.Bytes{{BYTE_COUNT}}: SolFixedBytes {
    public static var byteCount: Int { {{BYTE_COUNT}} }
}

EOD

filename_template = "Bytes{{BYTE_COUNT}}.swift"

(0..32).drop(1).each { |byte_count|
    filename = filename_template
        .gsub(/\{\{BYTE_COUNT\}\}/, "#{byte_count}")

    content = template
        .gsub(/\{\{BYTE_COUNT\}\}/, "#{byte_count}")

    File.open(filename, "w") { |file|
        file.write(content)
    }
}
