#!/bin/sh

#  ci-post-clone.sh
#  Multisig
#
#  Created by Dirk Jäckel on 17.07.23.
#  Copyright © 2023 Gnosis Ltd. All rights reserved.

env
echo `pwd`
cd ..
bin/configure.sh
