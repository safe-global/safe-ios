#! /usr/bin/env bash
set -e +o pipefail

CONFIG_DIR=Multisig/Cross-layer/Configuration
EXAMPLE_CONFIG="${CONFIG_DIR}/Config.Example.xcconfig"
CONFIG_FILE="${CONFIG_DIR}/Config.xcconfig"

echo `env` > _env.txt

cp "${EXAMPLE_CONFIG}" "${CONFIG_FILE}"

# replace the example value with the environment key
if ! [ -z ${CONFIG_KEY_STAGING} ]; then
    sed -i '' "s;your-staging-config-key;${CONFIG_KEY_STAGING};g" "${CONFIG_FILE}"
fi

if ! [ -z ${CONFIG_KEY_PROD} ]; then
    sed -i '' "s;your-production-config-key;${CONFIG_KEY_PROD};g" "${CONFIG_FILE}"
fi

# decrypt configuration file with the key from environment
FIREBASE_ENCRYPTED="Firebase.dat"
FIREBASE_DST="Multisig/Cross-layer/Analytics"
bin/decrypt.sh "${ENCRYPTION_KEY}" "${FIREBASE_ENCRYPTED}" "${FIREBASE_DST}"
