#!/bin/bash

## Script to upload airgap bundle from the command line. 
​
set -ex
​
SCRIPT_DIR=.
AIRGAP_FILE_NAME=sentry.airgap
LICENSE_FILE_NAME=stage-ethan-kots-beta.yaml
KOTS_NAMESPACE=ethan-kots
REGISTRY_HOST=ttl.sh
REGISTRY_NAMESPACE=ethan
REGISTRY_USERNAME=
REGISTRY_PASSWORD=
LICENSE_FILE_CONTENTS="$(cat "${SCRIPT_DIR}/${LICENSE_FILE_NAME}" | awk '{printf "%s\\n", $0}')"
​
# log in
BEARER_TOKEN="$(curl -X POST \
    -H 'Content-Type: application/json' \
    'http://localhost:8800/api/v1/login' \
    -d "{\"password\":\"testing\"}" | jq --join-output '.token')"
​
# upload license
APP_SLUG="$(curl -v -X POST \
    -H "Authorization: ${BEARER_TOKEN}" \
    -H 'Content-Type: application/json' \
    'http://localhost:8800/graphql' \
    -d "{\"operationName\":\"uploadKotsLicense\",\"variables\":{\"value\":\"${LICENSE_FILE_CONTENTS}\"},\"query\":\"mutation uploadKotsLicense(\$value: String!) {  uploadKotsLicense(value: \$value) {  slug  }}\"}" | jq --join-output .data.uploadKotsLicense.slug)"
​
# get auth string
KOTSADM_AUTHSTRING="$(kubectl get secret kotsadm-authstring --namespace $KOTS_NAMESPACE -o yaml | awk 'NR==3 {print $2}' | base64 --decode | awk '{print $2}')"
​
# airgap reset
curl -v -X POST \
    -H "Authorization: Kots ${KOTSADM_AUTHSTRING}" \
    -H 'Content-Type: application/json' \
    http://localhost:8800/api/v1/kots/airgap/reset/${APP_SLUG}
​
# upload airgap bundle
curl -v -X POST \
    -H "Authorization: Kots ${KOTSADM_AUTHSTRING}" \
    http://localhost:8800/api/v1/kots/airgap \
    -F "file=@${SCRIPT_DIR}/${AIRGAP_FILE_NAME}" \
    -F "registryHost=${REGISTRY_HOST}" \
    -F "namespace=${REGISTRY_NAMESPACE}" \
    -F "username=${REGISTRY_USERNAME}" \
    -F "password=${REGISTRY_PASSWORD}"