#!/bin/sh

#  ci-post-clone.sh
#  Multisig
#
#  Created by Dirk Jäckel on 17.07.23.
#  Copyright © 2023 Gnosis Ltd. All rights reserved.

# For documentaion on this see: https://developer.apple.com/documentation/xcode/writing-custom-build-scripts
env
echo `pwd`
# I don't trust our scripts to work from anywhere
cd ..
bin/configure.sh
