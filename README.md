# Ombra Kubernetes Cluster with GitOps

This repository provides a complete solution for deploying and managing a production-ready Kubernetes cluster using modern cloud-native technologies:

- **🏗️ Infrastructure**: Cluster API (CAPI) with Talos Linux on Proxmox VE
- **🚀 GitOps**: ArgoCD for continuous deployment and application management
- **🔧 Automation**: PowerShell scripts for lifecycle management

## Repository Structure

```
ombra-labops/
├── README.md                    # This file - project overview
├── cluster-infrastructure/      # 🏗️ Cluster creation and management
│   ├── controlplanes/          # Control plane node configurations
│   ├── workers/                # Worker node configurations
│   └── README.md               # Infrastructure setup guide
├── gitops/                     # 🚀 GitOps and application deployment
│   └── README.md               # ArgoCD setup and usage
├── scripts/                    # 🔧 Automation and management scripts
│   ├── get-cluster-configs.ps1 # Extract cluster configurations
│   ├── reset-cluster.ps1       # Clean and redeploy cluster
│   ├── setup-gitops.ps1        # Install and configure ArgoCD
│   └── README.md               # Scripts documentation
└── docs/                       # 📚 Comprehensive documentation
    ├── instructions.md          # Detailed technical guide
    └── README.md               # Documentation overview
```

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

## Quick Start

### Phase 1: 🏗️ Deploy the Cluster

1. **Prerequisites**: Set up Proxmox infrastructure and management cluster
   ```powershell
   # See cluster-infrastructure/README.md for detailed setup
   ```

2. **Deploy cluster**:
   ```powershell
   # Option 1: Use the reset script (recommended)
   ./scripts/reset-cluster.ps1
   
   # Option 2: Manual deployment
   kubectl apply -f cluster-infrastructure/controlplanes/
   kubectl apply -f cluster-infrastructure/workers/
   ```

3. **Get cluster access**:
   ```powershell
   ./scripts/get-cluster-configs.ps1
   ```

### Phase 2: 🚀 Setup GitOps with ArgoCD

1. **Deploy ArgoCD and infrastructure**:

   ```powershell
   ./scripts/setup-gitops.ps1 -RepoUrl "https://github.com/your-username/ombra-labops.git"
   ```

2. **Access ArgoCD UI**:

   ```powershell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

   Navigate to <https://localhost:8080>

3. **Get ArgoCD admin password**:

   ```powershell
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

4. **Verify deployments**:
   - CNI (Cilium) with Hubble UI
   - NGINX Ingress Controller
   - cert-manager for SSL certificates
   - Sealed Secrets for secret management

## Architecture Overview

### Infrastructure Components

- **Proxmox VE**: Virtualization platform hosting the cluster
- **Talos Linux**: Immutable, secure OS designed for Kubernetes
- **Cluster API**: Declarative cluster lifecycle management
- **VLAN 55**: Dedicated network (192.168.55.0/24) for cluster nodes

### Cluster Specifications

**Control Plane Nodes**:

- Count: 3 nodes for high availability
- Resources: 4 CPU, 4GB RAM, 30GB disk
- Network: 10G LACP (vmbr1) for performance
- VIP: 192.168.55.220

**Worker Nodes**:

- Count: 3 nodes (scalable)
- Resources: 4 CPU, 8GB RAM, 40GB disk
- Storage: Additional 20GB partition for Ceph

## Documentation

For detailed information, see:

- **[📁 cluster-infrastructure/README.md](./cluster-infrastructure/README.md)**: Complete cluster setup guide
- **[📁 gitops/README.md](./gitops/README.md)**: ArgoCD and GitOps workflows
- **[📁 scripts/README.md](./scripts/README.md)**: Automation scripts documentation
- **[📁 docs/instructions.md](./docs/instructions.md)**: Comprehensive technical deep-dive

## Next Steps

1. **First time setup**: Follow the cluster-infrastructure README
2. **Deploy GitOps**: Run the setup-gitops.ps1 script to deploy ArgoCD and infrastructure
3. **Scale and manage**: Use the provided scripts for ongoing operations
4. **Learn more**: Read the comprehensive documentation in `docs/`

---

*This project demonstrates modern Kubernetes cluster management using GitOps principles and cloud-native technologies.*
