If you are a regular reader of this blog, you already know that I am a huge fan of Talos, a minimalist and secure distribution designed solely to run Kubernetes components. According to the publication date of my article on this topic, it’s been almost a year that I’ve been using it daily (although in reality, I started much earlier).

I still love this project and remain convinced of its potential. Talos seems to me to be one of the best options for deploying Kubernetes, ensuring maximum security without sacrificing simplicity and flexibility.

In short, there’s no need to go over the advantages I find in it again.

I had the opportunity to develop extensions for Talos, use the SDK, play around with Omni (a system for managing Talos at scale), and even do Talos within Talos within Talos. I have also installed clusters with baremetal OVH, Raspberry Pi, ZimaBoard, VMs on Proxmox, Openstack, AWS…

Today, I am tackling another aspect of Talos: provisioning Kubernetes clusters on Proxmox VMs via the Cluster API.

I do not have the expertise to write a comprehensive article on the Cluster API, nor have I tested multiple providers or clouds. In this article, I will instead present my journey to deploy a Talos cluster on Proxmox via the Cluster API, detailing the steps, encountered issues, and solutions found.

But first: what is the Cluster API?
Cluster API

alt text

The Cluster API is an open-source project aimed at automating the deployment, configuration, and management of Kubernetes clusters.

    Started by the Kubernetes Special Interest Group (SIG) Cluster Lifecycle, the Cluster API project uses Kubernetes-style APIs and patterns to automate cluster lifecycle management for platform operators. The supporting infrastructure, like virtual machines, networks, load balancers, and VPCs, as well as the Kubernetes cluster configuration are all defined in the same way that application developers operate deploying and managing their workloads.

To summarize, the Cluster API (which we will abbreviate as CAPI in this article) allows the use of Kubernetes resources to describe and manage Kubernetes clusters… from within a Kubernetes cluster! This means we can leverage all the features of Kubernetes: reconciliation loops, access control, secret management, etc.

Thus, we will have a management cluster that will handle the creation of workload clusters.

The components of CAPI are as follows:

    First, the Cluster-API Controller, which is the main component of CAPI;
    The Bootstrap Provider, responsible for generating the certificates and configurations needed to create the cluster. It also manages the workers to ensure they join the cluster;
    The Infrastructure Provider, which manages the resources needed for the cluster. It creates VMs, networks, disks, etc. In short, it controls the cloud or hypervisor;
    The IPAM Provider, which assigns IP addresses to the cluster machines (based on the needs and constraints of the Infrastructure Provider);
    And finally, the Control Plane Provider, which ensures that the control planes are properly configured and functional (these can be VMs or managed by a cloud service).

I can already hear your questions:

    But on which platforms can I use CAPI?

CAPI is extensible and there are providers (similar to Pulumi or Terraform) for many environments: AWS, Azure, GCP, OpenStack, Hetzner, vcluster, etc.

To start playing with CAPI, we first need to install the command-line client clusterctl:

The idea is to pick the necessary components for our environment. So, here’s my shopping list for my Proxmox + Talos project:

    Bootstrap Provider: The one from Talos (pre-configured in CAPI);
    Infrastructure Provider: I use the IONOS (1&1) project that integrates Proxmox (also pre-configured in CAPI);
    IPAM Provider: I will use the in-cluster project to manage IPs ourselves (again, pre-configured in CAPI);
    Last but not least, the Control Plane Provider will be the one from Talos (pre-configured in CAPI, of course).

I also want to raise a small alert about the fact that our clusterctl will by default use the latest releases of each GitHub project (and therefore, potentially unstable versions), which is not great. We can specify specific versions in the configuration file located at ~/.cluster-api/clusterctl.yaml.

providers:
  - name: "talos"
   url: "https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases/download/v0.6.7/bootstrap-components.yaml"
   type: "BootstrapProvider"
  - name: "talos"
   url: "https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases/download/v0.5.8/control-plane-components.yaml"
   type: "ControlPlaneProvider"
  - name: "proxmox"
   url: "https://github.com/ionos-cloud/cluster-api-provider-proxmox/releases/download/v0.6.2/infrastructure-components.yaml"
   type: "InfrastructureProvider"

Ok! We have our components, what’s missing?
Management Cluster

As mentioned in the introduction, we will need a primary cluster to manage the others. I will create a single-node cluster quickly (and I will do it on my current Proxmox cluster). I could have used an ephemeral cluster under KIND or talosctl cluster create, but for the purposes of this article, I will deploy a cluster based on virtual machines.

If you want to follow a guide to deploy Talos, I invite you to follow my article on the subject (it’s a bit old, but the basics are there).

I then start a Talos ISO on my Proxmox. alt text

We generate the configuration for the management cluster:

talosctl gen secrets
talosctl gen config capi https://192.168.1.6:6443

I will also modify the cluster.allowSchedulingOnControlPlanes field to true in the controlplane.yaml file. The idea is to allow pods to be scheduled on the control plane (and fortunately, we have only one node).

Once the file is modified, we can complete the configuration of the management cluster:

$ talosctl bootstrap -n 192.168.1.6 -e 192.168.1.6 --talosconfig ./talosconfig
$ talosctl kubeconfig -n 192.168.1.6 -e 192.168.1.6 --talosconfig ./talosconfig --merge=false
$ kubectl --kubeconfig kubeconfig get nodes
NAME            STATUS   ROLES           AGE   VERSION
talos-gag-kjo   Ready    control-plane   32s   v1.31.2

