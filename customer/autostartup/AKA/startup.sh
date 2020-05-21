#!/bin/bash
set -e
source ./vars.sh

echo "Connecting to Cluster"
kubectl config use-context $KUBE_CONTEXT

echo "Startup Cloud Instances"
# Equivalent AWS command: (For each node + LB): aws ec2 start-instances --instance-ids i-07b517fd03dba9e0f && aws ec2 wait instance-running --instance-ids i-07c817fd03dba9e0f
gcloud compute instances start $LB --zone $LBZ & wait
gcloud compute instances start $I1 --zone $I1Z & gcloud compute instances start $I2 --zone $I2Z \
  & gcloud compute instances start $I3 --zone $I3Z & gcloud compute instances start $I4 --zone $I4Z \
  & gcloud compute instances start $I5 --zone $I5Z & gcloud compute instances start $I6 --zone $I6Z & wait
sleep 20

echo "Waiting for Node Ready"
until (kubectl wait --for=condition=Ready node/$I1); do sleep 1; done 
until (kubectl wait --for=condition=Ready node/$I2); do sleep 1; done 
until (kubectl wait --for=condition=Ready node/$I3); do sleep 1; done 
until (kubectl wait --for=condition=Ready node/$I4); do sleep 1; done 
until (kubectl wait --for=condition=Ready node/$I5); do sleep 1; done 
until (kubectl wait --for=condition=Ready node/$I6); do sleep 1; done 
kubectl wait --for=condition=Ready node/$I2 & kubectl wait --for=condition=Ready node/$I3 \
  & kubectl wait --for=condition=Ready node/$I4 & kubectl wait --for=condition=Ready node/$I5 \
  & kubectl wait --for=condition=Ready node/$I6 & wait

echo "Waiting for Kubernetes to become available for scaling Ceph"
set +e
SCALE_CMD="kubectl -n rook-ceph-system scale deploy rook-ceph-operator --replicas=1"
ATTEMPTS=0
$SCALE_CMD
RESULT=$?
until [ $RESULT -eq 0 ] || [ $ATTEMPTS -eq 60 ]; do
  $SCALE_CMD
  RESULT=$?
  ATTEMPTS=$((ATTEMPTS + 1))
  echo "Waiting for Kubernetes to become available for scaling Ceph ($ATTEMPTS of 60)"
  sleep 2
done

if [ $ATTEMPTS -eq 60 ]; then
    echo "Aborting... Unable to query Kubernetes after $ATTEMPTS attempts."
    echo exit 1
fi

echo "Waiting for Ceph deployment to roll out"
kubectl rollout status deployment.extensions/rook-ceph-operator --namespace rook-ceph-system

echo "Waiting for Ceph to become available for querying"
HEALTH_CMD="kubectl exec -n rook-ceph -i --namespace rook-ceph-system $(kubectl get -n rook-ceph-system pod -l "app=rook-ceph-operator" -o jsonpath='{.items[0].metadata.name}') -- ceph health"
ATTEMPTS=0
$HEALTH_CMD
RESULT=$?
until [ $RESULT -eq 0 ] || [ $ATTEMPTS -eq 60 ]; do
  $HEALTH_CMD
  RESULT=$?
  ATTEMPTS=$((ATTEMPTS + 1))
  echo "Waiting to query Ceph ($ATTEMPTS of 60)"
  sleep 2
done
set -e

if [ $ATTEMPTS -eq 60 ]; then
    echo "Aborting... Unable to query ceph after $ATTEMPTS attempts."
    echo exit 1
fi

echo "Waiting for Ceph to be Ready"
CEPH_HEALTH=$($HEALTH_CMD)
while [ "$CEPH_HEALTH" != "HEALTH_OK" ]
do 
    CEPH_HEALTH=$($HEALTH_CMD)
    echo $CEPH_HEALTH
done 
echo "Ceph is Ready"
sleep 20

echo "Starting Replicated System"
kubectl scale deploy replicated --replicas=1
kubectl rollout status deploy replicated
REPLICATED_POD_ID=$(kubectl get pod -l "app=replicated,tier=master" -o name | sed 's/pod\///')
until (kubectl exec $REPLICATED_POD_ID -c replicated -- replicatedctl system status 2>/dev/null | grep -q '"Retraced": "ready"'); do sleep 1; done 

echo "Starting Replicated Application"
kubectl exec $REPLICATED_POD_ID -c replicated -- replicatedctl app start --attach

echo "Successful Startup"
