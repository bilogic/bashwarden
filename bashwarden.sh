#!/bin/bash

set -o allexport
source .bashwarden.env
set +o allexport

function authenticate() {
    token=$(
        curl -X POST $bitwarden_host/identity/connect/token \
            -d "device_type=Server&device_name=bashwarden&device_identifier=bashwarden&grant_type=client_credentials&scope=api&client_id=$client_id&client_secret=$client_secret" \
            -H 'Content-Type: application/x-www-form-urlencoded' |
            jq -j '.access_token'
    )

    protected_symmetric_key=$(
        curl --request GET \
            --url "$bitwarden_host/api/sync?excludeDomains=true" \
            -H "Authorization: Bearer $token" | jq -r '.Profile.Key'
    )
}

function get() {
    cipher_object=$(
        curl --request GET \
            --url "$bitwarden_host/api/sync?excludeDomains=true" \
            -H "Authorization: Bearer $token" | jq -r ".Ciphers[] | select(.Id == \"$cipher_id\")"
    )
}

function put() {
    # @TODO need to form cipher_payload, see JSON
    curl --request PUT \
        --url "$bitwarden_host/api/ciphers/$cipher_id" \
        -d $cipher_payload \
        -H "Authorization: Bearer $token"
}

authenticate
get

echo "**************************************\r\n"
echo $protected_symmetric_key
echo $cipher_object
echo "**************************************\r\n"

exit 0

# Below are examples/references, code that we probably need to complete this script

## https://github.com/jcs/rubywarden/blob/master/API.md#cipher-encryption-and-decryption

## Encrypt + Decrypt using aes-256-cbc
hex_iv=1234567890abcdef
base64_iv=$(echo $hex_iv | xxd -r -p | base64)
iv=$(echo $base64_iv | base64 --decode | xxd -p)
ciper_text=$(echo "We're blown. Run" | openssl enc -aes-256-cbc -nosalt -e -K '2222233333232323' -iv "$iv" | base64)
echo $ciper_text | base64 --decode | openssl enc -aes-256-cbc -d -K '2222233333232323' -iv "$iv"