We have our management cluster, we can move on to the next step.
Configure Proxmox

To deploy VMs, we will need to provide access to CAPI in a certain way (otherwise, we won’t get very far). Therefore, I am dedicating a user on my Proxmox to manage the machines from our cluster.

# In Proxmox
$ pveum user add capmox@pve
$ pveum aclmod / -user capmox@pve -role PVEVMAdmin
$ pveum user token add capmox@pve capi -privsep
┌──────────────┬──────────────────────────────────────┐
│ key          │ value                                │
╞══════════════╪══════════════════════════════════════╡
│ full-tokenid │ capmox@pve!capi                      │
├──────────────┼──────────────────────────────────────┤
│ info         │ {"privsep":"0"}                      │
├──────────────┼──────────────────────────────────────┤
│ value        │ 918a2c6d-8f30-47i7-8d46-e72c2a882ec8 │
└──────────────┴──────────────────────────────────────┘

With this, I can modify my CAPI configuration file to add the connection information to Proxmox:

# ~/.cluster-api/clusterctl.yaml
PROXMOX_URL: "https://192.168.1.182:8006"
PROXMOX_TOKEN: 'capmox@pve!capi'
PROXMOX_SECRET: "918a2c6d-8f30-47i7-8d46-e72c2a882ec8"

Info

If you don’t like configuration files, you can also use environment variables (e.g. export PROXMOX_URL="https://192.168.1.182:8006" PROXMOX_TOKEN='capmox@pve!capi' etc).

We can now install CAPI along with our various providers:

$ clusterctl init --infrastructure proxmox --ipam in-cluster --control-plane talos --bootstrap talos
$ kubectl get pods -A
NAMESPACE                     NAME                                                       READY   STATUS    RESTARTS      AGE
cabpt-system                  cabpt-controller-manager-6dcd86fd55-6q4nh                  1/1     Running   0             6m1s
cacppt-system                 cacppt-controller-manager-7757bc6849-grm6b                 1/1     Running   0             6m
capi-ipam-in-cluster-system   capi-ipam-in-cluster-controller-manager-8696b5d999-kmkxm   1/1     Running   0             5m59s
capi-system                   capi-controller-manager-59c7f9c475-fx2jb                   1/1     Running   0             6m1s
capmox-system                 capmox-controller-manager-674bdf77bd-8tpzw                 1/1     Running   0             5m59s
cert-manager                  cert-manager-74b56b6655-rt6cc                              1/1     Running   0             19h
cert-manager                  cert-manager-cainjector-55d94dc4cc-qk7h4                   1/1     Running   0             19h
cert-manager                  cert-manager-webhook-564f647c66-dkfrm                      1/1     Running   0             19h
kube-system                   coredns-b588ffbd5-rsbhl                                    1/1     Running   0             20h
kube-system                   coredns-b588ffbd5-x2j7g                                    1/1     Running   0             20h
kube-system                   kube-apiserver-talos-gag-kjo                               1/1     Running   0             20h
kube-system                   kube-controller-manager-talos-gag-kjo                      1/1     Running   2 (20h ago)   20h
kube-system                   kube-flannel-b5wpl                                         1/1     Running   1 (20h ago)   20h
kube-system                   kube-proxy-jmlkw                                           1/1     Running   1 (20h ago)   20h
kube-system                   kube-scheduler-talos-gag-kjo                               1/1     Running   3 (20h ago)   20h

Yes, a night’s sleep and a day’s work have passed between the creation of the management cluster and the installation of CAPI.

Alright, we have the same base now, so we can continue together.
Objective: A Control Plane!

Let’s start simple, I just want a control plane to get started. The first step would be to detail the resources we need for our cluster. So, what do we need to deploy a Talos control plane on Proxmox?

    The definition of a cluster!

It’s a good start, let’s first create a cluster before adding machines to it. For this, I rely on the CAPI documentation to understand that I need a Cluster resource. This resource also has a dependency on another resource called ProxmoxCluster.

In this ProxmoxCluster object, we will define the parameters of our Kubernetes cluster, i.e., configure the IP addresses, gateway, DNS servers that the nodes will use, etc., but most importantly, an API-Server endpoint for a control plane.

apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxCluster
metadata:
  name: proxmox-cluster
  namespace: default
spec:
  allowedNodes:
  - homelab-proxmox-02
  controlPlaneEndpoint:
    host: 192.168.1.220
    port: 6443
  dnsServers:
  - 8.8.8.8
  - 8.8.4.4
  ipv4Config:
    addresses:
    - 192.168.1.210-192.168.1.219
    gateway: 192.168.1.254
    prefix: 24

We can then create our Cluster. Here, we see that we are referencing our ProxmoxCluster (Proxmox provider) on the infrastructureRef side and our TalosControlPlane (Talos provider) on the controlPlaneRef side (it doesn’t exist yet, but at the speed we’re going, it won’t be long).

apiVersion: cluster.x-k8s.io/v1beta1
kind: Cluster
metadata:
  name: coffee-cluster
  namespace: default
spec:
  controlPlaneRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
    kind: TalosControlPlane
    name: talos-cp # does not exist yet
  infrastructureRef:
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    kind: ProxmoxCluster
    name: proxmox-cluster

So far, so good. We have our resources well-present in the cluster.

