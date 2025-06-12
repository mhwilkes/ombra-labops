# GitOps Configuration

This directory contains all GitOps configurations for the Ombra Kubernetes cluster using ArgoCD.

## Structure

```text
gitops/
├── README.md                           # This file
├── bootstrap/                          # ArgoCD bootstrap configurations
│   ├── argocd-namespace.yaml          # ArgoCD namespace
│   ├── argocd-install.yaml            # ArgoCD installation
│   └── app-of-apps.yaml               # App of Apps pattern
├── apps/                               # Application definitions
│   ├── argocd/                        # ArgoCD self-management
│   ├── infrastructure/                # Core infrastructure apps
│   │   ├── cilium/                    # CNI (Cilium)
│   │   ├── nginx-ingress/             # Ingress controller
│   │   ├── cert-manager/              # Certificate management
│   │   └── sealed-secrets/            # Secret management
│   └── workloads/                     # Application workloads
└── environments/                       # Environment-specific configs
    └── production/                    # Production environment
```

## Quick Start

1. **Bootstrap ArgoCD**:

   ```powershell
   kubectl apply -f bootstrap/
   ```

2. **Access ArgoCD UI**:

   ```powershell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

   Navigate to <https://localhost:8080>

3. **Get initial admin password**:

   ```powershell
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

## Management

All applications are managed through the "App of Apps" pattern. The main application (`app-of-apps`) manages all other applications, including infrastructure components and workloads.
