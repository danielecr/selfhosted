# Alternatives

The simpliest option to expose an ssh service of an internal VM is to setup an routing rule and forward traffic to the target machine. With some firewall rules is possible to limit traffic to just the port allowed.

Another option is to use an ssh-server in the middle as an "hop to the vm",
the client .ssh/config would be:

```
Host *.funtun
   ProxyCommand ssh root@192.168.1.10:22 nc %h %p
```

And the requirement in this case is to have access to 192.168.1.10 server as root, or as another dedicated user, specifically created for this goal.

## The drawbacks

1. create a dedicated user in the hosting server may be an overcommitment
2. "something in the middle" can cause problems when connecting from outside the LAN

## Keeping out "something in the middle"

Or just faking it by streaming data over an https connection, is what is described on the upper folder.

There is also a good improvement offered by mosh: https://github.com/mobile-shell/mosh

Mosh use the regular ssh negotiation to setup an UDP channel, over which client can do a secure (AES256 encrypted) remote shell.

With mosh, the regular ssh negotiation can rely on ProxyCommand, so it possible to combine ssh-over-https provided by nginx reverse proxy, with UDP channel settled up by mosh.

Mosh require both, the VM and the client machine, to have it installed.

