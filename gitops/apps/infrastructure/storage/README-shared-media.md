# Shared Media Storage Following TRASHGuides

This directory contains the configuration for shared CephFS storage used by media applications, following the [TRASHGuides](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/Docker/) recommended folder structure.

## Overview

The shared media storage provides a unified filesystem that supports:
- **Hardlinks** for instant moves between folders
- **Atomic operations** for efficient file management  
- **Multiple simultaneous access** from different applications
- **Proper permissions** for all media applications

## Folder Structure (TRASHGuides Compatible)

```
/data
├── torrents/           # qBittorrent downloads
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
├── usenet/             # SABnzbd downloads
│   ├── incomplete/     # Active downloads
│   └── complete/
│       ├── movies/
│       ├── tv/
│       ├── music/
│       └── books/
├── downloads/          # General download folder
└── media/              # Final media library
    ├── movies/         # Plex Movies library
    ├── tv/             # Plex TV library  
    ├── music/          # Plex Music library
    └── books/          # Book library
```

## Application Mount Points

Following TRASHGuides recommendations:

### Download Clients
- **qBittorrent**: Mount `/data` → Access to `/data/torrents/`
- **SABnzbd**: Mount `/data` → Access to `/data/usenet/`

### Media Management (Starr Apps)  
- **Sonarr**: Mount `/data` → Full access for TV management
- **Radarr**: Mount `/data` → Full access for movie management  
- **Bazarr**: Mount `/data` → Access to media for subtitles

### Media Servers
- **Plex**: Mount `/data/media` → Access to organized library only

## Implementation Details

### Storage Setup
- **Primary PVC**: `shared-media-data` in `media-storage` namespace (2Ti CephFS)
- **Namespace PVCs**: Local PVCs in each app namespace pointing to same storage
- **Initialization Job**: Creates the directory structure with proper permissions

### CephFS Benefits
- Multiple PVCs can reference the same underlying CephFS volume
- All applications see the same files simultaneously
- Hardlinks work across all mount points
- Atomic moves between directories

## Application Configuration Examples

### Plex (Media Library Access Only)
```yaml
persistence:
  media:
    enabled: true
    existingClaim: shared-media-data
    globalMounts:
      - path: /data/media  # Only access to final library
```

### Sonarr/Radarr (Full Access)
```yaml  
persistence:
  data:
    enabled: true
    existingClaim: shared-media-data
    globalMounts:
      - path: /data  # Full access for management
```

### qBittorrent (Download Access)
```yaml
persistence:
  data:
    enabled: true
    existingClaim: shared-media-data
    globalMounts:
      - path: /data  # Access to download and move to media
```

## Key Advantages

1. **Hardlinks Work**: Files can be instantly moved from downloads to media
2. **Single Source of Truth**: All apps see the same file structure
3. **Efficient Storage**: No duplicate files, instant operations
4. **TRASHGuides Compliant**: Follows community best practices
5. **Scalable**: Easy to add new media applications

## Migration Notes

If migrating from separate storage:
1. Applications may need path reconfiguration
2. Existing downloads may need to be moved to new structure  
3. Plex libraries may need to be rescanned with new paths
4. Download clients need category/path updates

## Troubleshooting

### PVC Not Binding
```bash
kubectl get pvc shared-media-data -n <namespace>
kubectl describe pvc shared-media-data -n <namespace>
```

### Permission Issues
```bash
kubectl logs media-structure-init-xxx -n media-storage
```

### Mount Problems
```bash
kubectl describe pod <app-pod> -n <namespace>
kubectl get events -n <namespace>
```