$ kubectl get cluster,proxmoxcluster
NAME                                      CLUSTERCLASS   PHASE          AGE    VERSION
cluster.cluster.x-k8s.io/coffee-cluster                  Provisioning   102s
NAME                                                             CLUSTER   READY   ENDPOINT
proxmoxcluster.infrastructure.cluster.x-k8s.io/proxmox-cluster                     {"host":"192.168.1.220","port":6443}

Too easy 😎, now let’s create our ControlPlane…

We specify that the ControlPlane is a machine managed by Proxmox (once again, we mix the configuration of the infrastructure and the machines). We can also add additional parameters to influence the Talos configuration that the provider will generate (here, we only specify the type of the machine, but we could go further).

apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: talos-cp
spec:
  version: v1.32.0
  replicas: 1
  infrastructureTemplate:
    kind: ProxmoxMachineTemplate
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    name: control-plane-template
    namespace: default
  controlPlaneConfig:
    controlplane:
      generateType: controlplane

We apply the changes, restart… The only thing left is to create the ProxmoxMachineTemplate to finally see our ControlPlane start.

apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxMachineTemplate
metadata:
  name: control-plane-template
  namespace: default
spec:
  template:
    spec:
      disks:
        bootVolume:
          disk: scsi0
          sizeGb: 20
      format: qcow2
      full: true
      memoryMiB: 2048
      network:
        default:
          bridge: vmbr0
          model: virtio
      numCores: 2
      numSockets: 1
      sourceNode: homelab-proxmox-02
      templateID: ??? # to be filled

Like with Terraform providers when not using Cloud-Init, we need to create a ’template’ machine that will be duplicated for each cluster machine. Since we are using Talos, it is not necessary to boot this machine for installation; it just needs to be created with the Talos ISO image as the bootable disk and ensure that the qemu-guest-agent is enabled on the Proxmox side.

It is also not necessary to be very attentive to the resources allocated to this machine. CAPI will modify them according to what we have defined in our resources as shown above.

To get the Talos ISO, you can download it from Factory. In our case, since we are using standard VMs, we can select “Bare-metal Machine,” which corresponds to standard (virtual or physical) machines.

alt text

Enable Qemu Guest Agent on Proxmox:

alt text

I then get the machine with ID 124! I can now fill in the .spec.template.spec.templateID field of my ProxmoxMachineTemplate.

Now, our cluster has everything it needs to deploy the first machine, and it can start at any moment 😁!

And now, it’s long… very long…

alt text Something is wrong, let’s check the logs of the Proxmox provider.

I0131 16:44:24.941681       1 proxmoxmachine_controller.go:187] "Bootstrap data secret reference is not yet available" controller="proxmoxmachine" controllerGrou
I0131 16:44:24.990591       1 find.go:63] "vmid doesn't exist yet" controller="proxmoxmachine" controllerGroup="infrastructure.cluster.x-k8s.io" controllerKind="
E0131 16:44:25.060475       1 proxmoxmachine_controller.go:209] "error reconciling VM" err="cannot reserve 2147483648B of memory on node homelab-proxmox-02: 0B a
E0131 16:44:25.119065       1 controller.go:324] "Reconciler error" err="failed to reconcile VM: cannot reserve 2147483648B of memory on node homelab-proxmox-02:

I could have waited a long time 😅! Note that 2147483648B = 2GiB, and I have more than enough memory available on my Proxmox node.

alt text

Well, let’s head to the GitHub issues then… ⌛

Digging a bit, I found this message:

    By default our scheduler only allows to allocate as much memory to guests as the host has. This might not be a desirable behavior in all cases. For example, one might explicitly want to overprovision their host’s memory, or to reserve a bit of the host’s memory for itself.

Since I have nothing to lose, I modify the configuration of my ProxmoxCluster to add a schedulerHint that will allow over-provisioning of memory.

apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxCluster
metadata:
  name: proxmox-cluster
  namespace: default
spec:
+  schedulerHints:
+    memoryAdjustment: 0
  allowedNodes:
  - homelab-proxmox-02
  controlPlaneEndpoint:
    host: 192.168.1.220
    port: 6443
  dnsServers:
  - 8.8.8.8
  - 8.8.4.4
  ipv4Config:
    addresses:
    - 192.168.1.210-192.168.1.219
    gateway: 192.168.1.254
    prefix: 24

There’s no reason this should work, but I’ll try anyway.

alt text Hello there!

This is an incredible breakthrough!! 🎉 But something seems off 🤔, an inconsistency between the labels that CAPI added to the machine and what the VM screen shows.

alt text

It’s not the correct IP address, and nothing much is happening on the CAPI side.

E0131 17:04:39.039618       1 controller.go:324] "Reconciler error" err="failed to reconcile VM: error waiting for agent: error waiting for agent: the operat │
│ ion has timed out" controller="proxmoxmachine" controllerGroup="infrastructure.cluster.x-k8s.io" controllerKind="ProxmoxMachine" ProxmoxMachine="default/cont │
│ rol-plane-template-4jtgp" namespace="default" name="control-plane-template-4jtgp" reconcileID="294544f4-4de0-4a91-b686-47a0d51a1f2a"

What a mess!

My theory is that CAPI is unable to configure the IP address. There are two ways it could have done this:

    Either obtain the IP address and send its configuration by setting the IP address in the Talos configuration;
    Or configure its IP address via Cloud-Init (and use it to provide its configuration).

