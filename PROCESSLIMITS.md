### Changing File and Process Limits

```
vi /etc/security/limits.conf
```
add this to the bottom of this file:
```
* soft core unlimited
* hard core unlimited
* hard nproc 65535
* soft nproc 65535
* hard nofile 65535
* soft nofile 65535
```
Edit nproc file specific to the OS you are using ...

For CentOS 7.x:
```
vi /etc/security/limits.d/20-nproc.conf
```
... and add the following (clean up any duplication):

```
* hard nproc 65535
* soft nproc 65535
```

For PCE version 18.x and above:
```
vi /etc/sysctl.conf
```

core nodes:
```
fs.file-max        = 2000000
net.core.somaxconn = 16384
```

data nodes:
```
fs.file-max          = 2000000
kernel.shmmax        = 60000000
vm.overcommit_memory = 1
```
snc0 nodes:
```
fs.file-max          = 2000000
net.core.somaxconn   = 16384
kernel.shmmax        = 60000000
vm.overcommit_memory = 1
```
