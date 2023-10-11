import XCTest
@testable import SecureConfig

final class SecureConfigTests: XCTestCase {
    func testIntegration() throws {
        continueAfterFailure = false
        
        let config = SecureConfig()
        let plain = SecureConfig.PlainFile(["a": "b"])
        let sealed = try config.encrypt(file: plain)
        
        let dir = NSTemporaryDirectory()
        try config.save(filename: dir + "/sealedbox", contents: sealed.file)

        let file: SecureConfig.SealedFile = try config.load(filename: dir + "/sealedbox")
        
        let keytext = config.string(from: sealed.key)
        guard let key = config.key(from: keytext) else {
            XCTFail("key conversion failed")
            return
        }
        let derived = try config.decrypt(file: file, key: key)
        XCTAssertEqual(derived, plain)
    }
}