In short, something is wrong, and it seems related to the IP address not being correctly configured. Let’s proceed by elimination: I am quite sure that my Proxmox setup is not the issue, my configuration seems to match what CAPI expects, leaving only one potential problem: Talos.

Is the Proxmox-Talos setup peculiar? I have deployed many Talos clusters on Proxmox without encountering any issues. The answer is actually quite simple: CAPI asks Proxmox to set the machine’s IP address through Cloud-Init, but Talos does not support this when using the “Bare-metal Machine” ISO image (which is the one I used).

I should have used the “nocloud” image (the one used for standard clouds/hypervisors):

alt text

Who would have thought that the ‘cloud’ image was the only one compatible with cloud-init?

alt text

I modify the machine template to use the “nocloud” image and restart the deployment.

It starts, we see that the machine gets its IP configuration, it has joined the cluster (as we can see the cluster name on the console), but it crashes and restarts in a loop.

We can see the following error message:

29.285667 [talos] controller runtime finished
29.287109 [talos] error running phase 2 in install sequence: task 1/1: fail task "upgrade" failed: exit code 1
29.2884421 [talos] no system disk found, nothing to

We thought we had it, but it seems not. Fortunately, I have a small idea of what might be wrong: Talos has no idea which disk to use. To confirm this, I can directly read the machine’s configuration, not via the Talos API (the machine isn’t up long enough for that), but directly from Kubernetes where the Talos configuration is stored.

alt text

The “disk” field is empty, which explains why Talos doesn’t know where to install the system. To fix this, we can modify this configuration via the TalosControlPlane object.

apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: talos-cp
spec:
  version: v1.32.0
  replicas: 1
  infrastructureTemplate:
    kind: ProxmoxMachineTemplate
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    name: control-plane-template
    namespace: default
  controlPlaneConfig:
    controlplane:
      generateType: controlplane
+     strategicPatches:
+       - |
+         - op: replace
+           path: /machine/install
+           value:
+             disk: /dev/sda

We apply, cross our fingers, and wait.

alt text

Incredible, it worked! 😄 We have our ControlPlane running on Proxmox. We see the usual Talos logs asking us to bootstrap the cluster.

In a normal context, we would have to run the talosctl bootstrap command. In a CAPI deployment, this step is supposed to be automated. By listing the status of our ‘ProxmoxMachine’ object, we see that it is still “pending.”

# kubectl describe proxmoxmachine control-plane-template-n62jk
Name:         control-plane-template-n62jk
Namespace:    default
API Version:  infrastructure.cluster.x-k8s.io/v1alpha1
Kind:         ProxmoxMachine
# ...
Status:
  Addresses:
    Address:                control-plane-template-n62jk
    Type:                   Hostname
    Address:                192.168.1.210
    Type:                   InternalIP
  Bootstrap Data Provided:  true
  Ip Addresses:
    net0:
      ipv4:      192.168.1.210
  Proxmox Node:  homelab-proxmox-02
  Vm Status:     pending
Events:          <none>

Oh shit, here we go again.

Alright, what’s the problem now? Let’s check the logs of the Proxmox provider pod:

E0131 19:27:13.724453       1 controller.go:324] "Reconciler error" err="failed to reconcile VM: error waiting for agent: error waiting for agent: the operation has timed out" controller="proxmoxmachine" controllerGroup="infrastructure.cluster.x-k8s.io" controllerKind="ProxmoxMachine" ProxmoxMachine="default/control-plane-template-n62jk" namespace="default" name="control-plane-template-n62jk" reconcileID="d6d0983
3-8d38-4518-bd49-b94522f560bd"

The error error waiting for agent cannot come from just anywhere: it must be related to the Qemu-guest-agent (CAPI must be making requests to the hypervisor to check if the machine is compliant).

Indeed, the QGAs do not seem to be functional. To fix this, we can apply a patch in the Talos configuration to request the installation of the necessary extension.

apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: talos-cp
spec:
  version: v1.32.0
  replicas: 1
  infrastructureTemplate:
    kind: ProxmoxMachineTemplate
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    name: capi-quickstart-control-plane
    namespace: default
  controlPlaneConfig:
    controlplane:
      generateType: controlplane
      strategicPatches:
        - |
          - op: replace
            path: /machine/install
            value:
              disk: /dev/sda
+              extensions:
+                - image: ghcr.io/siderolabs/qemu-guest-agent:9.2.0

Machine redeployed and… we are still in “pending”:

# ...
Status:
  Addresses:
    Address:                control-plane-template-hcthr
    Type:                   Hostname
    Address:                192.168.1.210
    Type:                   InternalIP
  Bootstrap Data Provided:  true
  Conditions:
    Last Transition Time:  2025-01-31T19:47:42Z
    Reason:                PoweringOn
    Severity:              Info
    Status:                False
    Type:                  Ready
    Last Transition Time:  2025-01-31T19:47:42Z
    Reason:                PoweringOn
    Severity:              Info
    Status:                False
    Type:                  VMProvisioned
  Ip Addresses:
    net0:
      ipv4:      192.168.1.210
  Proxmox Node:  homelab-proxmox-02
  Vm Status:     pending
Events:          <none>

Let’s check the provider logs to understand this new error.

