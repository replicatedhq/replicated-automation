#!/bin/bash -v
set -e

# Run this from a machine with kubectl access to the cluster. 

# Generate access_key and secret_key from rook-ceph `kurl` user
OP_POD_NAME=$(kubectl get pod -l app=rook-ceph-operator -n rook-ceph -o jsonpath='{.items[].metadata.name}')
ACCESS_KEY=$(kubectl -n rook-ceph exec -it ${OP_POD_NAME} -- radosgw-admin user info --uid kurl | grep access_key | awk '{print $2}' | sed 's/\"//g' - | sed 's/,//g' -)
SECRET_KEY=$(kubectl -n rook-ceph exec -it ${OP_POD_NAME} -- radosgw-admin user info --uid kurl | grep secret_key | awk '{print $2}' | sed 's/\"//g' - )

# Create credentials-velero file, backing it up if it already exists
cp credentials-velero credentials-velero.bak 2>/dev/null || :
cat <<EOF > credentials-velero
[default]
aws_access_key_id=${ACCESS_KEY}
aws_secret_access_key=${SECRET_KEY}
EOF

# Delete velero namespace, if it exists (to ready for new configuration)
set +e; kubectl delete namespace velero; set -e

# Restore prior configuration. 
ROOK_RGW_IP=$(k get svc rook-ceph-rgw-rook-ceph-store -o jsonpath='{.spec.clusterIP}' -n rook-ceph)
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.0.0 \
  --bucket velero \
  --backup-location-config region=us-east-1,s3ForcePathStyle="true",s3Url=http://rook-ceph-rgw-rook-ceph-store.rook-ceph,publicUrl=http://${ROOK_RGW_IP} \
  --secret-file ./credentials-velero \
  --use-restic
