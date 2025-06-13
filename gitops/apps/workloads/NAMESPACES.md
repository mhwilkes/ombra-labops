# Namespace Organization

This document outlines the namespace organization strategy for the media stack workloads.

## Namespace Structure

### `plex` - Media Server
**Purpose**: Dedicated namespace for Plex media server
**Applications**:
- Plex Media Server

**Rationale**: 
- Plex is the core media consumption service
- Isolates media serving from management/download operations
- Easier to apply specific security policies and resource quotas
- Can be scaled independently

### `arr` - Media Management
**Purpose**: *arr application suite for media automation
**Applications**:
- Sonarr (TV shows)
- Radarr (Movies)  
- Prowlarr (Indexer management)

**Rationale**:
- These applications work closely together
- Shared configuration patterns and security requirements
- Common resource usage patterns
- Logical grouping for monitoring and troubleshooting

### `downloads` - Download Clients
**Purpose**: Download client applications
**Applications**:
- qBittorrent (Torrent client)
- SABnzbd (Usenet client)

**Rationale**:
- Download operations are resource-intensive
- Separate security boundary for potentially higher-risk operations
- Easier to apply network policies for external connections
- Can apply specific resource limits for download operations

### `dashboard` - Monitoring & Management
**Purpose**: Dashboard and monitoring applications
**Applications**:
- Homepage (Service dashboard)

**Rationale**:
- Central monitoring and access point
- Different security requirements (read-only access to other services)
- Can be exposed differently than core services

## Cross-Namespace Communication

### Service Discovery
Applications can communicate across namespaces using fully qualified domain names:
- `service-name.namespace.svc.cluster.local`
- Example: `qbittorrent.downloads.svc.cluster.local`

### Storage Sharing
All applications share common storage paths:
- `/opt/downloads` - Shared download directory
- `/opt/plex/media` - Shared media library
- Individual `/opt/[app]/config` directories

### Network Policies (Future Enhancement)
Consider implementing NetworkPolicies to:
- Allow arr apps to communicate with download clients
- Allow Plex to access media directories
- Restrict external access to download clients
- Allow dashboard to query all services

## Benefits of This Structure

1. **Security Isolation**: Each namespace can have different security policies
2. **Resource Management**: Apply resource quotas per functional area
3. **Monitoring**: Easier to monitor and alert on functional areas
4. **Scaling**: Scale different components independently
5. **Troubleshooting**: Isolate issues to specific functional areas
6. **Access Control**: Different RBAC policies per namespace

## Migration Notes

When migrating from the previous single `media` namespace:
1. Applications will be recreated in new namespaces
2. ConfigMaps and Secrets will need to be recreated
3. Persistent volumes should be preserved (using hostPath)
4. Service discovery URLs between apps may need updates

## Future Enhancements

Consider adding:
- `monitoring` namespace for Prometheus, Grafana
- `security` namespace for security tools
- `backup` namespace for backup solutions
- NetworkPolicies for enhanced security
- ResourceQuotas per namespace
