#! /usr/bin/env bash
set -e +o pipefail

KEY="$1"
INPUT="$2"
OUTPUT="$3"

TEMP="$OUTPUT.tar"

if [ -z ${KEY} ] || [ ! -f "${INPUT}" ] ; then
  # if decryption key is not set or input file does not exist, skip this.
  exit 0
fi

mkdir -p "${OUTPUT}"
openssl aes-256-cbc -k "${KEY}" -in "${INPUT}" -out "${TEMP}" -d
tar xf "${TEMP}" -C "${OUTPUT}"
rm -rf "${TEMP}"
