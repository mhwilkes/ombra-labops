# Example application updates for TRASHGuides compliant shared storage
# This shows how to update your existing applications to use the new shared storage approach

# Note: These are examples of how to update your existing application configurations
# You would apply these changes to your actual application YAML files

# Example 1: Plex - Media Library Access Only
# Update gitops/apps/workloads/plex/plex.yaml
---
# In the persistence section, change from:
# media:
#   enabled: true
#   existingClaim: shared-media-data
#   globalMounts:
#     - path: /data

# To this TRASHGuides compliant approach:
persistence:
  config:
    enabled: true
    type: persistentVolumeClaim
    storageClass: ceph-rbd
    size: 10Gi
    accessMode: ReadWriteOnce
    globalMounts:
      - path: /config
  media:
    enabled: true
    existingClaim: shared-media-data  # This now references the namespace-local PVC
    globalMounts:
      - path: /data/media  # Mount only the media subdirectory
        subPath: media     # CephFS subPath to limit access
  transcode:
    enabled: true
    type: emptyDir
    sizeLimit: 10Gi
    globalMounts:
      - path: /transcode

---
# Example 2: Sonarr - Full Data Access
# Update gitops/apps/workloads/arr/sonarr.yaml
---
persistence:
  config:
    enabled: true
    type: persistentVolumeClaim
    storageClass: ceph-rbd
    size: 1Gi
    accessMode: ReadWriteOnce
    globalMounts:
      - path: /config
  data:
    enabled: true
    existingClaim: shared-media-data  # References the arr namespace PVC
    globalMounts:
      - path: /data  # Full access to all data for management

---
# Example 3: qBittorrent - Downloads and Media Access
# Update gitops/apps/workloads/downloads/qbittorrent.yaml
---
persistence:
  config:
    enabled: true
    type: persistentVolumeClaim
    storageClass: ceph-rbd
    size: 1Gi
    accessMode: ReadWriteOnce
    globalMounts:
      - path: /config
  data:
    enabled: true
    existingClaim: shared-media-data  # References the downloads namespace PVC
    globalMounts:
      - path: /data  # Full access for downloading and moving files

# Application Settings Notes:
# ========================

# qBittorrent Settings:
# - Default Save Path: /data/torrents/
# - Category paths:
#   - movies: /data/torrents/movies/
#   - tv: /data/torrents/tv/
#   - music: /data/torrents/music/

# Sonarr Settings:
# - Root Folder: /data/media/tv/
# - Download Client Category: tv
# - Completed Download Handling: /data/torrents/tv/ → /data/media/tv/

# Radarr Settings: 
# - Root Folder: /data/media/movies/
# - Download Client Category: movies
# - Completed Download Handling: /data/torrents/movies/ → /data/media/movies/

# SABnzbd Settings:
# - Incomplete Folder: /data/usenet/incomplete/
# - Complete Folder: /data/usenet/complete/
# - Category folders:
#   - movies: /data/usenet/complete/movies/
#   - tv: /data/usenet/complete/tv/

# Plex Settings:
# - Movies Library: /data/media/movies/
# - TV Library: /data/media/tv/
# - Music Library: /data/media/music/
