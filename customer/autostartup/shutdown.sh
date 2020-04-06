#!/bin/bash
set -e
source ./vars.sh

echo "Connecting to Cluster"
kubectl config use-context $KUBE_CONTEXT

echo "Stopping Replicated"
REPLICATED_POD_ID=$(kubectl get pod -l "app=replicated,tier=master" -o name | sed 's/pod\///')
kubectl exec $REPLICATED_POD_ID replicatedctl app stop --force

echo 'Delete replicated-shared-fs-snapshotter deployment'
kubectl delete deployments/replicated-shared-fs-snapshotter

echo "Stopping Ceph"
kubectl -n rook-ceph-system scale deploy rook-ceph-operator --replicas=0
kubectl rollout status deployment.extensions/rook-ceph-operator --namespace rook-ceph-system

echo "Cordoning Nodes"
kubectl cordon $I1 & kubectl cordon $I2 & kubectl cordon $I3 & kubectl cordon $I4 & kubectl cordon $I5 & kubectl cordon $I6 & wait

echo "Node Shutdown"
# Equivalent AWS commands (for each node + LB): 
# * aws ec2 stop-instances --instance-ids i-07c817fd03dba9e0f
# * aws ec2 wait instance-stopped --instance-ids i-07c817fd03dba9e0f
gcloud compute instances stop $I1 --zone $I1Z & gcloud compute instances stop $I2 --zone $I2Z & gcloud compute instances stop $I3 --zone $I3Z & gcloud compute instances stop $I4 --zone $I4Z & gcloud compute instances stop $I5 --zone $I5Z & gcloud compute instances stop $I6 --zone $I6Z & wait
gcloud compute instances stop $LBZ --zone $I1Z & wait

echo "Successful Shutdown"