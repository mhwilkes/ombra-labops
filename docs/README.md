# Documentation

This directory contains comprehensive documentation for the Ombra Kubernetes cluster project.

## Documents

### `instructions.md`
Complete walkthrough and technical deep-dive covering:
- Cluster API concepts and architecture
- Proxmox infrastructure setup
- Talos Linux configuration
- Step-by-step deployment process
- Troubleshooting and best practices

This document provides the foundational knowledge needed to understand and work with the cluster infrastructure.

## Quick Reference

### Project Overview
This repository manages a production-ready Kubernetes cluster using:
- **Cluster API (CAPI)** for declarative cluster management
- **Talos Linux** as the minimalist, secure OS for Kubernetes nodes
- **Proxmox VE** as the virtualization infrastructure
- **ArgoCD** for GitOps-based application deployment

### Repository Structure
```
ombra-labops/
├── README.md                    # Project overview and quick start
├── cluster-infrastructure/      # Cluster creation and management
├── gitops/                     # ArgoCD and application deployment
├── scripts/                    # Automation scripts
└── docs/                       # Documentation (this directory)
```

### Common Workflows

#### Initial Setup
1. Review `instructions.md` for background knowledge
2. Set up Proxmox infrastructure per requirements
3. Configure management cluster with Cluster API
4. Deploy cluster using `cluster-infrastructure/` configurations
5. Set up GitOps with `scripts/setup-gitops.ps1`

#### Day-to-Day Operations
1. Manage cluster through GitOps workflows
2. Deploy applications via ArgoCD
3. Monitor cluster health and applications
4. Scale workloads as needed

#### Troubleshooting
1. Check cluster status with `kubectl` commands
2. Review ArgoCD for application sync issues
3. Use Talos tools for OS-level debugging
4. Reference troubleshooting sections in documentation

### External Resources

#### Official Documentation
- [Cluster API Documentation](https://cluster-api.sigs.k8s.io/)
- [Talos Linux Documentation](https://talos.dev/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)

#### Community Resources
- [Cluster API Slack](https://kubernetes.slack.com/messages/cluster-api)
- [Talos Community](https://talos.dev/community/)
- [ArgoCD Community](https://argoproj.github.io/community/)

### Contributing

When making changes to this project:
1. Update relevant documentation
2. Test changes in development environment
3. Follow GitOps principles for deployment
4. Document any new procedures or troubleshooting steps
