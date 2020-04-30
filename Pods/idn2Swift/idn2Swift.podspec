Pod::Spec.new do |spec|
  spec.name         = "idn2Swift"
  spec.version      = "0.0.1"
  spec.summary      = "This spec provides you with the iOS build of the Libidn2."
  spec.description  = <<-DESC
The library contains functionality to convert internationalized domain names to and from ASCII Compatible Encoding (ACE), following the IDNA2008 and TR46 standards.

The API consists of two main functions, idn2_to_ascii_8z for converting data from UTF-8 to ASCII Compatible Encoding (ACE), and idn2_to_unicode_8z8z to convert ACE names into UTF-8 format. There are several variations of these main functions, which accept UTF-32, or input in the local system encoding. All functions assume zero-terminated strings.

This library is backwards (API) compatible with the libidn library. Replacing the idna.h header with idn2.h into a program is sufficient to switch the application from IDNA2003 to IDNA2008 as supported by this library.

Libidn2 is believed to be a complete IDNA2008 and TR46 implementation, it contains an extensive test-suite, and is included in the continuous fuzzing project OSS-Fuzz.
                   DESC
  spec.homepage     = "https://github.com/gnosis/libidn2"
  spec.license      = "LGPLv3+"
  spec.authors             = {
    "Nikos Mavrogiannopoulos" => "nmav@gnutls.org",
    "Simon Josefsson" => "simon@josefsson.org",
    "Tim Rühsen" => "tim.ruehsen@gmx.de"
  }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/DmitryBespalov/pod-idn2.git", :branch => "master" }
  spec.source_files = "idn2/include/idn2.h", "Source/IDN.swift"
  spec.preserve_paths = "idn2", "unistring"
  spec.public_header_files = "idn2/include/idn2.h"
  spec.xcconfig = {'HEADER_SEARCH_PATHS' => '"$(SRCROOT)/Pods/idn2/idn2/include"'}
  spec.vendored_libraries = "unistring/lib/libunistring.a", "idn2/lib/libidn2.a"
  spec.libraries = "iconv"

  spec.static_framework = true
  
  spec.resource_bundles = {
    'idn2SwiftResources' => ['Resources/**/*']
  }

  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/IDNTests.swift'
  end
end
