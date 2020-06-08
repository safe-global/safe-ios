#! /usr/bin/env bash

CONFIG_DIR=Multisig/Cross-layer/Configuration
EXAMPLE_CONFIG="${CONFIG_DIR}/Config.Example.xcconfig"
CONFIG_FILE="${CONFIG_DIR}/Config.xcconfig"

cp "${EXAMPLE_CONFIG}" "${CONFIG_FILE}"

# replace the example value with the environment key
sed -i '' "s/USE_YOUR_OWN_INFURA_KEY_HERE/${INFURA_KEY}/g" "${CONFIG_FILE}"
