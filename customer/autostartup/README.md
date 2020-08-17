Scripts to automatically startup/shutdown the entire Replicated environment

Only supports AKA and KOTS at present

* Modify vars.sh to refer to the 6 instances and the zones they were in. 
* Name of the kubernetes context/credentials, which is needed for these scripts to work. 
* Just put all three *.sh files in the same directory, declare your variables, configure your kubectl context, and you're good to go. 

**NOTE** These steps are specifically for restarting an **entire** cluster at once. If you're on KOTS and want to safely reboot a single-node cluster or reboot one node at a time, start with ensuring you've enabled the [EKCO Addon For kURL](https://kurl.sh/docs/add-ons/ekco) before trying these scripts.
