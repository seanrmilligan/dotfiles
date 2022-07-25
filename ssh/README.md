# SSH Notes

Signing into a machine with no public IP via another machine with a public IP:

```
Host the_public_machine
  HostName 123.123.123.123
  Port 22
  User ubuntu
  IdentityFile ~/.ssh/keyfile

Host the_private_machine
  Hostname 192.168.1.1
  Port 22
  User ubuntu
  ForwardAgent yes
  ProxyCommand ssh -W %h:%p the_public_machine
```

Note: both machines here accept the same SSH key.
