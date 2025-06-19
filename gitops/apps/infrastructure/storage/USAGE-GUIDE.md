# How to Use the Shared Media Storage

This guide shows how to configure your applications to use the shared CephFS storage.

## Overview

We use a **single PVC** (`shared-media-data`) in the `media-storage` namespace that can be referenced by applications in other namespaces using Kubernetes cross-namespace volume mounting.

## Application Configuration Method

### Option 1: Cross-Namespace PVC Reference (Recommended)

Each application can reference the shared PVC using this pattern:

```yaml
# In your application's persistence configuration
persistence:
  data:
    enabled: true
    type: custom
    volumeSpec:
      persistentVolumeClaim:
        claimName: shared-media-data
        # Note: PVC is in media-storage namespace
    globalMounts:
      - path: /data  # or appropriate subpath
```

### Option 2: Using hostPath (Alternative)

If cross-namespace PVC references don't work, you can mount the same underlying storage via hostPath after it's mounted on a node:

```yaml
persistence:
  data:
    enabled: true
    type: hostPath
    hostPath: /var/lib/kubelet/pods/*/volumes/kubernetes.io~csi/pvc-*/mount
    globalMounts:
      - path: /data
```

### Option 3: Create Local PVC References (Most Compatible)

Create a PVC in each namespace that references the same storage:

```yaml
# In each application namespace (plex, arr, downloads)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-media-data
  namespace: <app-namespace>
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ceph-cephfs
  resources:
    requests:
      storage: 2Ti
```

## Application Examples

### Plex Configuration
```yaml
# In gitops/apps/workloads/plex/plex.yaml
persistence:
  config:
    enabled: true
    type: persistentVolumeClaim
    storageClass: ceph-rbd
    size: 10Gi
    globalMounts:
      - path: /config
  media:
    enabled: true
    existingClaim: shared-media-data  # References local PVC
    globalMounts:
      - path: /data/media  # Only mount media subdirectory
        subPath: media
```

### Sonarr Configuration
```yaml
# In gitops/apps/workloads/arr/sonarr.yaml
persistence:
  config:
    enabled: true
    type: persistentVolumeClaim
    storageClass: ceph-rbd
    size: 1Gi
    globalMounts:
      - path: /config
  data:
    enabled: true
    existingClaim: shared-media-data  # References local PVC
    globalMounts:
      - path: /data  # Full access to all data
```

### qBittorrent Configuration
```yaml
# In gitops/apps/workloads/downloads/qbittorrent.yaml
persistence:
  config:
    enabled: true
    type: persistentVolumeClaim
    storageClass: ceph-rbd
    size: 1Gi
    globalMounts:
      - path: /config
  data:
    enabled: true
    existingClaim: shared-media-data  # References local PVC
    globalMounts:
      - path: /data  # Full access for downloads
```

## Required PVCs per Namespace

Add this to each application's namespace:

### For Plex namespace:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-media-data
  namespace: plex
spec:
  accessModes: [ReadWriteMany]
  storageClassName: ceph-cephfs
  resources:
    requests:
      storage: 2Ti
```

### For Arr namespace:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-media-data
  namespace: arr
spec:
  accessModes: [ReadWriteMany]
  storageClassName: ceph-cephfs
  resources:
    requests:
      storage: 2Ti
```

### For Downloads namespace:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-media-data
  namespace: downloads
spec:
  accessModes: [ReadWriteMany]
  storageClassName: ceph-cephfs
  resources:
    requests:
      storage: 2Ti
```

## Verification

After deployment, verify the shared storage:

```bash
# Check the main PVC
kubectl get pvc -n media-storage

# Check if directory structure was created
kubectl logs -n media-storage job/media-structure-init

# Check application PVCs
kubectl get pvc shared-media-data -n plex
kubectl get pvc shared-media-data -n arr  
kubectl get pvc shared-media-data -n downloads
```

## Next Steps

1. Deploy the storage configuration
2. Add the PVC definitions to each application namespace
3. Update applications to use `existingClaim: shared-media-data`
4. Configure application paths according to TRASHGuides structure
