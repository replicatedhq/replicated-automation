#!/bin/bash
set -e
source ./vars.sh

echo "Connecting to Cluster"
kubectl config use-context $KUBE_CONTEXT

echo "Startup Cloud Instances"
gcloud compute instances start $I1 --zone $I1Z & gcloud compute instances start $I2 --zone $I2Z & gcloud compute instances start $I3 --zone $I3Z & gcloud compute instances start $I4 --zone $I4Z & gcloud compute instances start $I5 --zone $I5Z & gcloud compute instances start $I6 --zone $I6Z & wait

echo "Waiting for Node Ready"
until (kubectl wait --for=condition=Ready node/$I1); do sleep 1; done 
kubectl wait --for=condition=Ready node/$I2 & kubectl wait --for=condition=Ready node/$I3 & kubectl wait --for=condition=Ready node/$I4 & kubectl wait --for=condition=Ready node/$I5 & kubectl wait --for=condition=Ready node/$I6 & wait

echo "Scaling Ceph"
kubectl -n rook-ceph-system scale deploy rook-ceph-operator --replicas=1
kubectl rollout status deployment.extensions/rook-ceph-operator --namespace rook-ceph-system
sleep 10

# Wait for Ceph to be ready
CEPH_HEALTH=$(kubectl exec -n rook-ceph -i --namespace rook-ceph-system $(kubectl get -n rook-ceph-system pod -l "app=rook-ceph-operator" -o jsonpath='{.items[0].metadata.name}') -- ceph health)
while [ "$CEPH_HEALTH" != "HEALTH_OK" ]
do 
    CEPH_HEALTH=$(kubectl exec -n rook-ceph -i --namespace rook-ceph-system $(kubectl get -n rook-ceph-system pod -l "app=rook-ceph-operator" -o jsonpath='{.items[0].metadata.name}') -- ceph health)
    echo $CEPH_HEALTH
done 
echo "Ceph is Ready"

echo "Starting Replicated"
REPLICATED_POD_ID=$(kubectl get pod -l "app=replicated,tier=master" -o name | sed 's/pod\///')
REPLICATED_APP_ID=$(kubectl exec $REPLICATED_POD_ID replicated apps | awk 'NR==2 {print $1}')
kubectl exec $REPLICATED_POD_ID replicated app $REPLICATED_APP_ID start 

echo "Successful Startup"