E0131 19:51:41.225099       1 controller.go:324] "Reconciler error" err="failed to reconcile VM: unable to get cloud-init status: no pid returned from agent exec command" controller="proxmoxmachine" controllerGroup="infrastructure.cluster.x-k8s.io" controllerKind="ProxmoxMachine" ProxmoxMachine="default/control-plane-template-hcthr" namespace="default" name="control-plane-template-hcthr" reconcileID="099e3e4a-64ca-4b3f-8fb5-be280e3de35e"

no pid returned from agent exec command means that CAPI is trying to execute a bash command on the machine via the QGAs.

Trying to launch a terminal in Talos? You fool!

For once, the solution is not in the Talos configuration but rather in the Proxmox provider configuration. We will modify it as follows to skip checking the machine status via Cloud-Init.

apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxMachineTemplate
metadata:
  name: control-plane-template
  namespace: default
spec:
  template:
    spec:
      disks:
        bootVolume:
          disk: scsi0
          sizeGb: 20
      format: qcow2
      full: true
      memoryMiB: 2048
      network:
        default:
          bridge: vmbr0
          model: virtio
      numCores: 2
      numSockets: 1
      sourceNode: homelab-proxmox-02
      templateID: 124
+      checks:
+        skipCloudInitStatus: true

I restart… WE ARE FINALLY “READY”! 🎉

Status:
  # ...
  Ip Addresses:
    net0:
      ipv4:      192.168.1.210
  Proxmox Node:  homelab-proxmox-02
  Ready:         true
  Vm Status:     ready
Events:          <none>

We can now try to deploy additional control planes by modifying the number of replicas in the TalosControlPlane configuration.

apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: talos-cp
spec:
  version: v1.32.0
-  replicas: 1
+  replicas: 3
  infrastructureTemplate:
    kind: ProxmoxMachineTemplate
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    name: control-plane-template
    namespace: default
  controlPlaneConfig:
    controlplane:
      generateType: controlplane
      strategicPatches:
        - |
          - op: replace
            path: /machine/install
            value:
              disk: /dev/sda
              extensions:
                - image: ghcr.io/siderolabs/qemu-guest-agent:9.2.0

In a few seconds, we get two new machines running on Proxmox.

alt text

However, there’s still a small ‘hiccup’: we defined that the machines should join the cluster whose API-Server is exposed at the address 192.168.1.220. But no machine corresponds to this IP, so no machine can join the cluster. Additionally, if we manually assign this address to a machine, it will become a SPOF for our cluster (spoiler: that’s not good).

Normally, in a Cloud context, this is when we add a LoadBalancer to expose port 6443 of our control planes through an IP address that is not attached to a single machine. In an on-prem environment, we can use a service like KeepAlived or HAProxy.

But thanks to Talos (❤️), which offers a solution to establish a VIP to reach the API-Server (exactly what we are looking to do).

apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: talos-cp
spec:
  version: v1.32.0
  replicas: 3
  infrastructureTemplate:
    kind: ProxmoxMachineTemplate
    apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
    name: control-plane-template
    namespace: default
  controlPlaneConfig:
    controlplane:
      generateType: controlplane
      strategicPatches:
        - |
          - op: replace
            path: /machine/install
            value:
              disk: /dev/sda
              extensions:
                - image: ghcr.io/siderolabs/qemu-guest-agent:9.2.0
+          - op: add
+            path: /machine/install/extraKernelArgs
+            value:
+              - net.ifnames=0
+          - op: add
+            path: /machine/network/interfaces
+            value:
+              - interface: eth0
+                dhcp: false
+                vip:
+                  ip: 192.168.1.220

To elaborate a bit more, we add the net.ifnames=0 option (1st patch) to the kernel so that the network interfaces are named eth0, eth1, and become predictable (otherwise, we have dynamic naming). Once we have the network interface name, we can add a virtual IP address to it (2nd patch) that will be used to reach the API-Server.

When the first machine starts, it will take the IP address 192.168.1.220 (in addition to its current address).

alt text

Thanks to this, the machines automatically join the cluster without any manual intervention (and the bootstrap step is automatically completed).
Adding Workers

We can now move on to the next step: deploying workers! Since it’s quite straightforward, I can directly provide you with the manifests.

apiVersion: cluster.x-k8s.io/v1beta1
kind: MachineDeployment
metadata:
  name: machinedeploy-workers
  namespace: default
spec:
  clusterName: coffee-cluster
  replicas: 3
  selector:
    matchLabels: null
  template:
    spec:
      bootstrap:
        configRef:
          apiVersion: bootstrap.cluster.x-k8s.io/v1alpha3
          kind: TalosConfigTemplate
          name: talosconfig-workers
      clusterName: coffee-cluster
      infrastructureRef:
        apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
        kind: ProxmoxMachineTemplate
        name: worker-template
      version: v1.32.0
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxMachineTemplate
metadata:
  name: worker-template
  namespace: default
spec:
  template:
    spec:
      disks:
        bootVolume:
          disk: scsi0
          sizeGb: 20
      format: qcow2
      full: true
      memoryMiB: 2048
      network:
        default:
          bridge: vmbr0
          model: virtio
      numCores: 2
      numSockets: 1
      sourceNode: homelab-proxmox-02
      templateID: 124
      checks:
        skipCloudInitStatus: true
---
apiVersion: bootstrap.cluster.x-k8s.io/v1alpha3
kind: TalosConfigTemplate
metadata:
  name: talosconfig-workers
