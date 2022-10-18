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

