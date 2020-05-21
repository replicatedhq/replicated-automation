# Simply remove the value for the instance/zone name to indicate that the node doesn't exist. 
I1=instance-kots4
I2=instance-kots5
I3=instance-kots6
I4=
I5=
I6=
LB=instance-kotslb
I1Z=us-central1-c
I2Z=us-central1-c
I3Z=us-central1-c
I4Z=
I5Z=
I6Z=
LBZ=us-central1-c

# KUBE_CONTEXT as defined by the local machine. You need to be able to execute `kubectl config use-context $KUBE_CONTEXT` for the scripts to work. 
# Look in your $HOME/.kube/config to find the appropriate name to connect to the kubernetes cluster. 
KUBE_CONTEXT=kubernetes-admin@instance-kots4
