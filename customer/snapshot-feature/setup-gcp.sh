#!/bin/bash

## Script to help set up GCP storage for snapshot functionality
## Requires: gsutil and for your account project to be linked via command line. 
## Validated on OSX shell

BUCKET_NAME=replsnap-$(LC_CTYPE=C tr -dc a-z0-9 < /dev/urandom | head -c 16 | xargs)
## Create the bucket
gsutil mb -l US gs://$BUCKET_NAME
## Create the iam account
gcloud iam service-accounts create "$BUCKET_NAME" --display-name="$BUCKET_NAME"
## Create the key linked to the IAM account and save
PROJECT_NAME=$(gcloud config list --format 'value(core.project)' 2>/dev/null)
IAM_ACCT="${BUCKET_NAME}@${PROJECT_NAME}.iam.gserviceaccount.com"
gcloud iam service-accounts keys create "./${BUCKET_NAME}.key" --iam-account="$IAM_ACCT"

## Add role to service account. 
gcloud projects add-iam-policy-binding $PROJECT_NAME \
  --member serviceAccount:$IAM_ACCT \
  --role "roles/storage.admin"

## Copy key to Replicated Admin Console: /app/airgapped/snapshots/settings
pbcopy < "./${BUCKET_NAME}.key" 
printf "\n\nBUCKET_NAME: $BUCKET_NAME\n\n"
read -p "Enter bucket name, path, and paste key to Replicated Admin Console /app/airgapped/snapshots/settings"

