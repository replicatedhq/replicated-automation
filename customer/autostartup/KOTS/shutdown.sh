#!/bin/bash
set -e
source ./vars.sh

echo "Connecting to Cluster"
kubectl config use-context $KUBE_CONTEXT

echo "Stopping Ceph"
kubectl -n rook-ceph scale deploy rook-ceph-operator --replicas=0
kubectl rollout status deployment/rook-ceph-operator --namespace rook-ceph

echo "Cordoning Nodes"
CORDON_CMD='kubectl cordon $I'
CMD='wait'
if [[ ! -z $I1 ]]; then I=$I1; CMD="$(eval echo ${CORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I2 ]]; then I=$I2; CMD="$(eval echo ${CORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I3 ]]; then I=$I3; CMD="$(eval echo ${CORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I4 ]]; then I=$I4; CMD="$(eval echo ${CORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I5 ]]; then I=$I5; CMD="$(eval echo ${CORDON_CMD}) & ${CMD}"; fi
if [[ ! -z $I6 ]]; then I=$I6; CMD="$(eval echo ${CORDON_CMD}) & ${CMD}"; fi
eval ${CMD}

echo "Node Shutdown"
# For AWS: SHUTDOWN_CMD='aws ec2 stop-instances --instance-ids $I; aws ec2 wait instance-stopped --instance-ids $I'
SHUTDOWN_CMD='gcloud compute instances stop $I --zone $IZ'
CMD='wait'
if [[ ! -z $I1 ]]; then I=$I1; IZ=$I1Z; CMD="$(eval echo ${SHUTDOWN_CMD}) & ${CMD}"; fi
if [[ ! -z $I2 ]]; then I=$I2; IZ=$I2Z; CMD="$(eval echo ${SHUTDOWN_CMD}) & ${CMD}"; fi
if [[ ! -z $I3 ]]; then I=$I3; IZ=$I3Z; CMD="$(eval echo ${SHUTDOWN_CMD}) & ${CMD}"; fi
if [[ ! -z $I4 ]]; then I=$I4; IZ=$I4Z; CMD="$(eval echo ${SHUTDOWN_CMD}) & ${CMD}"; fi
if [[ ! -z $I5 ]]; then I=$I5; IZ=$I5Z; CMD="$(eval echo ${SHUTDOWN_CMD}) & ${CMD}"; fi
if [[ ! -z $I6 ]]; then I=$I6; IZ=$I6Z; CMD="$(eval echo ${SHUTDOWN_CMD}) & ${CMD}"; fi
eval ${CMD}

if [[ ! -z $LB ]]; then 
    echo "Load Balancer Shutdown"
    # For AWS: aws ec2 stop-instances --instance-ids $LB; aws ec2 wait instance-stopped --instance-ids $LB & wait'
    gcloud compute instances stop $LB --zone $LBZ & wait
fi

echo "Successful Shutdown"