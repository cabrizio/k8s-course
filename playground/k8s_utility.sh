#!/bin/bash

_load_modules_containerd() {
	 echo "Loading containerd modules..."
	 echo overlay >> /etc/modules-load.d/containerd.conf
	 echo br_netfilter >> /etc/modules-load.d/containerd.conf
	 sleep 3
	 modprobe overlay
	 modprobe br_netfilter
}

_load_modules_k8s_cri() {
	 echo "Loading K8s cri modules..."
	 echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/99-kubernetes-cri.conf
	 echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-kubernetes-cri.conf
	 echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/99-kubernetes-cri.conf
	 sleep 5
	 sysctl --system
}

_install_containerd() {
	 echo "Installing containerd..."
	 apt-get update && sudo apt-get install -y containerd
	 mkdir -p /etc/containerd
	 containerd config default | sudo tee /etc/containerd/config.toml
	 systemctl restart containerd
}

_install_k8s_tools() {
	echo "Installing kubelet,kubeadm and kubectl...."
	apt-get update && sudo apt-get install -y apt-transport-https curl
	curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
	echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list
	apt-get update
	apt-get install -y kubelet=1.24.0-00 kubeadm=1.24.0-00 kubectl=1.24.0-00
	apt-mark hold kubelet kubeadm kubectl
}


_load_modules_containerd
_load_modules_k8s_cri
_install_containerd
_install_k8s_tools
