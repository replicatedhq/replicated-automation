Scripts to automatically startup/shutdown the entire Replicated environment

Only supports AKA at present (leveraging the safe-shutdown capability which will soon be added to KOTS)

* Modify vars.sh to refer to the 6 instances and the zones they were in. 
* Name of the kubernetes context/credentials, which is needed for these scripts to work. 
* Just put all three *.sh files in the same directory, declare your variables, configure your kubectl context, and you're good to go. 

