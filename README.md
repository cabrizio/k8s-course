# K8S Certification CKA #


## K8S architectual ##

### _K8s Control Plane_ ###

The control plane is a collection of multiple components responsable for managing the cluster itself globally. Essentially, the control plane controls the cluster.
Individual control plane components can run on any machine in the cluster, but ussually are run on dedicated controller machines.

Components:

- kube-api-server, the primary interface to the control plane and the cluster itself.When interacting with your Kubernetes cluster, you will usually do so using the kubernetes API

- etcd, is the backend data store for the K8S cluster, It provides high-availability storage for all data relating to the state of the cluster

- kube-scheduler, it handles scheduling, the process of selecting an available node in the cluster on which to run containers

- kube-controller-manager, runs a collection of multiple controller utilities in a single process.These controllers carry put a variety of automation-related tasks whitin the K8s cluster.

- cloud-controller-manager, provides an interface between K8s and various cloud platforms.It is only used when using cloud-based resources alongside K8s.


### _K8s Workers node_ ###

K8s Nodes are the machines where the containers managed by the cluster run. A cluster can have any number of nodes.

Various node components manage container on the machine and comunicate with the copntrol-plane.

Components:

- kubelet, is the K8S agent that run on each node.It communicates with the control plane and ensures that containers are run on its node as instructed by the control plane.Kubelet also handles the process of reporting container status and other data about containers back to the control plane.

- container-runtime is not built into K8s. It is a separate piece of software that is responsable for actually running containers on the machine.
K8s supports multiple container runtime implementations.

- kube-proxy is a network proxy. It runs on each node and handles some tasks related to providing networking between containers and services in the cluster.



### _K8S cluster - The big picture_ ###

