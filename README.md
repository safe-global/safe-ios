# safe-multisig-ios
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

Export your Infura project key as an `INFURA_KEY` environment variable:

    $> export INFURA_KEY="..."


*Optional*. If you use the encrypted `Firebase.dat` configuration, provide the encryption key as 
environment variable.

    $> export ENCRYPTION_KEY="..."

The app will work without it, so that step can be skipped.

Then, run the configure script to install the Config.xcconfig

    $> bin/configure.sh

Now you are ready to build the project.

