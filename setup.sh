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

sudo yum install -y bash-completion bash-completion-extras

# flux 
wget https://github.com/fluxcd/flux/releases/download/1.19.0/fluxctl_linux_amd64
chmod +x fluxctl_linux_amd64
sudo mv fluxctl_linux_amd64 /usr/local/bin/fluxctl 


kubectl create ns flux
export GHUSER="owain-iotic"
fluxctl install --git-readonly --git-user=${GHUSER} --git-email=${GHUSER}@users.noreply.github.com --git-url=https://github.com/owain-iotic/tryk-flux.git  --git-path=namespaces,workloads --namespace=flux > flux.yaml
kubectl apply -f ./flux.yaml

mkdir -p /home/centos/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/centos/.kube/config
sudo chown centos:centos /home/centos/.kube/config

mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config
echo "alias fluxsync='fluxctl --k8s-fwd-ns=flux sync'" >> /home/centos/.bashrc
echo "source <(kubectl completion bash)" >> /home/centos/.bashrc
echo "alias fluxsync='fluxctl --k8s-fwd-ns=flux sync'" >> /root/.bashrc
echo "source <(kubectl completion bash)" >> /root/.bashrc
echo `date` >> /opt/iotics/bootscript-run