![image](https://user-images.githubusercontent.com/25394408/196386040-73ac524e-44c0-49b9-b083-32869ead8582.png)


## K8S building a cluster ##

### _Tools suite_ ###

 - [Kubeadm] - is a tool that will simplify the process of setting up our K8s cluster


### _Hands-on_  ###

Create a stack of 3 VMs in order to configure a cluster of 1 control-plane and 2 workers, for this purpose I have configured a Vagrantfile and an utility script that will help to configure the VMs quicker. 
Once configured the VMs and execute the [k8s_utility.sh] we need to initialite the K8s cluster:

```shell
## Execute the kubeadm cmd on the control-plane only, this will initialite the master node, the output will print also the join cmd to use on the workers node

kubeadm init --pod-network-cidr 192.168.0.0/16 --apiserver-advertise-address 192.168.56.10 --kubernetes-version 1.24.0

kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.24.0

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

- [Introducing to High Availability in K8s](#Introducing-to-High-Availability-in-K8s)
- [Introducing K8s Management Tools](#Introducing-K8s-Management-Tools)
- [Safely Draining a K8s Node](#Safely-Draining-a-K8s-Node)
- [Upgrading K8s with kubeadm](#Upgrading-K8s-with-kubeadm)
- [Backing UP and Restoring etcd Cluster Data](#Backing-UP-and-Restoring-etcd-Cluster-Data)

## Introducing to High Availability in K8s ##

### _High Availability in K8s_ ###

K8s facilitates highpavailability applications, but you can also design the cluster itself to be high available. To do this you need multiple control-plane.

When using multiple control-planes for high availability, you will likely need to communicate with the K8s api trough a load balancer. This includes clients such as kubelet instances running on worker nodes.

![image](https://user-images.githubusercontent.com/25394408/197200514-9fb4aa07-210f-4b29-9411-89215fb38a5b.png)


We also can have differet High Availability topology
- [Stacked etcd topology](#Stacked-etcd-topology)
- [External etcd topology](#External-etcd-topology)

### _Stacked etcd topology_ ###

A stacked HA cluster is a topology where the distributed data storage cluster provided by etcd is stacked on top of the cluster formed by the nodes managed by kubeadm that run control plane components.

Each control plane node runs an instance of the kube-apiserver, kube-scheduler, and kube-controller-manager. The kube-apiserver is exposed to worker nodes using a load balancer.

Each control plane node creates a local etcd member and this etcd member communicates only with the kube-apiserver of this node. The same applies to the local kube-controller-manager and kube-scheduler instances.

This topology couples the control planes and etcd members on the same nodes. It is simpler to set up than a cluster with external etcd nodes, and simpler to manage for replication.

However, a stacked cluster runs the risk of failed coupling. If one node goes down, both an etcd member and a control plane instance are lost, and redundancy is compromised. You can mitigate this risk by adding more control plane nodes.

You should therefore run a minimum of three stacked control plane nodes for an HA cluster.

This is the default topology in kubeadm. A local etcd member is created automatically on control plane nodes when using kubeadm init and kubeadm join --control-plane.

![image](https://user-images.githubusercontent.com/25394408/197200331-d1c045c6-1029-497a-b2e3-c2ccaf2c3d69.png)


### _External etcd topology_ ###

An HA cluster with external etcd is a topology where the distributed data storage cluster provided by etcd is external to the cluster formed by the nodes that run control plane components.

Like the stacked etcd topology, each control plane node in an external etcd topology runs an instance of the kube-apiserver, kube-scheduler, and kube-controller-manager. And the kube-apiserver is exposed to worker nodes using a load balancer. However, etcd members run on separate hosts, and each etcd host communicates with the kube-apiserver of each control plane node.

This topology decouples the control plane and etcd member. It therefore provides an HA setup where losing a control plane instance or an etcd member has less impact and does not affect the cluster redundancy as much as the stacked HA topology.

However, this topology requires twice the number of hosts as the stacked HA topology. A minimum of three hosts for control plane nodes and three hosts for etcd nodes are required for an HA cluster with this topology.

![image](https://user-images.githubusercontent.com/25394408/197200400-7798e23c-fa2a-4919-8c84-68f72b45ac2e.png)


## Introducing K8s Management Tools ##

There is a variety of management tools available for K8s. These tools interface with K8s to provide additional functionality.When using K8s, it is a good idea to be aware of some of these tools.

- [kubectl]
Most probably the tools beign used more often. Kuectl is the official command line interface for K8s. It is the main method you will use to work with K8s.
- [kubeadm]
An easy tool for quickly creating K8s clusters

- [minikube]
Minikube allows you to automatically set up a logical single-node K8s cluster.It is great for getting K8s up and running for developer puerpose

- [helm]
Helm provides templating and package management for K8s objects. You can use it to manage your own templates or download shared templates from the [helm-community].

- [kompose]
kompose helps you to translate from docker compose files into K8s objects. If you are using Docker compose for some part of your workflow, you can move your application to K8s easily with Kompose

- [kustomize]
Kustomize is a configuration management tool for managing K8s object configurations. It allows you to share and re-use templated configurations for K8s applications.


## Safely Draining a K8s Node ##

When performing maintenance, you =may sometimes need to remove a K8s node from the service.
To do this, you can drain the node. Containers running on the node will be gracefully terminated (and potentially rescheduled on another node)

To drain a node, use the `kuectl drain` cmd 

`$ kubectl drain <node>`

When draining a node, you may need to ignore DaemonSets (pods that are tied to each node). If you have any DaemonSet pods running on the node, you will likely need to use the flag `--ignore-daemonsets`.

`$ kubectl drain <node> --ignore-daemonsets`


If the node remains part of the cluster, you can allow pods to run on the node again when maintenance is complete using the `kubectl uncordon command <node>`

### _Hands-on_  ###

Assuming that we already have a cluster up and running.....

Start creating a standard pod

```shell
$ nano pod.yml

apiVersion: v1
kind: Pod
metadata:
 name: my-pod
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
     - containerPort: 80
  restartPolicy: OnFailure

$ kubectl apply -f pod.yml
```

and a deployment with 2 replicas

```shell
$ nano deployment.yml

apiVersion: apps/v1
kind: Deployment
metadata:
 name: my-deployment
 labels:
  app: my-deployment
spec:
 replicas: 2
 selector:
  matchLabels:
   app: my-deployment
 template:
  metadata:
   labels:
    app: my-deployment
  spec:
   containers:
   - name: nginx
     image: nginx:1.14.2
     ports:
     - containerPort: 80

$ kubectl apply -f deployment.yml
```


Get a list of pods. You should see the pods you just created (including the two replicas from the deployment). Take node of which node these pods are running on.

`kubectl get pods -o wide`

```shell
NAME                             READY   STATUS    RESTARTS   AGE    IP              NODE       NOMINATED NODE   READINESS GATES
my-deployment-566c76b78c-f5nnf   1/1     Running   0          24s    192.168.30.68   worker02   <none>           <none>
my-deployment-566c76b78c-wk5hh   1/1     Running   0          24s    192.168.5.2     worker01   <none>           <none>
my-pod                           1/1     Running   0          4m8s   192.168.5.1     worker01   <none>           <none>
```

Drain the node which the my-pod pod is running.

`kubectl drain worker01 --ignore-daemonsets --force`

Output
```shell
node/worker01 cordoned
WARNING: deleting Pods that declare no controller: default/my-pod; ignoring DaemonSet-managed Pods: kube-system/calico-node-pkgbd, kube-system/kube-proxy-7k7cd
evicting pod default/my-pod
evicting pod default/my-deployment-566c76b78c-wk5hh
pod/my-pod evicted
pod/my-deployment-566c76b78c-wk5hh evicted
node/worker01 drained
```
Check your list of pods again. You should see the deployment replica pods being moved to the remaining node. The regular pod will be deleted.

```shell
NAME                             READY   STATUS    RESTARTS   AGE     IP              NODE       NOMINATED NODE   READINESS GATES
my-deployment-566c76b78c-f5nnf   1/1     Running   0          2m47s   192.168.30.68   worker02   <none>           <none>
my-deployment-566c76b78c-hxbx4   1/1     Running   0          36s     192.168.30.69   worker02   <none>           <none>
```

Uncordon the node to allow new pods to be scheduled there again.
`kubectl uncordon worker01`

one finished you can notice the node being part of the cluster again

```shell
NAME       STATUS   ROLES           AGE   VERSION
master     Ready    control-plane   25m   v1.24.0
worker01   Ready    <none>          24m   v1.24.0
worker02   Ready    <none>          24m   v1.24.0
```
but the regular pod is not present, so it needs to be deployed again, the uncordon deployment does not reschedule the deployment.


## Upgrading K8s with kubeadm ##

When using K8s, you will likely want to periodically upgrade K8s to keep your cluster up to date. Kubeadm makes this process easier

Control Plane Upgrade Steps:
	- Upgrade kubeadm on the control-plane 
	- Drain the control-plane node
	- Plan the upgrade (kubeadm upgrade plan)
	- Apply the upgrade (kubeadm upgrade apply)
	- Upgrade kubelet and kubectl on the control-plane node
	- Uncordon the control plane node

Worker Node Upgrade Steps:
	- Drain the node
	- Upgrade kubeadm
	- Upgrade the kubelet configuration (kubeadm upgrade node).
	- Upgrade kubelet and kubectl.
	- Uncordon the node

### _Hands-on_  ###

Assuming that we already have a cluster up and running.....

Always start with the control-plan!!!

Drain the control plane node.
`kubectl drain master --ignore-daemonsets`

Upgrade kubeadm and check the version
```shell
sudo apt-get update && \
sudo apt-get install -y --allow-change-held-packages kubeadm=1.25.0-00
kubeadm version
```

Plan the upgrade.

`sudo kubeadm upgrade plan v1.25.0`

Upgrade the control plane components.
`sudo kubeadm upgrade apply v1.25.0`


Upgrade kubelet and kubectl on the control plane node.
```shell
sudo apt-get update && \
sudo apt-get install -y --allow-change-held-packages kubelet=1.25.0-00 kubectl=1.25.0-00
```

Restart kubelet.
```shell
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
At this stage we can rejoin the control-plane
`kubectl uncordon master`

```shell
NAME       STATUS   ROLES           AGE   VERSION
master     Ready    control-plane   60m   v1.25.0
worker01   Ready    <none>          59m   v1.24.0
worker02   Ready    <none>          59m   v1.24.0
```

Upgrading the worker nodes, this process needs to be done on all the worker-nodes. As demo we use worker01.

*Note: In a real-world scenario, you should not perform upgrades on all worker nodes at the same time. Make sure
enough nodes are available at any given time to provide uninterrupted service.*


Drain the worker
`kubectl drain worker01 --ignore-daemonsets --force`

Upgrade kubeadm and check the version
```shell
sudo apt-get update && \
sudo apt-get install -y --allow-change-held-packages kubeadm=1.25.0-00
kubeadm version
```

Plan the upgrade.
`sudo kubeadm upgrade node`

Upgrade kubelet and kubectl on the control plane node.
```shell
sudo apt-get update && \
sudo apt-get install -y --allow-change-held-packages kubelet=1.25.0-00 kubectl=1.25.0-00
```

Restart kubelet.
```shell
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```
At this stage we can rejoin the control-plane
`kubectl uncordon worker01`


All nodes have been updated successfully
```shell
NAME       STATUS   ROLES           AGE    VERSION
master     Ready    control-plane   116m   v1.25.0
worker01   Ready    <none>          115m   v1.25.0
worker02   Ready    <none>          115m   v1.25.0
```


## Backing UP and Restoring etcd Cluster Data ##

ETCD is the backend data storage solution for your K8s cluster. As such, all your K8s objects, applications, and configurations are stored in etcd.Somtimes it might be a good idea to run a backup.

We can backup etcd data using the etcd command line tool, [etcdctl].

Use the `etcdctl` snapshot save command to backup the data.

`$ ETCDCTL_API=3 etcdctl --endpoints $ENDPOINT snapshot save <file_name>`

You can also restore etcd data froma backup using the `etcdctl` restore command.
We will need to supply some additional parameters, as the restore operation creates a new logical cluster.

`$ ETCDCTL_API=3 etcdctl snapshot restore <file_name>`


example
```shell

$ sudo ETCDCTL_API=3 etcdctl snapshot save snapshot.db --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key

$ sudo ETCDCTL_API=3 etcdctl snapshot status snapshot.db  --write-out=table

	+----------+----------+------------+------------+
	|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
	+----------+----------+------------+------------+
	| 86016bcd |    25279 |       1043 |     4.2 MB |
	+----------+----------+------------+------------+
```


## Kubectl ##

kubectl is a command line tool that allows you to interact with K8s. kubectl uses the K8s-API to communicate with the cluster and carry oput your commands.
You can also use kubectl to deploy applications,inspect and manage cluster resources, and view logs

	- kubectl get, to list objects in the K8s cluster
	- kubectl describe, to get detailed information about K8s objects
	- kubectl create, to create objects
	- kubectl apply, similar to kubectl create. However if you use kubectl apply on an object that already exists, it will modify the existing object, if possible
	- kubectl delete, to delete object from the cluster
	- kubectl exec, it can be used to run commands inside containers


### _kubectl tips_ ###

Imperative Commands:
	- [declarative] - Define objects using data structures such as YAML or JSON `kubectl create -f <file_name>.yaml`
	- [imperative] - Define objects using kubectl commands and flag. Some people find imperative commands faster `kubectl create deployment my-deployment --image=nginx`

For the imperative command you can also use the `--dry-run` flag, this will run the imperative command without creating the object. Combine it with `-o yaml` to quickly obtain a sample YAML file you can manipulate
`kubectl create deployment my-deployment --image=nginx --dry-run -o yaml`

Use `--record` flag to record the command that was used to make a change `kubectl scale deployment my-deployment replicas=5 --record`, you can see it using the `kubectl describe`


### _EXTRAS_ ###
- [Deployments DOC](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Kubernetes Object Management](https://kubernetes.io/docs/concepts/overview/working-with-objects/object-management/)



## Managing K8s Role-Based Access Control (RBAC) ##

### _RBAC in K8s_ ###

Role-based access control in K8s allows you to control what users are allowed to do and access within your cluster.
For example, you can use RBAC to allow developers to read metadata and logs from K8s pods but not make changes to them.

### _RBAC Objects_ ###

Roles and ClusterRoles are K8s objects that define a set of permissions. These permissions determine what users can do in the cluster.

	- A role defines permissions within a particular namespace
	- ClusterRole defines cluster-wide permissions not specific to a single namespace.

[image]

RoleBinding and ClusterRolebinding are objects that connect Roles and ClusterRoles to users

[image]

### _Hands-On_ ###

Create a Role spec file. `vi role.yml`

```shell
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
	namespace: default
	name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "watch", "list"]
```

Create the rule `kubectl apply -f role.yml`

Bind the role to the `dev` user `vi rolebinding.yml`

```shell
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
	name: pod-reader
	namespace: default
subjects:
- kind: User
  name: dev
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```
Create the rule-binding `kubectl apply -f rolebinding.yml`


### _ETRAS_ ###

- [RBAC official documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)


## _Creating Service Accounts_ ##

In K8s a service account is an account used by container process within Pods to authenticate with the K8s API.
If your pods needs to communicate with the K8s API, you can use service accounts to control their access.

A service account can be created with some YAML as usual, and you can manage access control for service accounts, just like any other user using [RBAC objects](#RBAC-Objects).
Bind service accounts with RoleBinding or ClusterRoleBinding to provide access to the K8s API functionality.

*A RoleBinding or CLusterRoleBinding binds a role to subjects, such as groups,users or ServiceAccount*

### _Hands-On_ ###

As any other objects the ServiceAccount can be created using a YAML file or an imperative command

`vi my-serviceaccount.yml`

```shell
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-serviceaccount
```

OR

`kubectl create sa my-serviceaccount2 -n default`

View your ServiceAccount

`kubectl get sa`


Attach a Role to the ServiceAccount with a RoleBinding

`vi sa-pod-reader.yml`

```shell
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sa-pod-reader
  namespace: default
subjects:
- kind: ServiceAccount
  name: my-serviceaccount
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```
Create the objects `kubectl create -f sa-pod-reader.yml`. Get additional information for the ServiceAccount using
`kubectl describe sa my-serviceaccount`



## Inspecting Pod Resource Usage ##

### _K8s Metrics Server_ ###

In order to view metrics about the resources pods and containers are using, we need an add-on to collect and provide that data.One such add-on is *Kubernetes Metrics Server*.
With `kubectl top` you can view data about resource usage in your pods and nodes. `kubectl top` also supports flags like `--sort-by` and `--selector`

`kubectl top pod --sort-by <JSONPATH> --selector <selector>`


- [K8s metrics](https://github.com/kubernetes-sigs/metrics-server)



## Pods and Containers Overview ##

### _Managing Application Configuration_ ###

*Application Configuration*

When you are running applications in K8s, you may want to pass dynamic values to your applications at runtime to control how they behave. This is known as _application configuration_.

You can store configuration data in K8s unsing _ConfigMaps_. ConfigMaps store data in the form of a  key-value map. ConfigMap data can be passed to your container applications.

Secrets are similar to CponfoigMaps but are desogned to store sensitive data, such as passwords or API keys, more securely. They are created and used similarly to ConfigMaps.

You can pass ConfigMap and Secret data yo your container using environment variables. These variables will be visible to your container at runtime.

Configuration data from ConfigMaps and Secrets can also be passed to containers in the form of mounted volumes.This will cause the configuration data to appear in files available to the container file system.

Each top-level key in the configuration data will appear as a file containing all keys below that top-level key.

- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

### _Hands-On_ ###

Create a ConfigMap `vi my-configmap.yml`
```shell
kind: ConfigMap
apiVersion: v1
metadata:
  name: my-configmap
  namespace: default
data:
  key1: Hello, world!
  key2: |
    Test
    multiple lines
    more lines
```

Create the objects `kubectl create -f my-configmap.yml`


Create a Secret `vi my-secret.yml`, be aware that all the values need to be base64-encoded, example

```shell
$ echo -n 'secret' | base64
$ echo -n 'anothersecret' | base64

$ vi my-secret.yml
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: default
type: Opaque
data:
  secretkey1: c2VjcmV0
  secretkey2: YW5vdGhlcnNlY3JldA==

```

Create the object `kubectl create -f my-secret.yml`

Create a simple pod passing the confMaps and Secret as env variables

```shell
$ vi env-pod.yml
apiVersion: v1
kind: Pod
metadata:
  name: "env-pod"
  namespace: default
  labels:
    app: "env-pod"
spec:
  containers:
  - name: env-pod
    image: "debian:stable-slim"
    resources:
      limits:
        cpu: 200m
        memory: 500Mi
      requests:
        cpu: 100m
        memory: 200Mi
    command: ['sh', '-c', 'echo "configmap: $CONFIGMAPVAR secret: $SECRETVAR"']
    env:
    - name: CONFIGMAPVAR
      valueFrom:
        configMapKeyRef:
          name: my-configmap
          key: key1
    - name: SECRETVAR
      valueFrom:
        secretKeyRef:
          name: my-secret
          key: secretkey1
  restartPolicy: Always

$ kubectl create -f env-pod.yml
 ```
Check the log for the pod to see your configuration values `kubectl logs env-pod`
output `configmap: Hello, world! secret: secret`

















### _Managing Container Resources_ ###

### _Monitoring container health with Pods_ ###

### _Building Self-Healing Pods with Restart Policies_ ###

### _Introducing Init Containers_ ###
























[//]: #
	[Kubeadm]: <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/>
	[helm-community]: <https://artifacthub.io/>
	[kubectl]: <https://kubernetes.io/docs/reference/kubectl/kubectl/>
	[kubeadm]: <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/>
	[minikube]: <https://minikube.sigs.k8s.io/docs/start/>
	[helm]: <https://helm.sh/>
	[kompose]: <https://github.com/kubernetes/kompose>
	[kustomize]: <https://github.com/kubernetes-sigs/kustomize>
	[etcdctl]: <https://etcd.io/docs/v3.4/install/>
	[declarative]:
	[imperative]: