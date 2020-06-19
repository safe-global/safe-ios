# safe-multisig-ios

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/b89dec9e0b5b486c9d1c53d28d546605)](https://app.codacy.com/manual/DmitryBespalov/safe-ios?utm_source=github.com&utm_medium=referral&utm_content=gnosis/safe-ios&utm_campaign=Badge_Grade_Settings)

Gnosis Safe Multisig iOS app.

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

