#!/bin/bash
# You don't need to run or install this if you already have VM templates

# This script downloads and configures an image based off Debian-12 (see below) ; it configures the image for a docker or k8s template to use
# within a ProxMox VE node.
# Also, I have a very slow "lab" network; this script assumes that you will be connecting to the 'fast' network 1st;
# then download/configure the image, then it attempts to upload the new .qcow2 disk image to my ProxMox node for template creation.

#

# VARIABLES
# Date time used for image/templae name; edit to your iiking
date_time=$(date +'%m-%d-%y--%H-%M')
# Date time format used to rename vm name; edit as you please
vm_date_time=$(date +'%m-%d-%y')
# this will resolve to your user name
sudo_user=$(logname)

# Name of the disk image to download
# Get images here: virt-builder --list | grep debian
image_to_download="debian-12"
output_file="${image_to_download}.qcow2"

# Size to expand the .qcow2 image to
image_size="6G"

# Local Path to save .qcow2 disk image
outpath="/home/ed/quemu-images"

# Path on Proxmox node to save .qcow2 image
nas_path="/nas/proxmox/hera/exported-qcow2s"

# VMID of the template to set
vmid="9000"

# Packages to install on all .qcow2 images
base_packages="sudo,qemu-guest-agent,apt-transport-https,ca-certificates,neofetch,curl,gnupg,git,net-tools,mlocate" #packages used during the build phase

# List of packages to install on a k8s image
k8s_packages="sudo kubelet kubeadm kubectl docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

# List of packages to install on a docker image
docker_packages="docker-ce,docker-ce-cli,containerd.io,docker-buildx-plugin,docker-compose-plugin"

# IP address of the ProxMox VE Host:
remote_host_ip="192.168.14.124"

# IP address of the VM Gateway IP to set; This is typically the router IP
gateway_ip="192.168.14.1"

# SSH Keys below get copied to each VM
ssh_file="/home/${sudo_user}/.ssh/id_rsa"
ssh_pub_file="/home/${sudo_user}/.ssh/id_rsa.pub"
#Read password from file with 600 permissions
pass=$(echo /home/${sudo_user}/.password) 

#Do Not edit; used for case statement below
use_docker=false
use_k8s=false

# Check if script is run as sudo
if [[ $(id -u) -ne 0 ]]; then
    
    echo "This script must be run as root (sudo)." >&2
    
    exit 1
    
fi

# Display usage information
usage() {
    echo "Usage: $0 [-d] [-k]" 1>&2
    exit 1
}

while getopts ":dk" opt; do
    case $opt in
        d)
            use_docker=true
        ;;
        k)
            use_k8s=true
        ;;
        *)
            echo "Invalid option: -$OPTARG" >&2
            usage
            exit 1
        ;;
    esac
done

# Check if output directory exists; creates if not
if [[ ! -d ${outpath} ]]; then
    
    mkdir -p ${outpath}
    
    chown -R ${sudo_user}:${sudo_user} ${outpath} >&2
    
fi

# Cleaner and safer to run in ${OUTPATH}
pushd ${outpath} >/dev/null 2>&1

function fast_network() {
    
    # Business line used for work, homelab network is using a slower line
    read -p "Press enter when on fast network"
    sleep 5

    
}

function slow_network() {
    
    # My homelab network is much slower than my business line
    read -p "Press enter when on slow network"
    sleep 5

    
}

function check_dependencies() {
    
    ### Install libguestfs-tools: ###
    if dpkg -l | grep -q libguestfs-tools; then
        
        echo -e "\033[0;32mlibguestfs-tools is already installed. \033[0m"
        
    else
        
        echo -e "\033[0;33mlibguestfs-tools is not installed. Installing... \033[0m"
        
        apt-get update
        
        apt-get install libguestfs-tools
    fi
    
}

function build_image() {
    # builds .qcow2 image
    if [[ ! -f ${output_file} ]]; then
        
        ##set the name of the .qcow2 disk image
        if [ "$use_docker" = true ]; then
            local image_to_download=${image_to_download}
            local image_hostname="docker-${image_to_download}-template"
            
            elif [ "$use_k8s" = true ]; then
            export image_to_download=${image_to_download}
            export image_hostname="k8s-${image_to_download}-template"
            
        else
            export image_to_download=${image_to_download}
            export image_hostname="${image_to_download}-template"
            
        fi
        # Build the image with virt-builder;
        echo "Building ${image_to_download}" &&
        virt-builder ${image_to_download} \
        --output ${output_file} \
        --format qcow2 \
        --update \
        --size "${image_size}" \
        --hostname "${image_hostname}" \
        --root-password "file:/home/${sudo_user}/.password" \
        --install "${base_packages}" \
        --timezone "America/New_York" \
        --firstboot-command 'apt-get clean && apt-get autoremove' \
        --firstboot-command "sed -i 's/ens2/ens18/' /etc/network/interfaces" \
        --firstboot-command "sed -i 's/iface ens2/iface ens18/' /etc/network/interfaces" \
        --firstboot-command "/etc/init.d/networking restart" \
        --upload '../terraform/scripts/image-user-config.sh:/tmp/image-user-config.sh' \
        --run-command 'chmod +x /tmp/image-user-config.sh' \
        --run-command '/tmp/image-user-config.sh' \
        --firstboot-command 'localectl set-locale LANG=en_US.utf8' \
        --firstboot-command 'localectl set-keymap us' \
        --firstboot-command 'apt autoremove && apt clean' \
        --firstboot-command 'systemctl enable ssh' \
        --firstboot-command '/usr/bin/ssh-keygen -A' \
        --firstboot-command 'mkdir -p /run/sshd' \
        --firstboot-command 'wget https://github.com/muesli/duf/releases/download/v0.6.2/duf_0.6.2_linux_amd64.deb && dpkg -i duf_0.6.2_linux_amd64.deb' \
        --update \
        --ssh-inject root:file:/home/${sudo_user}/.ssh/id_rsa.pub
        #--update &&\
        export image_to_customize="${output_file}"
    else
        export image_to_customize="${output_file}"
        
    fi
}

