//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import idn2Swift

class IDNTests: XCTestCase {

    func test_toAscii_example() {
        let utf8str = "βόλος.com"
        var cString = Array(utf8str.utf8CString)
        var output: UnsafeMutablePointer<CChar>?
        let status = idn2_to_ascii_8z(&cString, &output, Int32(IDN2_NONTRANSITIONAL.rawValue))
        defer { free(output) }
        XCTAssertEqual(status, IDN2_OK.rawValue)
        if let ptr = output {
            let asciiStr = String(cString: ptr)
            XCTAssertEqual(asciiStr, "xn--nxasmm1c.com")
        } else {
            XCTFail()
        }
    }

    func test_toUnicode_example() {
        let asciistr = "xn--nxasmm1c.com"
        var cString = Array(asciistr.utf8CString)
        var output: UnsafeMutablePointer<CChar>?
        let status = idn2_to_unicode_8z8z(&cString, &output, 0)
        defer { free(output) }
        XCTAssertEqual(status, IDN2_OK.rawValue)
        if let ptr = output {
            let asciiStr = String(cString: ptr)
            XCTAssertEqual(asciiStr, "βόλος.com")
        } else {
            XCTFail()
        }
    }

    func test_error() {
        let code = IDN2_ENCODING_ERROR.rawValue
        guard let namePtr = idn2_strerror_name(code), let strPtr = idn2_strerror(code) else {
                XCTFail()
                return
        }
        let name = String(cString: namePtr)
        let str = String(cString: strPtr)
        XCTAssertEqual(name, "IDN2_ENCODING_ERROR")
        // using notEqual instead of isEmpty to see the actual str content in case of failure
        XCTAssertNotEqual(str, "")
    }

    func test_utf8ToASCII() throws {
        XCTAssertEqual(try IDN.utf8ToASCII("Faß.de", useSTD3ASCIIRules: true), "xn--fa-hia.de")
        XCTAssertEqual(try IDN.asciiToUTF8("xn--fa-hia.de"), "faß.de")
    }

}
