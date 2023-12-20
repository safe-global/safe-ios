# Safe{Wallet} iOS app
Safe Multisig iOS app.

# Coding Style
As of 18.03.2021, this project adopted the [Google's Swift Style Guide](https://google.github.io/swift/) as well as [Apple's Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/). 

We adopt the following modifications to the above guidelines:
- 4-space indentation instead of 2-space
- Line wrapping at 120 characters

Inconsistencies and differences between the project's source code and the aforementioned guidelines shall be corrected as a by-product of the normal work on feature development and bug fixes.

Notable differences that we should look for:
- alphabetical sorting of import statements
- separation of testable import with blank line
- one statement per line
- trailing commas after last array or dictionary element
- Add documentation to every (public) declaration.
- Delegate methods: first object is the source.
- force-try! Is forbidden except in unit test, test-only code, or in case of programmer error.
- Force-unwrap and force-cast is strongly discouraged (except unit tests or programmer error).
- Implicitly unwrapped optionals should be avoided whenever possible.
  - Except in @IBOutlet, Objective-C APIs, unit tests or programmer error.
- Access level is specified on each member of the extension (if it is not default).
- Graphical playground literals - use only in Playgrounds, not in code. 

# Configuration

In order for the app to be functional, you need to create the protected configuration file
with API keys in it (at least the `INFURA_API_KEY`).

You can find an example of unprotected configuration file at `Multisig/Cross-layer/Configurations/apis-staging.example.json`

You then encrypt that file using the `secconfig` tool:

    $> bin/secconfig encrypt Multisig/Cross-layer/Configurations/apis-staging.example.json Multisig/Cross-layer/Configuration/apis.bundle/apis-staging.enc.json
    <TOOL OUTPUT ENDING WITH '='>

The tool outputs the encryption key with which the configuration was encrypted. Export that value as an environment variable
    $> export CONFIG_KEY_STAGING="..."

Then, repeat the same for the production environment (in that case the files would be named `apis-prod.example.json` and `apis-prod.enc.json`, and the environment variable is `CONFIG_KEY_PROD`).

**NOTE: Do not commit unencrypted files with real API keys `apis-staging.exmaple.json` or `apis-prod.example.json` to git! Otherwise you will compromise them.**

You can find more details about the `secconfig` tool in the script `Pakcages/SecureConfig/Sources/secconfig/main.swift`

*Optional*. If you use the encrypted `Firebase.dat` configuration, provide the encryption key as 
environment variable.

    $> export ENCRYPTION_KEY="..."

The app will work without it, so that step can be skipped.

Then, run the configure script to install the Config.xcconfig

    $> bin/configure.sh

Now you are ready to build the project.