spec:
  template:
    spec:
      generateType: worker
      talosVersion: v1.9
      configPatches:
          - op: replace
            path: /machine/install
            value:
              disk: /dev/sda

Considering what we learned during the deployment of the control planes, it’s a piece of cake.

There you have it, we have a complete Kubernetes cluster deployed on Proxmox with Talos and the Cluster API!
Retrieve Access

If we deploy a cluster, it’s to be able to use it, right? So let’s see how to retrieve access to our cluster.

Whether it’s for the KubeConfig or the TalosConfig, it works the same way: we have secrets that have been generated by CAPI and that we can retrieve. The secret containing the KubeConfig is in the form <cluster-name>-kubeconfig and the secret containing the TalosConfig is in the form <cluster-name>-talosconfig.

Let’s start with the KubeConfig:

$ kubectl get secret coffee-cluster-kubeconfig -o yaml | yq .data.value | base64 -d > kubeconfig
$ kubectl --kubeconfig kubeconfig get nodes
NAME                                STATUS   ROLES           AGE   VERSION
control-plane-template-d4kfb        Ready    control-plane   10m   v1.32.0
control-plane-template-hhrgq        Ready    control-plane   10m   v1.32.0
control-plane-template-s4gwg        Ready    control-plane   10m   v1.32.0
machinedeploy-workers-h87sj-dp799   Ready    <none>          56s   v1.32.0
machinedeploy-workers-h87sj-kjg64   Ready    <none>          58s   v1.32.0
machinedeploy-workers-h87sj-z7cs2   Ready    <none>          57s   v1.32.0

Next, the TalosConfig:

$ kubectl get secret coffee-cluster-talosconfig -o yaml | yq .data.talosconfig | base64 -d > talosconfig
$ talosctl --talosconfig talosconfig -n 192.168.1.220 version
Client:
        Tag:         v1.8.3
        SHA:         6494aced
        Built:
        Go version:  go1.22.9
        OS/Arch:     darwin/arm64
Server:
        NODE:        192.168.1.220
        Tag:         v1.9.3
        SHA:         d40df438
        Built:
        Go version:  go1.23.5
        OS/Arch:     linux/amd64
        Enabled:     RBAC

Ready to use!
Talos Cloud Controller Manager

This section is an update to the article following a test with the autoscaler.

Initially, I concluded the article confident that the cluster was fully operational and everything was in order. However, when I attempted to test the autoscaler project, which aims to create Kubernetes nodes on the fly based on load, I encountered an unpleasant surprise.

Here is the current state of my setup:

$ kubectl get machine
NAME                                CLUSTER          NODENAME   PROVIDERID                                       PHASE         AGE     VERSION
machinedeploy-workers-bv6bz-2dnxp   coffee-cluster              proxmox://d5f96316-b669-4549-9598-dceaaff8d9ca   Provisioned   6m20s   v1.32.0
machinedeploy-workers-bv6bz-gftlh   coffee-cluster              proxmox://a6f7735a-b909-4f81-ac40-0dbd429c78eb   Provisioned   6m20s   v1.32.0
talos-cp-lwnkv                      coffee-cluster              proxmox://cb9374b7-873d-48de-afbd-56633a19343a   Provisioned   2m29s   v1.32.0
$ kubectl get proxmoxmachine
NAME                                CLUSTER          READY   NODE                 PROVIDER_ID                                      MACHINE
control-plane-template-lzmdn        coffee-cluster   true    homelab-proxmox-02   proxmox://cb9374b7-873d-48de-afbd-56633a19343a   talos-cp-lwnkv
machinedeploy-workers-bv6bz-2dnxp   coffee-cluster   true    homelab-proxmox-02   proxmox://d5f96316-b669-4549-9598-dceaaff8d9ca   machinedeploy-workers-bv6bz-2dnxp
machinedeploy-workers-bv6bz-gftlh   coffee-cluster   true    homelab-proxmox-02   proxmox://a6f7735a-b909-4f81-ac40-0dbd429c78eb   machinedeploy-workers-bv6bz-gftlh
$ kubectl get machinedeployments
NAME                    CLUSTER          REPLICAS   READY   UPDATED   UNAVAILABLE   PHASE       AGE   VERSION
machinedeploy-workers   coffee-cluster   2                  2         2             ScalingUp   10m   v1.32.0

We can see that the machines are properly provisioned, both on the CAPI side (Machine) and on the Proxmox side (ProxmoxMachine). However, the MachineDeployment shows that no machine is ready (READY).

I don’t know the exact reason, but the capi-controller-manager is clearly indicating that the nodes are not ready:

$ kubectl logs -n capi-system deployments/capi-controller-manager
I0426 09:08:37.030500       1 machine_controller_noderef.go:89] "Infrastructure provider reporting spec.providerID, matching Kubernetes node is not yet available" controller="machine" controllerGroup="cluster.x-k8s.io" controllerKind="Machine" Machine="default/machinedeploy-workers-bv6bz-2dnxp" namespace="default" name="machinedeploy-workers-bv6bz-2dnxp" reconcileID="82959820-448e-490a-9bfc-a221796e4b3b" Cluster="default/coffee-cluster" MachineSet="default/machinedeploy-workers-bv6bz" MachineDeployment="default/machinedeploy-workers" ProxmoxMachine="default/machinedeploy-workers-bv6bz-2dnxp" providerID="proxmox://d5f96316-b669-4549-9598-dceaaff8d9ca"
I0426 09:08:37.031054       1 machine_controller_noderef.go:89] "Infrastructure provider reporting spec.providerID, matching Kubernetes node is not yet available" controller="machine" controllerGroup="cluster.x-k8s.io" controllerKind="Machine" Machine="default/machinedeploy-workers-bv6bz-gftlh" namespace="default" name="machinedeploy-workers-bv6bz-gftlh" reconcileID="be2e4d15-7cc3-4d89-b64a-350714ab0957" Cluster="default/coffee-cluster" MachineSet="default/machinedeploy-workers-bv6bz" MachineDeployment="default/machinedeploy-workers" ProxmoxMachine="default/machinedeploy-workers-bv6bz-gftlh" providerID="proxmox://a6f7735a-b909-4f81-ac40-0dbd429c78eb"

