# Kubernetes Rook NFS Media Storage Solution

## Overview

This solution provides shared media storage for Kubernetes applications using Rook-managed NFS exports backed by CephFS. The Rook operator manages NFS servers that export CephFS volumes, allowing applications to mount the same storage directly without needing shared PVCs.

## Architecture

```
CephFS → Rook NFS Server → NFS Export → Direct NFS Mounts in Apps
```

1. **CephFS**: Provides the underlying storage with RWX capability
2. **Rook NFS**: Manages NFS servers that export CephFS volumes within the cluster
3. **Applications**: Mount NFS export directly in their pod specs

## Benefits

- ✅ **True shared storage** across namespaces
- ✅ **No PVC limitations** - mount directly in any namespace  
- ✅ **Simple application configuration** - standard NFS mounts
- ✅ **TRASHGuides directory structure** ready out of the box
- ✅ **Proper file permissions** (UID/GID 1000:1000)
- ✅ **ArgoCD friendly** with dependency management
- ✅ **Production-grade** with Rook CRD management

## Components

### Core Infrastructure
- `ceph-secrets.yaml` - Ceph authentication secrets
- `ceph-csi.yaml` - CephFS CSI driver
- `rook-nfs-ganesha.yaml` - **Main Rook NFS deployment**

### Supporting Resources
- `nfs-shared-storage.yaml` - Media namespaces and verification jobs
- `kustomization.yaml` - Deployment orchestration
- `argocd-storage-app.yaml` - ArgoCD application definition

### Documentation
- `APP-CONFIGURATION.md` - Additional application setup guidance

## Quick Start

1. **Deploy the storage infrastructure**:

   ```bash
   kubectl apply -k .
   ```

2. **Verify Rook NFS is running**:

   ```bash
   kubectl get pods -n rook-ceph
   kubectl logs -n rook-ceph -l app=rook-nfs
   ```

3. **Check verification job results**:

   ```bash   kubectl logs job/nfs-media-verification
   ```

4. **Mount NFS in your applications** - see examples below

## NFS Mount Details

- **Server**: `rook-nfs-media.rook-ceph.svc.cluster.local`
- **Port**: `2049`
- **Export**: `/`
- **Protocol**: NFSv4

## Directory Structure

The NFS export provides the TRASHGuides-compliant structure:

```
/media/
├── media/           # Final media library (Plex reads from here)
│   ├── movies/
│   ├── tv/
│   ├── anime/
│   └── music/
├── torrents/        # qBittorrent downloads here
│   ├── movies/
│   ├── tv/
│   ├── anime/
│   └── music/
└── usenet/          # SABnzbd downloads here
    ├── movies/
    ├── tv/
    ├── anime/
    └── music/
```

## Example Application Mount

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sonarr
  namespace: arr
spec:
  template:
    spec:
      containers:
      - name: sonarr
        image: lscr.io/linuxserver/sonarr:latest
        volumeMounts:
        - name: media-data          mountPath: /data
        env:
        - name: PUID
          value: "1000"
        - name: PGID
          value: "1000"
      volumes:
      - name: media-data
        nfs:
          server: rook-nfs-media.rook-ceph.svc.cluster.local
          path: /
```

## Migration Notes

If you're migrating from PVC-based shared storage:

1. **Keep application config PVCs** (these are per-app, not shared)
2. **Remove shared media PVCs** after confirming NFS mounts work
3. **Update deployments** to use NFS volumes instead of shared PVCs
4. **No data migration needed** - same underlying CephFS storage

## Troubleshooting

Common troubleshooting steps:

- Checking Rook NFS status: `kubectl get pods -n rook-ceph`
- Testing NFS connectivity: `kubectl logs job/nfs-media-verification`  
- Manual mount verification: Check application pod logs
- Common configuration issues: Ensure server name and path are correct

## File Limitations

- **Hardlinks**: May not work across NFS (configure Sonarr/Radarr to copy instead)
- **Permissions**: All apps must use UID/GID 1000:1000
- **Performance**: Good for media streaming, consider mount options for optimization
