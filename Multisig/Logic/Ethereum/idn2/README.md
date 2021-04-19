
# Info

This folder was manually copied from the [pod-idn2](https://github.com/gnosis/pod-idn2) repository's `swiftpm` branch.

Unfortunately at the moment, swift package that wraps the XCFramework binary target containing a C library with a modulemap file
cannot be archived (built for release) because compiler doesn't see the modulemap file inside the XCFramework.

If you need to recompile the libraries, head to the repository above and find there a script that does so. Then just replace the files in 
this folder with the output files.

If you changed the Localizable.strings file in the repository, then you need to copy-paste the contents to the Localizable.strings file
of this project.

For contact, you can find me on [GitHub](https://github.com/DmitryBespalov). Happy coding!
