# Infrastructure Organization

This directory contains the core infrastructure components organized by function:

## Directory Structure

```
infrastructure/
├── README.md                    # This file
├── infrastructure.yaml          # App-of-Apps for all infrastructure
├── secrets-management.yaml      # Secrets management components
├── storage.yaml                 # Storage infrastructure
├── metallb.yaml                 # Load balancer
├── nginx-ingress.yaml           # Ingress controller
├── cert-manager.yaml            # Certificate management
├── argocd-config.yaml           # ArgoCD configuration
├── argocd-ingress.yaml          # ArgoCD ingress
├── secrets-management/          # Infisical secrets management
│   ├── kustomization.yaml
│   ├── infisical-operator.yaml  # Infisical Kubernetes operator
│   └── infisical-auth.yaml      # Infisical authentication credentials
├── storage/                     # Ceph storage integration
│   ├── kustomization.yaml
│   ├── ceph-secrets.yaml        # Infisical-managed Ceph secrets
│   └── ceph-csi.yaml           # Ceph CSI drivers (RBD + CephFS)
├── cert-manager/               # Certificate management
│   └── issuers.yaml
└── metallb/                    # MetalLB configuration
    ├── kustomization.yaml
    ├── namespace.yaml
    └── metallb-config.yaml
```

## Deployment Order

The infrastructure components have dependencies and deploy in this order:

1. **secrets-management** → Infisical operator and authentication
2. **storage** → Ceph secrets + CSI drivers (depends on secrets-management)
3. **metallb** → Load balancer (independent)
4. **nginx-ingress** → Ingress controller (depends on metallb)
5. **cert-manager** → Certificate management (depends on ingress)
6. **argocd-config** → ArgoCD configuration (depends on cert-manager)

## Storage Classes Available

After deployment, you'll have these storage classes:

- **`ceph-rbd`** - Block storage (ReadWriteOnce)
  - Use for: Databases, application data, single-pod storage
  - Performance: Fast, direct block access
  
- **`ceph-cephfs`** - Shared filesystem (ReadWriteMany)
  - Use for: Media files, shared configuration, multi-pod storage
  - Performance: Good, POSIX-compliant filesystem

## Secrets Management

All sensitive data is managed via Infisical:
- Ceph authentication keys
- TLS certificates (future)
- Application secrets (future)

No secrets are stored in Git repositories.

## Usage Examples

### Block Storage PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
spec:
  storageClassName: ceph-rbd
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
```

### Shared Storage PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: media-storage
spec:
  storageClassName: ceph-cephfs
  accessModes: [ReadWriteMany]
  resources:
    requests:
      storage: 100Gi
```
