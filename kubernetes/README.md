# Installing Kubernetes

Instead of looking for install kubeadm, and container manager conforming to CRI, it is better to search for "installing CRI-O", and find out this github project

https://github.com/cri-o/packaging/

Following the guide is simple, for each distro:

~~~
KUBERNETES_VERSION=v1.33
CRIO_VERSION=v1.33
~~~

Then follow the distro specific content.

## Bootstrap (and reboot)

This is for the controlplane:

~~~
swapoff -a
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1

kubeadm init
~~~

For other nodes use the output of the command and relative kubeadm join parameters.

**BUT** it advisable to recall to edit `/etc/sysctl.conf` and uncomment the line

~~~
net.ipv4.ip_forward=1
~~~

on both nodes, ip_forward is not just an install-time requirement.

## Notes

I shared a live example of it in a playlist:

https://www.youtube.com/playlist?list=PLkTQw47r-fPKVTRqBgsD91zdVuPq2EJAu

made of 3 videos.

What happened was:
- requirements is unknown at the begin: I needed to change VM resource, and changing CPU core number, or RAM requires shotdown. (removing a network interface is done as plug and play)
- Kubernetes require at least 2 CPU, at least 1700 Mbytes (2G is simpler to memorize)
- in videos I did not mentioned about `/etc/sysctl.conf`, I was focused on stay on time, but this is not a skippable step


## Proxying traffic

The server nginx section added was:


```
stream {
        ...
        server {
                listen 6443; ## no ssl
                proxy_pass 10.4.1.11:6443;
        }
}
```

This skip completely the ssl verification on this hop, it just forward traffic to the internal VM.

I do not know if there is option for the kubectl client to authenticate on a proxy in the middle, but is almost useless.

There is nothing like SNI for it, because the port exposed is 6443, not a standard 443, so no ssl_preread is needed (that would work only if ssl were active)

## The kubectl CLI

I found it weird that there isn't a simpler direction, by the mean of kubeadm, for specifying kubectl command, and not just advice .kube/config replacement.

use https://github.com/btungut/kubeconfig-merge may be an option

These tricks https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/ do not give real control over what you are doing.

may be an option to move the config in a file named .kube/toimport and parse it by config

kubectl config --kubeconfig=toimport view -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' --raw > b64cert

Then refer it in new configuration.

In this way one can script the import just by replacing the .kube/toimport file with
something that came from the server

A bash script would look like:

```
kubectl config --kubeconfig=toimport view -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' --raw > .kube/clustercert.b64
kubectl config --kubeconfig=toimport view -o jsonpath='{.users[0].user.client-certificate-data}' --raw > .kube/user-client-cert.b64
kubectl config --kubeconfig=toimport view -o jsonpath='{.users[0].user.client-key-data}' --raw > .kube/user-client-key.b64
```
and use clustercert.b64, user-client-cert.b64, and user-client-key.b64 in .kube/config as file name.

(maybe base64 encoded is not ok, so base64 -d it. To add to the script, of course)

So one can repeat kubeadm init and kubeadm reset a number of time to experiments with parameters, and quickly work from remote


## End notes

Installing kubernetes on a clean machine is a 10 minutes task, so it is possible to just repeat if not confortable.

On https://github.com/cri-o/packaging/ there is nothing like Ansible scripts, Terraform script, and so on. This project is just focused to CRI-O and its testing environment. Nevertheless it describes in details all steps required to setup kubernetes, and just it.

## More log on installing on this configuration

VMs IP are 10.4.1.11 and 10.4.1.12
Default kubernetes config from kubeadm is 10.96.0.0/12
If I take the first 12 bit, it is 64 + 32, 2^6 + 2^5

~~~
00001010.00110000.00000000.00000000
-------------
this part
~~~

local network CIDR is 10.4.0.0/16

~~~
00001010.000000100.00000000.00000000
------------------
this part
~~~

So those are compatible.

The problem was with my cni installation. Really on worker node the config file was named .conf and not .conflist

When I tried to install calico I needed to investigate what was going on

Calico:

> kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.1/manifests/tigera-operator.yaml

> kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.1/manifests/custom-resources.yaml


## Installing flannel

https://github.com/flannel-io/flannel

because of kube-flannel daemonset is not running properly

edit /etc/kubernetes/manifests/kube-controller-manager.yaml
at command ,add
--allocate-node-cidrs=true
--cluster-cidr=10.244.0.0/16

https://github.com/flannel-io/flannel/issues/728

This set something like node ip and cluster ip

If flannel is required for calico, still I do not know


Invoce kubeadm with:

kubeadm init --pod-network-cidr=10.244.0.0/16


Calico default IPPool want 192.168.0.0/16 . Do:

kubectl edit installation

(in default namespace) and replace with 10.244.0.0/16

