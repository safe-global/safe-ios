#! /usr/bin/env bash
set -e +o pipefail

CONFIG_DIR=Multisig/Cross-layer/Configuration
EXAMPLE_CONFIG="${CONFIG_DIR}/Config.Example.xcconfig"
CONFIG_FILE="${CONFIG_DIR}/Config.xcconfig"

cp "${EXAMPLE_CONFIG}" "${CONFIG_FILE}"

# replace the example value with the environment key
sed -i '' "s/USE_YOUR_OWN_INFURA_KEY_HERE/${INFURA_KEY}/g" "${CONFIG_FILE}"
sed -i '' "s/YOUR_INTERCOM_APP_ID/${INTERCOM_APP_ID}/g" "${CONFIG_FILE}"
sed -i '' "s/YOUR_INTERCOM_API_KEY/${INTERCOM_API_KEY}/g" "${CONFIG_FILE}"

# replace the ssl pinning flag with the parameter value
if ! [ -z ${SSL_ENFORCE_PINNING} ]; then
    sed -i '' "s/SSL_ENFORCE_PINNING = .*/SSL_ENFORCE_PINNING = ${SSL_ENFORCE_PINNING}/g" "${CONFIG_FILE}"
fi

# decrypt configuration file with the key from environment
FIREBASE_ENCRYPTED="Firebase.dat"
FIREBASE_DST="Multisig/Cross-layer/Analytics"
bin/decrypt.sh "${ENCRYPTION_KEY}" "${FIREBASE_ENCRYPTED}" "${FIREBASE_DST}"
