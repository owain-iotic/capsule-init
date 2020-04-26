#!/bin/bash

cd /opt/iotics
echo "kubeadm init\n\n"

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` 
PRIVATE_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4`
PUBLIC_IP=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4`
SANS="$PRIVATE_IP,$PUBLIC_IP"
echo $SANS
kubeadm init --apiserver-cert-extra-sans="$SANS"

export KUBECONFIG=/etc/kubernetes/admin.conf
systemctl enable --now kubelet

kubectl apply -f /opt/iotics/weave-network.yaml

kubectl taint nodes --all node-role.kubernetes.io/master-

mkdir -p centos/.kube
sudo cp -i /etc/kubernetes/admin.conf centos/.kube/config
sudo chown centos:centos centos/.kube/config

mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config

echo `date` >> /opt/iotics/bootscript-run
