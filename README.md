# Ombra Kubernetes Cluster on Proxmox with Talos

This repository contains the Cluster API (CAPI) configuration for deploying a Talos Linux-based Kubernetes cluster named "ombra" on Proxmox infrastructure.

## Infrastructure Details

- **Cluster name**: ombra
- **Proxmox host**: 192.168.20.60:8006
- **Proxmox nodes**:
  - pve-r640-01
  - pve-r740xd-01
  - pve-r740xd-02
- **Network**: VLAN 55 (192.168.55.0/24)
- **Network interfaces**:
  - vmbr0: 2x 1G NICs with LACP
  - vmbr1: 2x 10G SFP NICs with LACP (used for this cluster)
- **Storage**: Ceph for persistent storage

## Prerequisites

1. A Talos VM template in Proxmox (template ID referenced in the configuration)
2. Proxmox API token with sufficient permissions
3. Management Kubernetes cluster with Cluster API components installed

## Setup Instructions

1. Create a Proxmox API token for CAPI to use:
   ```bash
   # On the Proxmox host
   pveum user add capmox@pve
   pveum aclmod / -user capmox@pve -role PVEVMAdmin
   pveum user token add capmox@pve capi -privsep
   ```

2. Configure the clusterctl configuration:
   ```bash
   # Create or update ~/.cluster-api/clusterctl.yaml
   # Use the provided clusterctl-config-example.yaml as a reference
   ```

3. Initialize Cluster API on your management cluster:
   ```bash
   clusterctl init --infrastructure proxmox --ipam in-cluster --control-plane talos --bootstrap talos
   ```

4. Create the Talos template in Proxmox:
   - Download the latest Talos ISO from https://github.com/siderolabs/talos/releases
   - Create a template VM in Proxmox with at least 2GB RAM and 20GB disk
   - Attach the Talos ISO
   - Enable qemu-guest-agent in the VM options
   - Record the template ID and update the YAML files if necessary

5. Deploy the cluster:
   ```bash
   # Apply the Proxmox cluster configuration
   kubectl apply -f controlplanes/proxmox.yaml
   
   # Apply the cluster definition
   kubectl apply -f controlplanes/cluster.yaml
   
   # Apply the control plane machine template
   kubectl apply -f controlplanes/cp-machine-template.yaml
   
   # Apply the talos control plane configuration
   kubectl apply -f controlplanes/taloscontrolplane.yaml
   
   # Apply worker configurations
   kubectl apply -f workers/proxmoxmachinetemplate-worker.yaml
   kubectl apply -f workers/talosconfig-workers.yaml
   kubectl apply -f workers/machinedeploy-worker.yaml
   ```

6. Get the kubeconfig for the new cluster:
   ```bash
   # Once the control plane is ready, you can get the kubeconfig
   # First, get the talosconfig file
   clusterctl get talosconfig ombra > ombra-talosconfig
   
   # Then get the kubeconfig for the cluster
   talosctl --talosconfig ombra-talosconfig kubeconfig --nodes 192.168.55.220 -e 192.168.55.220
   ```

## Resource Specifications

### Control Plane Nodes
- 4 CPU cores
- 4GB RAM
- 30GB disk
- Ceph storage partition (10GB)

### Worker Nodes
- 4 CPU cores
- 8GB RAM
- 40GB disk
- Ceph storage partition (20GB)

## Cluster Network

- Control plane VIP: 192.168.55.220
- Node IPs: 192.168.55.210-192.168.55.219
- Gateway: 192.168.55.1
- Subnet: 192.168.55.0/24
- DNS: 192.168.20.20

## Ceph Storage Configuration

Once your cluster is deployed, you can proceed with configuring Ceph storage using the pre-allocated partitions at `/var/lib/ceph` on both control plane and worker nodes.

## Notes

- The control plane uses the faster 10G network (vmbr1)
- Workers are distributed across different Proxmox nodes for high availability
- The Talos version is set to v1.33.0 (latest as of configuration)
- QEMU guest agent is enabled for better VM management
