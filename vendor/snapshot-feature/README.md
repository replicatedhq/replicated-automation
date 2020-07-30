# Installation: Manual Install of Velero CLI 
0. **(Alternate Instructions -- Recommended to follow instructions by Admin Console UI first)**
1. Run the following: 
```s
wget https://github.com/vmware-tanzu/velero/releases/download/v1.3.2/velero-v1.3.2-linux-amd64.tar.gz
tar -xvf velero-v1.3.2-linux-amd64.tar.gz
cd velero-v1.3.2-linux-amd64/
mv velero /usr/local/bin/velero
sudo mv velero /usr/local/bin/velero
```

# Installation: KOTS Application to demonstrate Snapshot capabilities
1. Perform an installation of the KOTS application located here: https://github.com/replicatedhq/kotsapps/tree/master/postgres-snapshots. This can be accomplished by running `curl -sSL https://k8s.kurl.sh/postgres-snapshots-unstable | sudo bash`. Recommended Ubuntu 18 for the VM. 
2. Download the license for the application here: https://raw.githubusercontent.com/replicatedhq/kotsapps/master/postgres-snapshots/License-Unstable.yaml
3. Once this application is installed, you are able to perform snapshots to the built-in Rook/Ceph RGW storage. 

# Scenario 1: Configure GCP as a storage provider 
0. **(Alternate Instructions -- Recommended to follow instructions by Admin Console UI first)**
1. Setup a new GCP bucket with all necessary permissions by following the guide here: https://github.com/vmware-tanzu/velero-plugin-for-gcp. For your convenience, we have also created a script to do this for you: https://raw.githubusercontent.com/replicatedhq/replicated-automation/master/vendor/snapshot-feature/setup-gcp.sh
2. Install the Velero with GCP plugin, using the bucket name and the secret created from the above first step

    ## Install Velero
    velero install \
        --provider gcp \
        --plugins velero/velero-plugin-for-gcp:v1.0.1 \
        --bucket $BUCKET \
        --secret-file ./credentials-velero.$BUCKET \
        --use-restic

3. On the "Snapshot Settings" page, change provider to GCP, and provide bucket name and credentials file if needed

# Scenario 2: Configuration to another provider has failed. Customer wishes to return to initial snapshot configuration (via Rook/Ceph RGW). 
1. Simply update the "Snapshot Settings" UI to point to the internal location. This should work. 
2. If this fails for any reason, manual steps to do the same can be performed by referring to the following script: https://github.com/replicatedhq/replicated-automation/blob/master/vendor/snapshot-feature/setup-rook-rgw.sh

# Scenario 3: Disaster Recovery. Old cluster is down. A new cluster has been created with kURL and we wish to restore application to this new cluster. 
0. Note: This approach will restore the application, but Admin Console will not be restored. 
1. Create a new cluster matching the old k8s installer (you can simply copy it into the UI at kurl.sh)
2. Run: `kubectl delete ns velero` to clear the default configuration. 
3. Reinstall Velero as you did above, using the same secret-file and bucket name. (see the `## Install Velero` section above)
4. Run `velero get backups`. You should get something like: 
    ```s
    austin@austins-empty-cluster:~$ velero get backups
    NAME                       STATUS      CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
    postgres-snapshots-6fx2k   Completed   2020-05-18 19:26:36 +0000 UTC   29d       default            <none>
    ```
5. Run `velero restore create --from-backup <backupname>` to perform the restore. For example, to restore the above backup, run: 
    ```s
    austin@austins-empty-cluster:~$ velero restore create --from-backup postgres-snapshots-6fx2k
    ```
6. Verify success by running `velero get restore` and `kubectl get pods` 
    ```s
    austin@austins-empty-cluster:~$ velero get restore
    NAME                                      BACKUP                     STATUS      WARNINGS   ERRORS   CREATED                         SELECTOR
    postgres-snapshots-6fx2k-20200518193155   postgres-snapshots-6fx2k   Completed   2          0        2020-05-18 19:31:55 +0000 UTC   <none>
    austin@austins-empty-cluster:~$ k get pods
    NAME                           READY   STATUS    RESTARTS   AGE
    pg-consumer-76bc58cffb-sdrcb   1/1     Running   0          23s
    pg-snapshot-585f4fb89-sclgb    1/1     Running   0          23s
    postgres-0                     1/1     Running   0          23s
    ```
7. At this point, the application has been restored and running without kotsadm. 

# Additional Useful Commands to Check Velero Backup Location is working as expected
```s
    kubectl get secret -o yaml aws-credentials -n velero
    kubectl get backupstoragelocations -n velero
    velero backup download <backupname>
```

