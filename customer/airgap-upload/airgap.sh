#!/bin/bash

## Script to upload airgap bundle from the command line. 

set -ex

SCRIPT_DIR=.
AIRGAP_FILE_NAME=kudo.airgap
LICENSE_FILE_NAME=License.yaml
KOTS_NAMESPACE=default
REGISTRY_HOST=10.96.2.115
REGISTRY_NAMESPACE=kurl
REGISTRY_USERNAME=kurl
REGISTRY_PASSWORD=1mtqTFDQF  # Password from registry-creds secret in kurl namespace
VM_IP=10.96.1.88             # IP address of KURL proxy
KOTS_PWD=kQRkHo08H           # Password given on initial install
LICENSE_FILE_CONTENTS="$(cat "${SCRIPT_DIR}/${LICENSE_FILE_NAME}" | awk '{printf "%s\\n", $0}')"

# log in
BEARER_TOKEN="$(curl -k -X POST -H 'Content-Type: application/json' "https://${VM_IP}:8800/api/v1/login" \
                -d "{\"password\":\"${KOTS_PWD}\"}" | jq --join-output '.token' | awk '{print $2}')"

# upload license
APP_SLUG="$(curl -k -v -X POST -H "Authorization: ${BEARER_TOKEN}" -H 'Content-Type: application/json' "https://${VM_IP}:8800/graphql" \
    -d "{\"operationName\":\"uploadKotsLicense\",\"variables\":{\"value\":\"${LICENSE_FILE_CONTENTS}\"},
    \"query\":\"mutation uploadKotsLicense(\$value: String!) {  uploadKotsLicense(value: \$value) {  slug  }}\"}" | jq --join-output .data.uploadKotsLicense.slug)"

THEPOD=$(kubectl get pod -l app=kotsadm-operator -o name | sed 's/pod\///')
BASIC_AUTHSTRING=$((kubectl exec -it $THEPOD -- bash -c 'printf user:$KOTSADM_TOKEN | base64') | sed 's/[^a-zA-Z0-9+//=]//g')
KOTSADM_AUTHSTRING=$BASIC_AUTHSTRING

# airgap reset
curl -k -v -X POST \
    -H "Authorization: Kots ${KOTSADM_AUTHSTRING}" \
    -H 'Content-Type: application/json' \
    https://${VM_IP}:8800/api/v1/airgap/reset

# upload airgap bundle
curl -k -v -X POST \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    https://${VM_IP}:8800/api/v1/app/airgap \
    -F "file=@${SCRIPT_DIR}/${AIRGAP_FILE_NAME}" \
    -F "registryHost=${REGISTRY_HOST}" \
    -F "namespace=${REGISTRY_NAMESPACE}" \
    -F "username=${REGISTRY_USERNAME}" \
    -F "password=${REGISTRY_PASSWORD}"