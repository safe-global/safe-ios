# Generates bytes<M> types for Contract ABI

template = <<-EOD
// MARK: - Sol.Bytes{{BYTE_COUNT}}

extension Sol {
    public struct Bytes{{BYTE_COUNT}} {
        public var storage: Data
        public init() { storage = Data() }
        public init(storage: Data) { self.storage = storage }
    }
}

extension Sol.Bytes{{BYTE_COUNT}}: SolFixedBytes {
    public static var byteCount: Int { {{BYTE_COUNT}} }
}

EOD

(0..32).drop(1).each { |byte_count|
    decl = template.gsub(/\{\{BYTE_COUNT\}\}/, "#{byte_count}")
    puts(decl)
}
