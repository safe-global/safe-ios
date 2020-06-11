#! /usr/bin/env bash

KEY="$1"
INPUT="$2"
OUTPUT="$3"

TEMP="${OUTPUT}.tar"

tar cvf "${TEMP}" "${INPUT}"
openssl aes-256-cbc -k "${KEY}" -in "${TEMP}" -out "${OUTPUT}"
rm -f "${TEMP}"
