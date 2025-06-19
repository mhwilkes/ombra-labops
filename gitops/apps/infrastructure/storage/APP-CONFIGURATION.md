# Application Configuration for Shared Storage

After deploying the shared storage, you'll need to configure each application to use the proper paths according to TRASHGuides structure.

## Directory Structure Available

```
/data/
├── torrents/
│   ├── movies/
│   ├── tv/
│   ├── music/
│   └── books/
├── usenet/
│   ├── incomplete/
│   └── complete/
│       ├── movies/
│       ├── tv/
│       ├── music/
│       └── books/
├── downloads/          # General downloads
└── media/             # Final organized library
    ├── movies/
    ├── tv/
    ├── music/
    └── books/
```

## Application Configuration Settings

### qBittorrent Settings
**Default Save Path**: `/data/torrents/`

**Categories** (Configure in qBittorrent WebUI):
- `movies` → `/data/torrents/movies/`
- `tv` → `/data/torrents/tv/`
- `music` → `/data/torrents/music/`
- `books` → `/data/torrents/books/`

### SABnzbd Settings
**Folders** (Configure in SABnzbd WebUI):
- **Temporary Download Folder**: `/data/usenet/incomplete/`
- **Completed Download Folder**: `/data/usenet/complete/`

**Categories**:
- `movies` → `/data/usenet/complete/movies/`
- `tv` → `/data/usenet/complete/tv/`
- `music` → `/data/usenet/complete/music/`
- `books` → `/data/usenet/complete/books/`

### Sonarr Settings
**Media Management**:
- **Root Folder**: `/data/media/tv/`
- **Use Hardlinks instead of Copy**: ✅ Enabled

**Download Client** (qBittorrent):
- **Category**: `tv`
- **Completed Download Handling**: ✅ Enabled
- **Remove Completed**: ✅ Enabled (after import)

**Download Client** (SABnzbd):
- **Category**: `tv`
- **Completed Download Handling**: ✅ Enabled

### Radarr Settings
**Media Management**:
- **Root Folder**: `/data/media/movies/`
- **Use Hardlinks instead of Copy**: ✅ Enabled

**Download Client** (qBittorrent):
- **Category**: `movies`
- **Completed Download Handling**: ✅ Enabled
- **Remove Completed**: ✅ Enabled (after import)

**Download Client** (SABnzbd):
- **Category**: `movies`
- **Completed Download Handling**: ✅ Enabled

### Bazarr Settings
**Languages**:
- **TV Shows Path**: `/data/media/tv/`
- **Movies Path**: `/data/media/movies/`

### Plex Settings
**Libraries**:
- **Movies Library**: `/data/media/movies/`
- **TV Shows Library**: `/data/media/tv/`
- **Music Library**: `/data/media/music/` (if used)

## How It Works (TRASHGuides Flow)

1. **Download**: qBittorrent downloads to `/data/torrents/movies/`
2. **Import**: Radarr hardlinks from `/data/torrents/movies/` → `/data/media/movies/`
3. **Stream**: Plex reads from `/data/media/movies/`
4. **Subtitles**: Bazarr adds subtitles to files in `/data/media/movies/`

## Benefits

- **Instant Moves**: Hardlinks mean no copying, instant import
- **No Duplicate Storage**: One file, multiple "locations"
- **Shared Access**: All apps see the same files
- **Proper Permissions**: All apps run as UID/GID 2000

## Verification Commands

```bash
# Check shared storage is mounted
kubectl get pvc shared-media-data -n plex
kubectl get pvc shared-media-data -n arr  
kubectl get pvc shared-media-data -n downloads

# Check directory structure was created
kubectl exec -n media-storage deployment/some-app -- ls -la /data/

# Test from each application
kubectl exec -n plex deployment/plex -- ls -la /data/media/
kubectl exec -n arr deployment/sonarr -- ls -la /data/
kubectl exec -n downloads deployment/qbittorrent -- ls -la /data/torrents/
```

## Troubleshooting

### Permission Issues
If apps can't write to shared storage:
```bash
# Check ownership in the shared volume
kubectl exec -n media-storage job/media-structure-init -- ls -lan /data/

# Should show: drwxrwxr-x 2000 2000
```

### Path Not Found
If apps can't find directories:
```bash
# Verify directory structure exists
kubectl exec -n downloads deployment/qbittorrent -- find /data -type d | sort
```

### Hardlinks Not Working
```bash
# Test hardlink creation (should not show "Invalid cross-device link")
kubectl exec -n arr deployment/sonarr -- ln /data/torrents/tv/test.file /data/media/tv/test.file
```
