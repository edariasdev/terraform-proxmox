

### SSH Issues with Debian:
I wasn't able to run ssh after enabling:
```shell
systemctl status -l ssh

sshd.service - OpenSSH Daemon
   Loaded: loaded (/usr/lib/systemd/system/sshd.service; disabled)
   Active: failed (Result: start-limit) since ons 2013-06-19 08:49:49 NZST; 3s ago
  Process: 1705 ExecStart=/usr/bin/sshd -D (code=exited, status=1/FAILURE)

jun 19 08:49:49 mba systemd[1]: Starting OpenSSH Daemon...
jun 19 08:49:49 mba systemd[1]: Started OpenSSH Daemon.
jun 19 08:49:49 mba systemd[1]: sshd.service: main process exited, code=exited, status=1/FAILURE
jun 19 08:49:49 mba systemd[1]: Unit sshd.service entered failed state.
jun 19 08:49:49 mba systemd[1]: sshd.service holdoff time over, scheduling restart.
jun 19 08:49:49 mba systemd[1]: Stopping OpenSSH Daemon...
jun 19 08:49:49 mba systemd[1]: Starting OpenSSH Daemon...
jun 19 08:49:49 mba systemd[1]: sshd.service start request repeated too quickly, refusing to start.
jun 19 08:49:49 mba systemd[1]: Failed to start OpenSSH Daemon.
jun 19 08:49:49 mba systemd[1]: Unit sshd.service entered failed state.

```

In order to check, I ran in debug and showed the first error

```shell
sudo /usr/bin/sshd -d

Could not load host key: /etc/ssh/ssh_host_rsa_key
Could not load host key: /etc/ssh/ssh_host_dsa_key
Could not load host key: /etc/ssh/ssh_host_ecdsa_key
Disabling protocol version 2. Could not load host key
sshd: no hostkeys available -- exiting.
```


Fix:
1. Add the /run/sshd directory:
```shell
sudo mkdir -p /run/sshd
```
2. Generate keys:
```shell
sudo /usr/bin/ssh-keygen -A
```
3. Enable the service:
```shell
sudo systemctl daemon-reload
```
4. Restart the service:
```shell
sudo systemctl restart ssh
```



Once restarted SSH should be operational with no errors:
```shell
ed@edbuntu:~/terraform$ ssh ed@192.168.14.80
The authenticity of host '192.168.14.80 (192.168.14.80)' can't be established.
ECDSA key fingerprint is SHA256:DFaIC046gSXHIGa9EbXe0QUUx2QvNRRcYbHPSclyzqU.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes 
Warning: Permanently added '192.168.14.80' (ECDSA) to the list of known hosts.
```

Sources
- https://www.xmodulo.com/sshd-error-could-not-load-host-key.html
- https://askubuntu.com/questions/600584/error-could-not-load-host-key-when-trying-to-recreate-ssh-host-keys
- https://bbs.archlinux.org/viewtopic.php?id=165382
- https://askubuntu.com/questions/1110828/ssh-failed-to-start-missing-privilege-separation-directory-var-run-sshd
- https://askubuntu.com/questions/1109934/ssh-server-stops-working-after-reboot-caused-by-missing-var-run-sshd/1110843#1110843
- https://bbs.archlinux.org/viewtopic.php?id=227787
