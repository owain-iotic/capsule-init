#!/bin/bash 
# Install Docker CE
## Set up the repository
### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum update -y && yum install -y \
  containerd.io-1.2.13 \
  docker-ce-19.03.8 \
  docker-ce-cli-19.03.8

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl restart docker

systemctl enable docker.service

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

modprobe br_netfilter

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

docker pull k8s.gcr.io/kube-proxy:v1.18.2             
docker pull k8s.gcr.io/kube-scheduler:v1.18.2            
docker pull k8s.gcr.io/kube-controller-manager:v1.18.2             
docker pull k8s.gcr.io/kube-apiserver:v1.18.2             
docker pull weaveworks/weave-npc:2.6.2              
docker pull weaveworks/weave-kube:2.6.2               
docker pull k8s.gcr.io/pause:3.2                 
docker pull k8s.gcr.io/coredns:1.6.7               
docker pull k8s.gcr.io/etcd:3.4.3-0             

echo "setup install on boot "

chmod +x /opt/iotics/*.sh 
cat > /etc/systemd/system/iotics-boot.service <<EOF
[Unit]
Description=iotics-bootup-script
After=network.target

[Service]
Type=idle
ExecStart=/opt/iotics/bootscript.sh
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

systemctl daemon-reload

systemctl enable iotics-boot.service

