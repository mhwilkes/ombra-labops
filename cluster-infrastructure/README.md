# Cluster Infrastructure

This directory contains all the configuration and tools needed to create and manage the Ombra Kubernetes cluster using Cluster API (CAPI) on Proxmox infrastructure.

## Directory Structure

```
cluster-infrastructure/
├── README.md                          # This file
├── clusterctl-config-example.yaml     # Example clusterctl configuration
├── clusterctl-windows-amd64.exe       # ClusterAPI CLI tool
├── ombra-kubeconfig                   # Generated kubeconfig for the cluster
├── ombra-talosconfig                  # Generated Talos configuration
├── controlplanes/                     # Control plane node configurations
│   ├── cluster.yaml                   # Main cluster definition
│   ├── cp-machine-template.yaml       # Control plane machine template
│   ├── proxmox.yaml                   # Proxmox cluster configuration
│   └── taloscontrolplane.yaml         # Talos control plane settings
└── workers/                           # Worker node configurations
    ├── machinedeploy-worker.yaml      # Worker machine deployment
    ├── proxmoxmachinetemplate-worker.yaml # Worker machine template
    └── talosconfig-workers.yaml       # Worker Talos configuration
```

## Prerequisites

1. **Management Cluster**: A Kubernetes cluster with Cluster API components installed
2. **Proxmox Environment**: 
   - Proxmox host: 192.168.20.60:8006
   - API token with sufficient permissions
   - Talos VM template created
3. **Network**: VLAN 55 (192.168.55.0/24) configured

## Quick Start

1. **Configure clusterctl**:
   ```powershell
   # Copy and customize the configuration
   cp clusterctl-config-example.yaml ~/.cluster-api/clusterctl.yaml
   # Edit with your Proxmox credentials and settings
   ```

2. **Initialize Cluster API** (on management cluster):
   ```bash
   clusterctl init --infrastructure proxmox --ipam in-cluster --control-plane talos --bootstrap talos
   ```

3. **Deploy the cluster**:
   ```powershell
   # Run from the repository root
   ./scripts/reset-cluster.ps1  # If redeploying
   
   # Or apply manually:
   kubectl apply -f cluster-infrastructure/controlplanes/
   kubectl apply -f cluster-infrastructure/workers/
   ```

4. **Get cluster access**:
   ```powershell
   # Run from the repository root
   ./scripts/get-cluster-configs.ps1
   ```

## Cluster Specifications

### Infrastructure
- **Platform**: Proxmox VE
- **Network**: VLAN 55 (192.168.55.0/24)
- **Control Plane VIP**: 192.168.55.220
- **Storage**: Ceph distributed storage

### Control Plane Nodes
- **Count**: 3 nodes
- **Resources**: 4 CPU, 4GB RAM, 30GB disk
- **Network**: 10G LACP (vmbr1)

### Worker Nodes  
- **Count**: Configurable (default 3)
- **Resources**: 4 CPU, 8GB RAM, 40GB disk
- **Storage**: Additional 20GB for Ceph

## Configuration Files

### Control Plane
- `cluster.yaml`: Main cluster definition with networking and API server settings
- `cp-machine-template.yaml`: Hardware specs for control plane VMs
- `proxmox.yaml`: Proxmox-specific cluster configuration
- `taloscontrolplane.yaml`: Talos OS configuration for control plane

### Workers
- `machinedeploy-worker.yaml`: Worker node deployment configuration
- `proxmoxmachinetemplate-worker.yaml`: Hardware specs for worker VMs
- `talosconfig-workers.yaml`: Talos OS configuration for workers

## Troubleshooting

1. **Check cluster status**:
   ```bash
   kubectl get clusters,machines,taloscontrolplanes
   ```

2. **View machine logs**:
   ```bash
   kubectl logs -l cluster.x-k8s.io/cluster-name=ombra
   ```

3. **Reset and redeploy**:
   ```powershell
   ./scripts/reset-cluster.ps1
   ```

## Next Steps

After the cluster is deployed and accessible:
1. Verify cluster health: `kubectl get nodes`
2. Set up GitOps: See `../gitops/README.md`
3. Deploy workloads using ArgoCD
