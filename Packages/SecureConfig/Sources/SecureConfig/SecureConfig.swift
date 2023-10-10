import Foundation
import CryptoKit

/// Use SecureConfig to create and encrypt a key-value configuration dictionary.
///
/// Encrypt `PlainFile` with `.encrypt(file:)` to produce a `key` and a `SealedFile`. Then export `key` with `string(from:)` to
/// a base64 String and save the `SealedFile` to disk.
///
/// Load and save Codable types in files using `.load(filename:)` and `.save(filename:contents:)` methods.
/// Use those to create or read `SealedFile` from the file system.
///
/// Decrypt the `SealedFile` with `.decrypt(file:key:)` to get configuration from the decrypted `PlainFile`.
///
/// In case of encryption errors, data conversion errors, or unsupported versions or algorithms, the methods will throw.
///
public class SecureConfig {
    
    public static let PLAIN_VERSION = "plain-v1"
    public static let SEALED_VERSION = "sealed-v1"
    public static let SEALED_ALGO = "aes-256-gcm"

    public struct SealedFile: Codable, Hashable {
        public var _version: String
        public var alg: String
        public var text: String
    }
    
    public struct PlainFile: Codable, Hashable {
        public var _version: String
        public var config: [String: String]
    }
    
    public enum Errors: Error {
        case unsupportedFileVersion(String)
        case unsupportedEncryptionAlgorithm(String)
        case textUnreadable
    }
    
    public init() {}
    
    public func load<T: Codable>(filename: String) throws -> T {
        let url: URL
        if #available(iOS 16.0, *) {
            url = URL(filePath: filename)
        } else {
            url = URL(fileURLWithPath: filename)
        }
        let content = try Data(contentsOf: url)
        let result: T = try contents(data: content)
        return result
    }
    
    public func save<T: Codable>(filename: String, contents: T) throws {
        let url: URL
        if #available(iOS 16.0, *) {
            url = URL(filePath: filename)
        } else {
            url = URL(fileURLWithPath: filename)
        }
        let data = try data(contents: contents)
        try data.write(to: url)
    }
    
    public func encrypt(file: PlainFile) throws -> (key: SymmetricKey, file: SealedFile) {
        guard file._version == SecureConfig.PLAIN_VERSION else { throw Errors.unsupportedFileVersion(file._version) }
        let data = try self.data(contents: file)
        let key = self.generateKey()
        let ciphertext = try encrypt(data: data, key: key)
        let result = SealedFile(ciphertext.base64EncodedString())
        return (key, result)
    }

    public func decrypt(file: SealedFile, key: SymmetricKey) throws -> PlainFile {
        guard file._version == SecureConfig.SEALED_VERSION else { throw Errors.unsupportedFileVersion(file._version) }
        guard file.alg == SecureConfig.SEALED_ALGO else { throw Errors.unsupportedEncryptionAlgorithm(file.alg) }
        guard let cipherdata = Data(base64Encoded: file.text) else { throw Errors.textUnreadable }
        let plaindata = try decrypt(data: cipherdata, key: key)
        let result: PlainFile = try contents(data: plaindata)
        guard result._version == SecureConfig.PLAIN_VERSION else { throw Errors.unsupportedFileVersion(file._version) }
        return result
    }
    
    public func generateKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    public func string(from key: SymmetricKey) -> String {
        return key.withUnsafeBytes { body in
            Data(body).base64EncodedString()
        }
    }
    
    public func key(from string: String) -> SymmetricKey? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return SymmetricKey(data: data)
    }
    
    public func encrypt(data: Data, key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.seal(data, using: key)
        return sealed.combined!
    }
    
    public func decrypt(data: Data, key: SymmetricKey) throws -> Data {
        let sealed = try AES.GCM.SealedBox(combined: data)
        let result = try AES.GCM.open(sealed, using: key)
        return result
    }

    
    internal func data<T: Codable>(contents: T) throws -> Data {
        return try JSONEncoder().encode(contents)
    }
    
    internal func contents<T: Codable>(data: Data) throws -> T {
        return try JSONDecoder().decode(T.self, from: data)
    }
}

public extension SecureConfig.PlainFile {
    init(_ config: [String: String]) {
        _version = SecureConfig.PLAIN_VERSION
        self.config = config
    }
}

public extension SecureConfig.SealedFile {
    init(_ text: String) {
        _version = SecureConfig.SEALED_VERSION
        alg = SecureConfig.SEALED_ALGO
        self.text = text
    }
}
