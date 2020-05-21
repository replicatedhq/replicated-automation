#!/bin/bash
set -e
source ./vars.sh

echo "Connecting to Cluster"
kubectl config use-context $KUBE_CONTEXT

if [[ ! -z $LB ]]; then 
    echo "Load Balancer Startup"
    # For AWS: aws ec2 start-instances --instance-ids $LB; aws ec2 wait instance-running --instance-ids $LB & wait
    gcloud compute instances start $LB --zone $LBZ & wait
fi

echo "Startup Node Instances"
# For AWS: STARTUP_CMD='aws ec2 start-instances --instance-ids $I; aws ec2 wait instance-running --instance-ids $I & wait'
STARTUP_CMD='gcloud compute instances start $I --zone $IZ'
CMD='wait'
if [[ ! -z $I1 ]]; then I=$I1; IZ=$I1Z; CMD="$(eval echo ${STARTUP_CMD}) & ${CMD}"; fi
if [[ ! -z $I2 ]]; then I=$I2; IZ=$I2Z; CMD="$(eval echo ${STARTUP_CMD}) & ${CMD}"; fi
if [[ ! -z $I3 ]]; then I=$I3; IZ=$I3Z; CMD="$(eval echo ${STARTUP_CMD}) & ${CMD}"; fi
if [[ ! -z $I4 ]]; then I=$I4; IZ=$I4Z; CMD="$(eval echo ${STARTUP_CMD}) & ${CMD}"; fi
if [[ ! -z $I5 ]]; then I=$I5; IZ=$I5Z; CMD="$(eval echo ${STARTUP_CMD}) & ${CMD}"; fi
if [[ ! -z $I6 ]]; then I=$I6; IZ=$I6Z; CMD="$(eval echo ${STARTUP_CMD}) & ${CMD}"; fi
eval ${CMD}
sleep 30

echo "Waiting for all nodes to be Ready"
if [[ ! -z $I1 ]]; then until (kubectl wait --for=condition=Ready node/$I1); do sleep 1; done; fi; 
if [[ ! -z $I2 ]]; then until (kubectl wait --for=condition=Ready node/$I2); do sleep 1; done; fi;
if [[ ! -z $I3 ]]; then until (kubectl wait --for=condition=Ready node/$I3); do sleep 1; done; fi;
if [[ ! -z $I4 ]]; then until (kubectl wait --for=condition=Ready node/$I4); do sleep 1; done; fi;
if [[ ! -z $I5 ]]; then until (kubectl wait --for=condition=Ready node/$I5); do sleep 1; done; fi;
if [[ ! -z $I6 ]]; then until (kubectl wait --for=condition=Ready node/$I6); do sleep 1; done; fi;
sleep 30

echo "Uncordoning Nodes"
UNCORDON_CMD='kubectl uncordon $I'
CMD='wait'
if [[ ! -z $I1 ]]; then I=$I1; CMD="$(eval echo ${UNCORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I2 ]]; then I=$I2; CMD="$(eval echo ${UNCORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I3 ]]; then I=$I3; CMD="$(eval echo ${UNCORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I4 ]]; then I=$I4; CMD="$(eval echo ${UNCORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I5 ]]; then I=$I5; CMD="$(eval echo ${UNCORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I6 ]]; then I=$I6; CMD="$(eval echo ${UNCORDON_CMD}) & ${CMD}"; fi
eval ${CMD}
sleep 30

echo "Waiting for Kubernetes to become available for scaling Ceph"
set +e
SCALE_CMD="kubectl -n rook-ceph scale deploy rook-ceph-operator --replicas=1"
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
kubectl rollout status deployment/rook-ceph-operator --namespace rook-ceph

echo "Waiting for Ceph to become available for querying"
HEALTH_CMD="kubectl exec -n rook-ceph -i --namespace rook-ceph $(kubectl get -n rook-ceph pod -l "app=rook-ceph-operator" -o jsonpath='{.items[0].metadata.name}') -- ceph health"
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
sleep 5
echo "Successful Startup"


