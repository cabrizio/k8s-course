# K8S Certification CKA #

## K8S architectual ##

### K8s Control Plane ###

The control plane is a collection of multiple components responsable for managing the cluster itself globally. Essentially, the control plane controls the cluster.
Individual control plane components can run on any machine in the cluster, but ussually are run on dedicated controller machines.

Components:

- kube-api-server, the primary interface to the control plane and the cluster itself.When interacting with your Kubernetes cluster, you will usually do so using the kubernetes API

- etcd, is the backend data store for the K8S cluster, It provides high-availability storage for all data relating to the state of the cluster

- kube-scheduler, it handles scheduling, the process of selecting an available node in the cluster on which to run containers

- kube-controller-manager, runs a collection of multiple controller utilities in a single process.These controllers carry put a variety of automation-related tasks whitin the K8s cluster.

- cloud-controller-manager, provides an interface between K8s and various cloud platforms.It is only used when using cloud-based resources alongside K8s.


### K8s Workers node ###

K8s Nodes are the machines where the containers managed by the cluster run. A cluster can have any number of nodes.

Various node components manage container on the machine and comunicate with the copntrol-plane.

Components:

- kubelet, is the K8S agent that run on each node.It communicates with the control plane and ensures that containers are run on its node as instructed by the control plane.Kubelet also handles the process of reporting container status and other data about containers back to the control plane.

- container-runtime is not built into K8s. It is a separate piece of software that is responsable for actually running containers on the machine.
K8s supports multiple container runtime implementations.

- kube-proxy is a network proxy. It runs on each node and handles some tasks related to providing networking between containers and services in the cluster.



### K8S cluster - The big picture ###

![image](https://user-images.githubusercontent.com/25394408/196386040-73ac524e-44c0-49b9-b083-32869ead8582.png)


## K8S building a cluster ##

### Tools suite ###

 - [Kubeadm] - is a tool that will simplify the process of setting up our K8s cluster


### Hands-on  ###

Create a stack of 3 VMs in order to configure a cluster of 1 control-plane and 2 workers, for this purpose I have configured a Vagrantfile and an utility script that will help to configure the VMs quicker. 
Once configured the VMs and execute the [k8s_utility.sh] we need to initialite the K8s cluster:

```shell
## Execute the kubeadm cmd on the control-plane only, this will initialite the master node, the output will print also the join cmd to use on the workers node

kubeadm init --pod-network-cidr 192.168.0.0/16 --apiserver-advertise-address 192.168.56.10 --kubernetes-version 1.24.0

## Output ##

# To start using your cluster, you need to run the following as a regular user:

#   mkdir -p $HOME/.kube
#   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
#   sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

#   export KUBECONFIG=/etc/kubernetes/admin.conf

# You should now deploy a pod network to the cluster.
# Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#   https://kubernetes.io/docs/concepts/cluster-administration/addons/

# Then you can join any number of worker nodes by running the following on each as root:

# kubeadm join 192.168.56.10:6443 --token zvqsim.kokbm2brrbm2d10e \
# 	--discovery-token-ca-cert-hash sha256:615dc9153bc7c1c5e039c8d284aa33ccb016e158eed9bdaaeb28c6f14e744e9c

```
Install the Clico network-addon
`kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml`

we can also get the join comand fromthe output or running `kubeadm token create --print-join-command` once executed the join on all the workers node successfully, go back on the master and run `kubectl get nodes`, we should be able to see all the nodes.


## K8s namespaces ##

Namespaces are virtual cluster backed by the same physical cluster. K8s objects, such as pods and containers, live in namespaces. Namespaces are a way to separate and organize objects in your cluster.
Particular helpfull if you have multiple applicationsserving different customers/backend.

list existing namespaces with kubectl
`kubectl get namespace`
or 
`kubectl get ns`

all cluster have a default namespace.This is used when no other namespace is specified. system components are store into the namespace *kube-system*

When using kubectl, you may need to specify a namespace.You can do this with the `--namespace` flag.If no flag are specified then the default namespce will be selected.

`kubectl get pods --namespace my-namespace`
or
`kubectl get pods -n my-namespace`

To create our own namespace
`kubectl create namespace my-namespace`



## K8s Management Overview ##

- [Introducing to High Availability in K8s]
- [Introducing K8s Management Tools]
- [Safely Draining a K8s Node]
- [Upgrading K8s with kubeadm]
- [Backing UP and Restoring etcd Cluster Data]

## Introducing to High Availability in K8s ##

### High Availability in K8s ###

K8s facilitates highpavailability applications, but you can also design the cluster itself to be high available. To do this you need multiple control-plane.

When using multiple control-planes for high availability, you will likely need to communicate with the K8s api trough a load balancer. This includes clients such as kubelet instances running on worker nodes.

![image](https://user-images.githubusercontent.com/25394408/197200514-9fb4aa07-210f-4b29-9411-89215fb38a5b.png)


We also can have differet High Availability topology
- [Stacked etcd topology]
- [External etcd topology]

### Stacked etcd topology ###

A stacked HA cluster is a topology where the distributed data storage cluster provided by etcd is stacked on top of the cluster formed by the nodes managed by kubeadm that run control plane components.

Each control plane node runs an instance of the kube-apiserver, kube-scheduler, and kube-controller-manager. The kube-apiserver is exposed to worker nodes using a load balancer.

Each control plane node creates a local etcd member and this etcd member communicates only with the kube-apiserver of this node. The same applies to the local kube-controller-manager and kube-scheduler instances.

This topology couples the control planes and etcd members on the same nodes. It is simpler to set up than a cluster with external etcd nodes, and simpler to manage for replication.

However, a stacked cluster runs the risk of failed coupling. If one node goes down, both an etcd member and a control plane instance are lost, and redundancy is compromised. You can mitigate this risk by adding more control plane nodes.

You should therefore run a minimum of three stacked control plane nodes for an HA cluster.

This is the default topology in kubeadm. A local etcd member is created automatically on control plane nodes when using kubeadm init and kubeadm join --control-plane.

![image](https://user-images.githubusercontent.com/25394408/197200331-d1c045c6-1029-497a-b2e3-c2ccaf2c3d69.png)


### External etcd topology ###

An HA cluster with external etcd is a topology where the distributed data storage cluster provided by etcd is external to the cluster formed by the nodes that run control plane components.

Like the stacked etcd topology, each control plane node in an external etcd topology runs an instance of the kube-apiserver, kube-scheduler, and kube-controller-manager. And the kube-apiserver is exposed to worker nodes using a load balancer. However, etcd members run on separate hosts, and each etcd host communicates with the kube-apiserver of each control plane node.

This topology decouples the control plane and etcd member. It therefore provides an HA setup where losing a control plane instance or an etcd member has less impact and does not affect the cluster redundancy as much as the stacked HA topology.

However, this topology requires twice the number of hosts as the stacked HA topology. A minimum of three hosts for control plane nodes and three hosts for etcd nodes are required for an HA cluster with this topology.

![image](https://user-images.githubusercontent.com/25394408/197200400-7798e23c-fa2a-4919-8c84-68f72b45ac2e.png)

