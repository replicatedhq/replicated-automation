#!/bin/bash

## Script to help set up GCP storage for snapshot functionality
## Requires: gsutil and for your account project to be linked via command line. 
## Validated on OSX shell following the instructions here: https://github.com/vmware-tanzu/velero-plugin-for-gcp#setup

## Get necessary gcloud settings
PROJECT_ID=$(gcloud config get-value project)

## Create the bucket
BUCKET=replsnap$(LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 16 | xargs)
gsutil mb -l US gs://$BUCKET

## Create the iam service account
gcloud iam service-accounts create "$BUCKET" --display-name="Velero $BUCKET"

## Set the $SERVICE_ACCOUNT_EMAIL variable to match its email value.
SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list \
  --filter="displayName:Velero $BUCKET" \
  --format 'value(email)')

## Attach policies to give velero the necessary permissions to function
ROLE_PERMISSIONS=(
    compute.disks.get
    compute.disks.create
    compute.disks.createSnapshot
    compute.snapshots.get
    compute.snapshots.create
    compute.snapshots.useReadOnly
    compute.snapshots.delete
    compute.zones.get
)

gcloud iam roles create velero.server.$BUCKET \
    --project $PROJECT_ID \
    --title "Velero Server $BUCKET" \
    --permissions "$(IFS=","; echo "${ROLE_PERMISSIONS[*]}")"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT_EMAIL \
    --role projects/$PROJECT_ID/roles/velero.server.$BUCKET

gsutil iam ch serviceAccount:$SERVICE_ACCOUNT_EMAIL:objectAdmin gs://${BUCKET}

## Create a service account key, specifying an output file (credentials-velero) in your local directory:
gcloud iam service-accounts keys create credentials-velero.$BUCKET \
    --iam-account $SERVICE_ACCOUNT_EMAIL

printf "\n\nBUCKET: $BUCKET\n"
printf "Key File: credentials-velero.$BUCKET\n\n"

## Install Velero
velero install \
    --provider gcp \
    --plugins velero/velero-plugin-for-gcp:v1.0.1 \
    --bucket $BUCKET \
    --secret-file ./credentials-velero.$BUCKET \
    --use-restic
