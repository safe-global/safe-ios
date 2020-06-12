# safe-multisig-ios
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

