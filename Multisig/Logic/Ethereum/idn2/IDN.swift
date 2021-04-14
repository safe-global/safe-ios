//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation
import idn2

// see https://unicode.org/reports/tr46/
// see https://libidn.gitlab.io/libidn2/manual/libidn2.html
public final class IDN {

    private init() {}

    public static func utf8ToASCII(_ utf8String: String, useSTD3ASCIIRules: Bool, transitionalProcessing: Bool = false) throws -> String {
        var flags: Int32 = 0
        flags |= Int32(IDN2_NFC_INPUT.rawValue)
        if useSTD3ASCIIRules {
            flags |= Int32(IDN2_USE_STD3_ASCII_RULES.rawValue)
        }
        if transitionalProcessing {
            flags |= Int32(IDN2_TRANSITIONAL.rawValue)
        }

        var input = Array(utf8String.utf8CString)
        var output: UnsafeMutablePointer<CChar>?
        let status = idn2_to_ascii_8z(&input, &output, flags)
        defer { free(output) }
        guard status == IDN2_OK.rawValue else {
            throw NSError(idn2Code: status)
        }
        let result = String(cString: output!)
        return result
    }

    public static func asciiToUTF8(_ asciiString: String) throws -> String {
        var input = Array(asciiString.utf8CString)
        var output: UnsafeMutablePointer<CChar>?
        let unusedFlags: Int32 = 0
        let status = idn2_to_unicode_8z8z(&input, &output, unusedFlags)
        defer { free(output) }
        guard status == IDN2_OK.rawValue else {
            throw NSError(idn2Code: status)
        }
        let result = String(cString: output!)
        return result
    }

    public static var localizationBundle: Bundle = {
        let containerBundle = Bundle(for: IDN.self)
        let bundle: Bundle
        if let path = containerBundle.path(forResource: "idn2SwiftResources", ofType: "bundle") {
            bundle = Bundle(path: path) ?? containerBundle
        } else {
            bundle = containerBundle
        }
        return bundle
    }()

}

extension NSError {

    convenience init(idn2Code: Int32) {
        self.init(domain: "idn2Swift",
                  code: Int(idn2Code),
                  userInfo: [NSLocalizedDescriptionKey: NSError.localizedString(from: idn2_rc(idn2Code))])
    }

    static func _localizedString(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: IDN.localizationBundle, value: "", comment: "")
    }

    // this is based on the libidn2 documentation.
    static func localizedString(from idn2Code: idn2_rc) -> String {
        switch idn2Code {
        case IDN2_OK:
            return _localizedString("ios_error_ok")
        case IDN2_MALLOC,
             IDN2_NO_CODESET,
             IDN2_ICONV_FAIL,
             IDN2_ENCODING_ERROR,
             IDN2_NFC,
             IDN2_PUNYCODE_BIG_OUTPUT,
             IDN2_PUNYCODE_OVERFLOW,
             IDN2_INVALID_FLAGS:
            let format = _localizedString("ios_idn_error_internal_format")
            return String(format: format, Int(idn2Code.rawValue))

        case IDN2_PUNYCODE_BAD_INPUT:
            return _localizedString("ios_error_idn_invalid_punycode")

        case IDN2_TOO_BIG_DOMAIN:
            return _localizedString("ios_error_idn_domain_too_big")

        case IDN2_TOO_BIG_LABEL:
            return _localizedString("ios_error_idn_label_too_big")

        case IDN2_INVALID_ALABEL:
            return _localizedString("ios_error_idn_invalid_alabel")

        case IDN2_UALABEL_MISMATCH:
            return _localizedString("ios_error_idn_ualabel_mismatch")

        case IDN2_NOT_NFC:
            return _localizedString("ios_error_idn_not_nfc")

        case IDN2_2HYPHEN:
            return _localizedString("ios_error_idn_2hyphen")

        case IDN2_HYPHEN_STARTEND:
            return _localizedString("ios_error_idn_hyphen_startend")

        case IDN2_LEADING_COMBINING:
            return _localizedString("ios_error_idn_leading_combining")

        case IDN2_DISALLOWED:
            return _localizedString("ios_error_idn_disallowed")

        case IDN2_CONTEXTJ:
            return _localizedString("ios_error_idn_contextj")

        case IDN2_CONTEXTJ_NO_RULE:
            return _localizedString("ios_error_idn_contextj_no_rule")

        case IDN2_CONTEXTO:
            return _localizedString("ios_error_idn_contexto")

        case IDN2_CONTEXTO_NO_RULE:
            return _localizedString("ios_error_idn_contexto_no_rule")

        case IDN2_UNASSIGNED:
            return _localizedString("ios_error_idn_unassigned")

        case IDN2_BIDI:
            return _localizedString("ios_error_idn_bidi")

        case IDN2_DOT_IN_LABEL:
            return _localizedString("ios_error_idn_dot_in_label")

        case IDN2_INVALID_TRANSITIONAL:
            return _localizedString("ios_error_idn_invalid_transitional")

        case IDN2_INVALID_NONTRANSITIONAL:
            return _localizedString("ios_error_idn_invalid_nontransitional")

        case IDN2_ALABEL_ROUNDTRIP_FAILED:
            return _localizedString("ios_error_idn_alabel_roundtrip_failed")

        default:
            let format = _localizedString("ios_idn_error_internal_format")
            return String(format: format, Int(idn2Code.rawValue))
        }
    }

}
