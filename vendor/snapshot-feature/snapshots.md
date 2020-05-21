# Scenario: Setup and perform snapshot on cluster to GCP: 
1. Install default postgres-snapshots
2. Take a snapshot. 
3. Delete velero namespace (since included in installer): `kubectl delete ns velero`
4. Set up a new GCP bucket and all permissions. 
5. Install velero with GCP, copying the key to the machine as needed

    ## Install Velero
    velero install \
        --provider gcp \
        --plugins velero/velero-plugin-for-gcp:v1.0.1 \
        --bucket $BUCKET \
        --secret-file ./credentials-velero.$BUCKET \
        --use-restic

# Scenario: Old cluster is down. Create a new cluster with kURL and restore application to this new cluster: 
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


# Velero CLI Install Steps
```s
wget https://github.com/vmware-tanzu/velero/releases/download/v1.3.2/velero-v1.3.2-linux-amd64.tar.gz
tar -xvf velero-v1.3.2-linux-amd64.tar.gz
cd velero-v1.3.2-linux-amd64/
mv velero /usr/local/bin/velero
sudo mv velero /usr/local/bin/velero
```

# Velero Install Example (for GCP)
```s
    velero install \
        --provider gcp \
        --plugins velero/velero-plugin-for-gcp:v1.0.1 \
        --bucket $BUCKET \
        --secret-file ./credentials-velero.$BUCKET \
        --use-restic
```


# Additional Useful commands: 
```s
    kubectl get secret -o yaml aws-credentials -n velero
    kubectl get backupstoragelocations -n velero
    velero backup download <backupname>
```