matching Kubernetes node is not yet available… Alright, but why? The node is clearly present in the cluster.

kubectl --kubeconfig ./kubeconfig get nodes
NAME                                STATUS   ROLES           AGE   VERSION
control-plane-template-lzmdn        Ready    control-plane   11m   v1.32.0
machinedeploy-workers-bv6bz-2dnxp   Ready    <none>          11m   v1.32.0
machinedeploy-workers-bv6bz-gftlh   Ready    <none>          11m   v1.32.0

From what I understand of the error message, the capi-controller-manager is unable to link the CAPI machine to the Kubernetes node. It is looking for a spec.providerID field in the Node resource of the CAPI cluster, but it doesn’t exist. But what is this field anyway?

$ kubectl explain node.spec.providerID
KIND:       Node
VERSION:    v1
FIELD: providerID <string>
DESCRIPTION:
  ID of the node assigned by the cloud provider in the format:
  <ProviderName>://<ProviderSpecificNodeID>

This is a field generated by the Infrastructure Provider (in our case, Proxmox) to link the VM to the Kubernetes node. This field is essential to confirm that the machine is indeed present in the cluster and ready.

So, how do we handle this? The first step is to configure CAPI to send this field. To do this, we can add a patch to the configuration of our nodes.

apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxMachineTemplate
metadata:
  name: worker-template
  namespace: default
spec:
  template:
  spec:
  # ...
    checks:
    skipCloudInitStatus: true
    skipQemuGuestAgent: true
+      metadataSettings:
+        providerIDInjection: true
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: ProxmoxMachineTemplate
metadata:
  name: control-plane-template
  namespace: default
spec:
  template:
  spec:
    disks:
    bootVolume:
      disk: scsi0
      sizeGb: 40
    format: qcow2
    full: true
    memoryMiB: 2048
    network:
    default:
      bridge: vmbr0
      model: virtio
    numCores: 2
    numSockets: 1
    sourceNode: homelab-proxmox-02
    templateID: 104
    checks:
    skipCloudInitStatus: true
    skipQemuGuestAgent: true
+      metadataSettings:
+        providerIDInjection: true

After this, CAPI will attempt to inject the spec.providerID field into the Kubernetes Node resource. Let’s see what the capi-controller-manager thinks.

$ kubectl logs -n capi-system deployments/capi-controller-manager
I0426 09:54:35.090983       1 machine_controller_noderef.go:89] "Infrastructure provider reporting spec.providerID, matching Kubernetes node is not yet available" controller="machine" controllerGroup="cluster.x-k8s.io" controllerKind="Machine" Machine="default/machinedeploy-workers-wxbj9-65rxq" namespace="default" name="machinedeploy-workers-wxbj9-65rxq" reconcileID="e5115551-9f16-4b5d-b028-979540aebeac" Cluster="default/coffee-cluster" MachineSet="default/machinedeploy-workers-wxbj9" MachineDeployment="default/machinedeploy-workers" ProxmoxMachine="default/machinedeploy-workers-wxbj9-65rxq" providerID="proxmox://8582a2a4-bdf0-4f0c-9ba6-81ade6b973d6"
I0426 09:54:44.760044       1 machine_controller_noderef.go:89] "Infrastructure provider reporting spec.providerID, matching Kubernetes node is not yet available" controller="machine" controllerGroup="cluster.x-k8s.io" controllerKind="Machine" Machine="default/talos-cp-bm999" namespace="default" name="talos-cp-bm999" reconcileID="45dd7b71-6907-431b-8f7d-8a8c0e876bec" Cluster="default/coffee-cluster" TalosControlPlane="default/talos-cp" ProxmoxMachine="default/control-plane-template-ndw88" providerID="proxmox://00e8da26-8afb-4d97-b995-9a9738b9ac63"

Not yet available… We’re not there yet. I also checked the manifests of the Node resources, and the providerID field is still missing.

The reason for this is that while we configured CAPI to inject the ID through the infrastructure provider, we also need to instruct the Kubelets to accept this information. To do this, we need to add the --cloud-provider=external parameter to the Talos configuration.

apiVersion: bootstrap.cluster.x-k8s.io/v1alpha3
kind: TalosConfigTemplate
metadata:
  name: talosconfig-workers
spec:
  template:
  spec:
    generateType: worker
    talosVersion: v1.9
    configPatches:
      - op: replace
      path: /machine/install
      value:
        disk: /dev/sda
