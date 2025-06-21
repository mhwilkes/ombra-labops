# Namespace Organization

This document outlines the namespace organization strategy for the media stack workloads.

## Namespace Structure

### `media` - Consolidated Media Stack ✅ **IMPLEMENTED**

**Purpose**: Single namespace for all media-related applications
**Applications**:
- **Plex Media Server** - Core media consumption service
- **Sonarr** - TV show management
- **Radarr** - Movie management  
- **Prowlarr** - Indexer management
- **Bazarr** - Subtitle management
- **Recyclarr** - Quality profile management
- **qBittorrent** - Torrent client
- **SABnzbd** - Usenet client
- **Overseerr** - Media request management
- **Maintainerr** - Media maintenance
- **Tautulli** - Plex analytics

**Rationale**: 
- **Simplified networking** - No cross-namespace communication needed
- **Easier storage management** - All apps share the same storage volumes naturally
- **Streamlined secrets** - API keys and credentials shared easily between related services  
- **Better resource management** - Unified resource quotas and limits for the entire media stack
- **Simpler backup/restore** - Single namespace to backup
- **Reduced complexity** - Fewer namespace boundaries to manage

### `dashboard` - Monitoring & Management
**Purpose**: Dashboard and monitoring applications (kept separate for different access patterns)
**Applications**:
- Homepage (Service dashboard)

**Rationale**:
- Different security requirements (read-only access to other services)
- Can be exposed differently than core services
- May need access to multiple namespaces for monitoring

## Storage Sharing
All media applications share common storage paths:
- `/opt/downloads` - Shared download directory
- `/opt/plex/media` - Shared media library  
- Individual `/opt/[app]/config` directories

## Benefits of Consolidated Structure

1. **Simplified Communication**: All media apps can communicate directly without FQDN
2. **Unified Resource Management**: Single ResourceQuota for the entire media stack
3. **Easier Troubleshooting**: All related services in one place
4. **Streamlined Security**: Single set of NetworkPolicies and RBAC rules
5. **Better Storage Management**: Natural volume sharing between related services
6. **Simpler Monitoring**: Single namespace to monitor for the entire media pipeline

## Migration Completed ✅

**What was moved to `media` namespace:**
- **From `arr/`**: bazarr, prowlarr, radarr, sonarr, recyclarr
- **From `downloads/`**: qbittorrent, sabnzbd  
- **From `plex/`**: plex, maintainerr, tautulli
- **From `requests/`**: overseerr

**Changes made:**
1. ✅ All application manifests moved to `media/` directory
2. ✅ All namespace references updated to `media`
3. ✅ ArgoCD application consolidated into single `media-stack`
4. ✅ Old directories removed
5. ✅ Documentation updated

## Future Enhancements

Consider adding:
- `monitoring` namespace for Prometheus, Grafana
- `security` namespace for security tools  
- `backup` namespace for backup solutions
- NetworkPolicies within the media namespace for micro-segmentation
- ResourceQuotas for the consolidated media namespace