function uplodad_to_proxmox() {
    
    # Uploads new qcow to proxmox nas
    if [ "$use_docker" = true ]; then
        
        export image_to_upload="docker-${date_time}-${image_to_customize}"
        
        elif [ "$use_k8s" = true ]; then
        
        export image_to_upload="k8s-${date_time}-${image_to_customize}"
        
    else
        
        export image_to_upload="${date_time}-${image_to_customize}"
        
    fi
    
    if [[ ! -f ${nas_path}/${image_to_upload} ]]; then
        
        echo "Creating copy of $output_file"
        
        cp $output_file $image_to_upload
        
        echo "Uploading ${image_to_upload}"
        
        cp "${image_to_upload}" "${nas_path}/"
        
    else
        
        echo "${image_to_upload} is already present, deleting."
        
        rm -f ${nas_path}/${image_to_upload}
        
        echo "Uploading as ${image_to_upload}"
        
        cp $output_file $image_to_upload
        
        cp "${image_to_upload}" "${nas_path}/"
        
    fi
}

function clean_local_workspace() {
    
    rm -f /home/${sudo_user}/quemu-images/*
    
}

function clean_remote_workspace() {
    
    rm -f /nas/exported-qcow2s/*
    
}

function create_template() {
    
    # Creates template on hypervisor based off built image:
    local template_type="$1"
    
    #local next_vmid=$(ssh -i $ssh_file root@$remote_host_ip "pvesh get /cluster/nextid")
    local vmid_to_use=$((vmid + 1))
    
    # Copy the .qcow2 image to ProxMox VE node then create the template for use.
    ssh -i $ssh_file root@$remote_host_ip "\
    qm create ${vmid_to_use} --name $template_type-$image_to_download-$vm_date_time --net0 virtio,bridge=vmbr0 &&\
    qm importdisk ${vmid_to_use} /nas/exported-qcow2s/${image_to_upload} local-lvm &&\
    qm set ${vmid_to_use} --scsihw virtio-scsi-single \
        --agent enabled=1 \
        --ciuser ${sudo_user} \
        --cipassword ${pass} \
        --scsi0 local-lvm:vm-${vmid_to_use}-disk-0 \
        --ide0 local-lvm:cloudinit \
        --boot c --bootdisk scsi0 \
        --serial0 socket \
        --vga type=std \
        --nameserver ${gateway_ip} \
        --searchdomain 'lab.lan' \
        --ipconfig0 ip=dhcp,gw=${gateway_ip} \
        --sshkeys /root/.ssh/id_rsa.pub \
    --description '$template_type Debian Template $date_time'"
    
    ssh -i $ssh_file root@$remote_host_ip "qm start ${vmid_to_use}"
}

function install_docker() {
    
    ### Add Docker GPG: ###
    virt-customize -a ${image_to_customize} \
    --run-command "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg"
    
    ## Add Docker Repo to sources: ###
    virt-customize -a ${image_to_customize} \
    --run-command 'echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null'
    
    ### Install Docker: ###
    for i in ${docker_packages}; do virt-customize --install "${i}" -a "${image_to_customize}"; done
    
}

function install_k8s() {
    
    ### Add Source for K8s: ###
    virt-customize --touch /etc/apt/sources.list.d/kubernetes.list -a "${image_to_customize}"
    
    ### Add K8s Repo to sources: ###
    virt-customize -a "${image_to_customize}" \
    --run-command 'echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list'
    
    ## Add K8s GPG: ###
    virt-customize -a "${image_to_customize}" \
    --run-command 'curl -fsSL https://dl.k8s.io/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg'
    
    ### Add Docker GPG: ###
    virt-customize -a ${image_to_customize} \
    --run-command 'curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && chmod a+r /etc/apt/keyrings/docker.gpg'
    
    ## Add Docker Repo to sources: ###
    virt-customize -a ${image_to_customize} \
    --run-command 'echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null'
    
    ### Install Kubernetes: ###
    for i in ${k8s_packages}; do virt-customize --install "${i}" -a "${image_to_customize}"; done

    ## Install k8s customization script: ###
    virt-customize -a ${image_to_customize} \
        --upload '../terraform/scripts/k8s-image-config.sh:/tmp/k8s-image-config.sh' \
        --run-command 'chmod +x /tmp/k8s-image-config.sh' \
        --run-command '/tmp/k8s-image-config.sh'
}

# Call the functions

if $use_docker; then
    echo -e "\033[0;36mRunning with Docker install.\033[0m"
    fast_network
    clean_local_workspace
    build_image &&
    install_docker &&
    slow_network
    uplodad_to_proxmox
    create_template "docker"
    clean_local_workspace;
    clean_remote_workspace;
    elif $use_k8s; then
    echo -e "\033[0;36mRunning with K8s install.\033[0m"
    fast_network
    clean_local_workspace
    build_image
    install_k8s
    slow_network
    uplodad_to_proxmox
    create_template "k8s"
    clean_local_workspace;
    clean_remote_workspace;
fi