+          - op: add
+            path: /machine/kubelet/extraArgs
+            value:
+              cloud-provider: external
---
apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: talos-cp
spec:
  version: v1.32.0
  replicas: 1
  infrastructureTemplate:
  kind: ProxmoxMachineTemplate
  apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
  name: control-plane-template
  namespace: default
  controlPlaneConfig:
  controlplane:
    generateType: controlplane
    strategicPatches:
    - |
      - op: replace
      path: /machine/install
      value:
        disk: /dev/sda
      - op: add
      path: /machine/install/extraKernelArgs
      value:
        - net.ifnames=0
      - op: add
      path: /machine/network/interfaces
      value:
        - interface: eth0
        dhcp: false
        vip:
          ip: 192.168.1.220
+          - op: add
+            path: /machine/kubelet/extraArgs
+            value:
+                cloud-provider: external

Before restarting the deployment, something important is missing: the Cloud Controller Manager (CCM). This component will modify the Node resources to inject the spec.providerID field. It needs to be installed in the managed cluster. We can install it directly in the Talos configuration.

We also take this opportunity to add the CSR approver, a component that will approve the Certificate Signing Requests (CSRs) sent by the Kubelets, as well as create a secret that the CCM will use to authenticate with the Talos APIs to retrieve machine information.

apiVersion: controlplane.cluster.x-k8s.io/v1alpha3
kind: TalosControlPlane
metadata:
  name: talos-cp
spec:
  controlPlaneConfig:
  controlplane:
    generateType: controlplane
    strategicPatches:
    - |
      # ...
+          - op: add
+            path: /cluster/externalCloudProvider
+            value:
+              enabled: true
+              manifests:
+                - https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml
+                - https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml
+          - op: add
+            path: /machine/kubelet/extraArgs/rotate-server-certificates
+            value: "true"
+          - op: add
+            path: /machine/features/kubernetesTalosAPIAccess
+            value:
+              enabled: true
+              allowedRoles:
+                - os:reader
+              allowedKubernetesNamespaces:
+                - kube-system

Note, the following patch should also be added to the TalosConfigTemplate for the workers:

- op: add
path: /machine/kubelet/extraArgs/rotate-server-certificates
value: "true"

    How does this work?

I asked myself the same question. To find the answer, we need to dive into what CAPMOX (the Proxmox Infrastructure Provider for CAPI) does. As you might expect, it creates a VM on Proxmox and passes its configuration via Cloud-Init. There are many ways to transfer data to Cloud-Init, but the simplest is to dedicate an ISO for this purpose (which is what CAPMOX does).

In my VMs, I therefore have an ISO containing the machine’s configuration. To verify this, I can connect to the Proxmox hypervisor and check the contents of the image.

$ 7z x /var/lib/vz/template/iso/user-data-126.iso
$ cat meta-data
instance-id: 417d9e56-373a-4592-b5c1-dd166d14af7a
local-hostname: machinedeploy-workers-j2r44-p9zlb
hostname: machinedeploy-workers-j2r44-p9zlb
provider-id: proxmox://417d9e56-373a-4592-b5c1-dd166d14af7a
kubernetes-version: v1.32.0

I get three files: meta-data, user-data, and network-config. The meta-data file contains the provider-id field we are trying to inject into the Node resource. The CCM will use this file to inject the spec.providerID field into the Node resource.

Returning to our deployment. Do we finally have the spec.providerID field in the Node resource?

$ kubectl get nodes --kubeconfig kubeconfig control-plane-template-zbgk7 -o yaml | yq .spec.providerID
proxmox://e673922a-27d8-44ae-989a-1dd9f8c05ba9
---
$ kubectl get machines
NAME                                CLUSTER          NODENAME                            PROVIDERID                                       PHASE     AGE   VERSION
machinedeploy-workers-j2r44-p9zlb   coffee-cluster   machinedeploy-workers-j2r44-p9zlb   proxmox://417d9e56-373a-4592-b5c1-dd166d14af7a   Running   15m   v1.32.0
machinedeploy-workers-j2r44-tvjxc   coffee-cluster   machinedeploy-workers-j2r44-tvjxc   proxmox://d3c44a55-cd65-42b1-addb-6583db7bb900   Running   15m   v1.32.0
talos-cp-jrtbc                      coffee-cluster   control-plane-template-zbgk7        proxmox://e673922a-27d8-44ae-989a-1dd9f8c05ba9   Running   15m   v1.32.
---
$ kubectl get machinedeployments.cluster.x-k8s.io
NAME                    CLUSTER          REPLICAS   READY   UPDATED   UNAVAILABLE   PHASE     AGE   VERSION
machinedeploy-workers   coffee-cluster   2          2       2         0             Running   16m   v1.32.0

Finally, we have the spec.providerID field in the Node resource. The Machine and MachineDeployment resources are also updated and show that the machines are ready! We successfully got the CCM working!
Conclusion

This was my first encounter with the Cluster API, and despite the challenges faced, I found it very interesting to get these components, which were not initially designed to work together, to function cohesively.

To make everything clearer, I have summarized the links between the different resources with this diagram:
CAPI Diagram

If you want to find the manifests used in this article, you can find them here.

As with any project using third-party providers, its complexity is directly related to the quality of the documentation. I sometimes had to dig into the code and especially into the resource descriptions via kubectl explain to understand how the resources were linked together and the content of the fields.

I still have other things to test with CAPI, including the integration of an auto-scaling program (or even karpenter), the installation of applications from the management cluster, and the use of ClusterClass.

I’m sure we’ll be talking about this again soon!

Have a good kawa ☕ !