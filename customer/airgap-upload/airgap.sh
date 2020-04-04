#!/bin/bash

## Script to upload airgap bundle from the command line. 

set -ex

KOTS_PWD="$1"
AIRGAP_FILENAME="$2"
LICENSE_FILENAME="$3"
KOTS_NAMESPACE="$4"        # Default 'default'
REGISTRY_USERNAME="$5"     # Default 'kurl'
REGISTRY_PASSWORD="$6"     # Password from registry-creds secret in kurl namespace
REGISTRY_NAMESPACE="$7"    # Registry namespace, default 'kurl'
REGISTRY_HOST="$8"
IS_EXISTING=$(kubectl get -o jsonpath="{.spec.clusterIP}" service registry -n kurl >> /dev/null 2>&1; echo $?)

function usage(){
  echo "For embedded clusters, ssh into the cluster and run:"
  echo "  $0 [pwd] [airgap] [license]"
  echo 
  echo "For existing clusters, start admin console on localhost:8800 and run: "
  echo "  $0 [pwd] [airgap] [license] [ns] [reg-user] [reg-pwd] [reg-ns] [reg-host]"
  echo 
  echo "Parameters:"
  echo "  Name          Required   Default Value  Note                                 "
  echo " |-------------|----------|--------------|-------------------------------------"
  echo "  pwd           required                  Password used for admin console      "
  echo "  airgap        optional   bundle.airgap  Filename of the airgap bundle        "
  echo "  license       optional   license.yaml   Filename of the license              "  
  echo "  ns            optional   default        Namespace where KOTS resides         "
  echo "  reg-user      optional                  Username to use for registry         "
  echo "  reg-pwd       optional                  Password to use for registry         "
  echo "  reg-ns        optional   <app-slug>     Namespace to use with registry images"
  echo "  reg-host      optional                  Hostname/IP of the registry          "
  echo 
  echo "Examples: " 
  echo "  $0 1mtwFTWE"
  echo "  $0 1mtwFTWE bundle.airgap license.yaml"
  echo "  $0 1mtwFTWE my-bundle.airgap my-license.yaml kots"
  echo "  $0 1mtwFTWE my-bundle.airgap my-license.yaml kots reguser 38dh2wjsy reguser index.docker.io"
  echo "  (Latter two examples only relevant for existing cluster installs)"
  echo ""
  exit 1
}

if [[ -z ${KOTS_PWD} ]]; then
  echo "Required Parameter: 'pwd' is missing.\n\n"; usage 
fi
if [[ -z ${AIRGAP_FILENAME} ]]; then
  AIRGAP_FILENAME="bundle.airgap"
fi
if [[ -z ${LICENSE_FILENAME} ]]; then
  LICENSE_FILENAME="license.yaml"
fi
if [[ -z ${KOTS_NAMESPACE} ]]; then
  KOTS_NAMESPACE="default"
fi
if [[ -z ${REGISTRY_NAMESPACE} ]]; then
  if [[ ${IS_EXISTING} == "0" ]]; then
    REGISTRY_NAMESPACE="kurl"
  else 
    echo "Parameter: 'reg-ns' is required for existing cluster installations."; usage
  fi
fi
if [[ -z ${REGISTRY_USERNAME} ]]; then
  if [[ ${IS_EXISTING} == "0" ]]; then
    REGISTRY_USERNAME=$(kubectl get secret registry-creds -o yaml | grep ".dockerconfigjson:" | awk '{print $2}' | base64 --decode | sed 's/\"/\n/g' - | awk 'NR==8 {print $1}')
  else 
    echo "Parameter: 'reg-user' is required for existing cluster installations."; usage
  fi
fi
if [[ -z ${REGISTRY_PASSWORD} ]]; then
  if [[ ${IS_EXISTING} == "0" ]]; then
    REGISTRY_PASSWORD=$(kubectl get secret registry-creds -o yaml | grep ".dockerconfigjson:" | awk '{print $2}' | base64 --decode | sed 's/\"/\n/g' - | awk 'NR==12 {print $1}')
  else 
    echo "Parameter: 'reg-pwd' is required for existing cluster installations."; usage
  fi
fi
# Determine registry host IP
if [[ -z ${REGISTRY_HOST} ]]; then
  if [[ ${IS_EXISTING} == "0" ]]; then
    REGISTRY_HOST=$(kubectl get secret registry-creds -o yaml | grep ".dockerconfigjson:" | awk '{print $2}' | base64 --decode | sed 's/\"/\n/g' - | awk 'NR==4 {print $1}')
  else 
    echo "Parameter: 'reg-host' is required for existing cluster installations."; usage
  fi
fi
# Determine proxy IP
if [[ ${IS_EXISTING} == "0" ]]; then
  KOTSADM_URL="https://$(kubectl get services -o jsonpath="{.items[?(@.spec.ports[*].port == 8800)].spec.clusterIP}"):8800"
else 
  KOTSADM_URL="http://localhost:8800"
fi

SCRIPT_DIR=.
LICENSE_FILE_CONTENTS="$(cat "${SCRIPT_DIR}/${LICENSE_FILENAME}" | awk '{printf "%s\\n", $0}')"

# log in and get tokens
BEARER_TOKEN_CURL="$(curl -k -X POST -H 'Content-Type: application/json' "${KOTSADM_URL}/api/v1/login" -d "{\"password\":\"${KOTS_PWD}\"}")"
BEARER_TOKEN="$(echo -e ${BEARER_TOKEN_CURL//\"/\\n} | awk 'NR==4 {print $2}')"

THEPOD=$(kubectl get pod -l app=kotsadm-operator -o name -n ${KOTS_NAMESPACE} | sed 's/pod\///')
BASIC_AUTHSTRING=$((kubectl -n ${KOTS_NAMESPACE} exec -it $THEPOD -- bash -c 'printf user:$KOTSADM_TOKEN | base64') | sed 's/[^a-zA-Z0-9+//=]//g')

# upload license
set +H
APP_SLUG_CURL="$(curl -k -X POST -H "Authorization: ${BEARER_TOKEN}" -H 'Content-Type: application/json' "${KOTSADM_URL}/graphql" \
    -d "{\"operationName\":\"uploadKotsLicense\",\"variables\":{\"value\":\"${LICENSE_FILE_CONTENTS}\"},
    \"query\":\"mutation uploadKotsLicense(\$value: String!) {  uploadKotsLicense(value: \$value) {  slug  }}\"}")"
APP_SLUG="$(echo -e ${APP_SLUG_CURL//\"/\\n} | awk 'NR==8 {print $1}')"
set -H

# airgap reset
curl -k -v -X POST \
    -H "Authorization: Kots ${BASIC_AUTHSTRING}" \
    -H 'Content-Type: application/json' \
    ${KOTSADM_URL}/api/v1/airgap/reset

# upload airgap bundle
curl -k -v -X POST \
    -H "Authorization: Bearer ${BEARER_TOKEN}" \
    ${KOTSADM_URL}/api/v1/app/airgap \
    -F "file=@${SCRIPT_DIR}/${AIRGAP_FILENAME}" \
    -F "registryHost=${REGISTRY_HOST}" \
    -F "namespace=${REGISTRY_NAMESPACE}" \
    -F "username=${REGISTRY_USERNAME}" \
    -F "password=${REGISTRY_PASSWORD}"