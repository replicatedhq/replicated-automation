# TLS on Existing KOTS Cluster

This guide walks though setting up TLS on Existing KOTS Cluster using Nginx Reverse Proxy.

## Install KOTSADM

Install KOTSADM on an existing cluster like you would normally do.

```
kubectl kots install application-name
```

## Certificate Secret

* In `nginx-tls` dir add a cert with name `tls.crt` and key with name `tls.key`.
* Create a `Secret` named `kotsadm-nginx-tls`
```
kubectl -n <namespace> create secret generic kotsadm-nginx-tls --from-file=./nginx-tls
```

## Reverse Proxy Configuration

* In `nginx-conf` dir modify `virtualhost.conf` to replace `demo-aj.somebigbank.com` (in 2 places) with the FQDN assigned to the cert.
* Create a `ConfigMap` named `kotsadm-nginx-conf`
```
kubectl -n <namespace> create configmap kotsadm-nginx-conf --from-file=./nginx-conf
```

## Reverse Proxy Deployment

* Create Nginx Proxy `Deployment` and `Service` from `nginx-proxy` dir.
```
kubectl -n <namespace> apply -f nginx-proxy/
```

## Accessing KOTSADM via TLS

* The `Service` is setup as a `NodePort` by default, so you can use any one of the public IPs assigned to the K8s host nodes. For testing purposes add the TLS FQDN from `virtualhost.conf` to your `/etc/hosts` file.
```
<k8s_host_node_public_ip> <tls_fqdn>
```

* Next you can access it via HTTPS on port `30443`
```
https://<tls_fqdn>:30443
```

* You can also access it via HTTP on port `30080` but you will be redirected to HTTPS.

```
http://<tls_fqdn>:30080
```

## DNS and LoadBalancer

* In production you should add the host node IP as a DNS A record so the TLS FQDN is accssible without adding it to `/etc/hosts` of all the users.

* If the K8s cluster environment supports `LoadBalancer` as a `Service` type (AWS, GCP, etc.), you can modify `nginx-proxy/service.yaml` and add the load balancer IP as the DNS A record for the TLS FQDN.
