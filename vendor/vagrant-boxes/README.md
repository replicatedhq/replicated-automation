This can be used as a vagrant box for testing kURL installations. To launch it, ensure you have [vagrant and virtualbox installed](https://www.vagrantup.com/docs/providers/virtualbox),
then run:

```
vagrant plugin install vagrant-disksize
vagrant up ubuntu18
```

### Installing KOTS with kURL

If you need to get the install command for a channel, you run (from your workstation, not the VM)

```shell script
replicated channel inspect $CHANNEL
```

e.g.

```shell script
replicated channel inspect Unstable
```

Once you have your install commmand, you can run it in the VM

```shell script
vagrant ssh
```

```text
vagrant@vagrant:~$ curl https://k8s.kurl.sh/${APP_SLUG}-${APP_CHANNEL} | sudo bash
```


### Proxying port 443 on localhost

Since binding to 80/443 on localhost would involve giving root to Virtualbox, we tend to instead prefer
to install nginx and use it to proxy through to those ports. On macOS, you can do this with nginx:


```shell script
brew install nginx
```


```shell script
cat <<EOF >> $(dirname $(which brew))/../etc/nginx/nginx.conf
stream {
    upstream web_server_443 {
        server localhost:8443;
    }

    upstream web_server_80 {
        server localhost:8080;
    }

    server {
        listen 443;
        proxy_pass web_server_443;
    }
    server {
        listen 80;
        proxy_pass web_server_80;
    }
}
EOF
```

```shell script
brew services reload nginx
```
