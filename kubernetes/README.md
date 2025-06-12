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

## End notes

Installing kubernetes on a clean machine is a 10 minutes task, so it is possible to just repeat if not confortable.

On https://github.com/cri-o/packaging/ there is nothing like Ansible scripts, Terraform script, and so on. This project is just focused to CRI-O and its testing environment. Nevertheless it describes in details all steps required to setup kubernetes, and just it.