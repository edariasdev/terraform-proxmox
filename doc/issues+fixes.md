## 1. I inadvertently deleted a VM within the hypervisor and was unable to destroy the resources within Terraform.

> [!WARNING]
> Terraform keeps track of infrastructure using the 'terraform.tfstate' file. If for whatever reason a VM or container is delete on the host without using Terraform, you will get an error as such below.

```shell
ed@edbuntu:~/terraform$ terraform destroy
proxmox_lxc.basic: Refreshing state... [id=hera/lxc/105]
╷
│ Error: vm '105' not found
│ 
│   with proxmox_lxc.basic,
│   on main.tf line 27, in resource "proxmox_lxc" "basic":
│   27: resource "proxmox_lxc" "basic" {
```
fix for this was:
```shell
terraform state list 
```
which output 
```shell
proxmox_lxc.basic
```
once I found the plan I applied, I ran 
```shell
terraform state rm proxmox_lxc.basic
``` 
which then allowed me to run 
```shell
terraform plan
```

## 2. When I kicked-off this plan, all resources deployed except my k8s master node. 

```shell
proxmox_vm_qemu.worker_node["0"]: Still creating... [4m0s elapsed]
proxmox_vm_qemu.worker_node["1"]: Still creating... [4m10s elapsed]
proxmox_vm_qemu.worker_node["1"]: Creation complete after 4m18s [id=hera/qemu/107]
╷
│ Error: scsi0 - cloud-init drive is already attached at 'ide0'
│ 
│   with proxmox_vm_qemu.master_node["0"],
│   on main.tf line 52, in resource "proxmox_vm_qemu" "master_node":
│   52: resource "proxmox_vm_qemu" "master_node" {

│ Error: scsi0 - cloud-init drive is already attached at 'ide0'
│ 
│   with proxmox_vm_qemu.worker_node["0"],
│   on main.tf line 93, in resource "proxmox_vm_qemu" "worker_node":
│   93: resource "proxmox_vm_qemu" "worker_node" {
```
There seems to be no apparent long term fix and is an inconsistent error with several small workarounds.
+ https://github.com/Telmate/terraform-provider-proxmox/issues/704



## 3. Issue when I tried to install packages into the qcow2 image:

```bash
Need to get 39.5 MB of archives.
After this operation, 153 MB of additional disk space will be used.
E: You don't have enough free space in /var/cache/apt/archives/.
virt-customize: error: 
        export DEBIAN_FRONTEND=noninteractive
        apt_opts='-q -y -o Dpkg::Options::=--force-confnew'
        apt-get $apt_opts update
        apt-get $apt_opts install 'kubeadm'
      : command exited with an error

If reporting bugs, run virt-customize with debugging enabled and include 
the complete output:

  virt-customize -v -x [...]
```
Fix 1:
Resize the qcow2 image via several steps
```shell
ed@edbuntu:~/terraform$ sudo virt-filesystems --long -h --all -a /home/ed/quemu-images/22-08-23-debian-12-generic-amd64.qcow2
Name        Type        VFS      Label  MBR  Size  Parent
/dev/sda1   filesystem  ext4     -      -    1.9G  -
/dev/sda14  filesystem  unknown  -      -    3.0M  -
/dev/sda15  filesystem  vfat     -      -    124M  -
/dev/sda1   partition   -        -      -    1.9G  /dev/sda
/dev/sda14  partition   -        -      -    3.0M  /dev/sda
/dev/sda15  partition   -        -      -    124M  /dev/sda
/dev/sda    device      -        -      -    10G   -
```

```shell
sudo qemu-img create -f qcow2 -o preallocation=metadata 8gb-debian12-k8s.qcow2 8G &&\
sudo virt-resize --expand /dev/sda1 /tmp/debian-12-generic-amd64.qcow2 8gb-debian12-k8s.qcow2
```


Fix 2:
Use 'virt-builder' to create an image with xG size:
```shell
    virt-builder ${image_to_download} \
        --output "${output_file}" \
        --format qcow2 \
        --size "${image_size}" 
```
+ https://gist.github.com/joseluisq/2fcf26ff1b9c59fe998b4fbfcc388342
+ https://www.libguestfs.org/virt-resize.1.html

## 4. Mounting a qcow locally:
1. Mount with 'guestmount'
2. Perform operations
3. Unmount

```shell
sudo guestmount -a debian-12.qcow2 -i /mnt &&\
sudo ls -al /mnt/etc/apt/keyrings/kubernetes-archive-keyring.gpg
sudo guestunmount /mnt 
```
