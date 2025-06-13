# BJW-S Workloads Setup

This directory contains workload definitions using the [bjw-s app-template](https://github.com/bjw-s/helm-charts/tree/main/charts/other/app-template) Helm chart. This chart provides a standardized way to deploy applications in Kubernetes with sensible defaults and extensive customization options.

## Overview

The bjw-s app-template chart is designed to:
- Reduce boilerplate YAML for common application deployments
- Provide consistent patterns across different applications
- Support complex scenarios while maintaining simplicity for basic use cases
- Follow Kubernetes best practices

## Available Workloads

### Media Server (`plex` namespace)

- **Plex** (`plex.yaml`) - Media server with LoadBalancer on 192.168.55.210

### Media Management (`arr` namespace)

- **Sonarr** (`sonarr.yaml`) - TV show management
- **Radarr** (`radarr.yaml`) - Movie management  
- **Prowlarr** (`prowlarr.yaml`) - Indexer management for *arr apps

### Download Clients (`downloads` namespace)

- **qBittorrent** (`qbittorrent.yaml`) - Torrent client with LoadBalancer on 192.168.55.211
- **SABnzbd** (`sabnzbd.yaml`) - Usenet downloader

### Dashboard (`dashboard` namespace)

- **Homepage** (`homepage.yaml`) - Beautiful dashboard for all services

## Quick Start

1. **Review and customize the configurations**:
   - Update domain names in ingress sections (currently set to `*.local.example.com`)
   - Modify IP addresses for LoadBalancer services
   - Set appropriate storage paths for your environment
   - Configure API keys and environment variables

2. **Commit and push changes**:
   ```powershell
   git add .
   git commit -m "Add bjw-s workloads"
   git push
   ```

3. **ArgoCD will automatically sync the applications** (assuming your GitOps is set up)

## Configuration Guide

### Essential Customizations

#### 1. Domain Names
Update all ingress hostnames:
```yaml
ingress:
  app:
    hosts:
      - host: your-app.your-domain.com  # Change this
```

#### 2. Storage Paths
Ensure host paths exist and have correct permissions:
```yaml
persistence:
  config:
    hostPath: /opt/your-app/config  # Update paths
    hostPathType: DirectoryOrCreate
```

#### 3. LoadBalancer IPs
Reserve and configure IPs in your network:
```yaml
service:
  app:
    type: LoadBalancer
    loadBalancerIP: 192.168.55.XXX  # Use available IP
```

#### 4. Environment Variables
Configure application-specific settings:
```yaml
env:
  TZ: America/New_York  # Your timezone
  APP_API_KEY: "your-api-key"  # Generated API keys
```

### Security Considerations

1. **API Keys**: Generate unique API keys for each application
2. **Storage Permissions**: Ensure proper file ownership (UID/GID 1000 for most apps)
3. **Network Isolation**: Consider using NetworkPolicies for sensitive applications
4. **TLS Certificates**: Configure cert-manager for automatic SSL certificates

### Storage Setup

Before deploying, create the required directories on your nodes:

```bash
# For media stack
sudo mkdir -p /opt/{plex,sonarr,radarr,prowlarr,qbittorrent,sabnzbd}/config
sudo mkdir -p /opt/downloads /opt/plex/media/{movies,tv} /opt/sabnzbd/incomplete
sudo chown -R 1000:1000 /opt/{plex,sonarr,radarr,prowlarr,qbittorrent,sabnzbd,downloads}
```

## Chart Features

### Controllers
Define the main application containers, init containers, and sidecars.

### Services  
Expose applications within the cluster or externally via LoadBalancer/NodePort.

### Ingress
Route external traffic to services with nginx ingress controller integration.

### Persistence
Support for various storage types:
- `hostPath` - Direct host filesystem mounting
- `configMap` - Configuration data
- `secret` - Sensitive data
- `emptyDir` - Temporary storage
- `persistentVolumeClaim` - Dynamic storage

### ConfigMaps & Secrets
Manage application configuration and sensitive data.

## Troubleshooting

### Common Issues

1. **Pod stuck in Pending**:
   - Check storage path permissions
   - Verify LoadBalancer IP availability
   - Check resource constraints

2. **Configuration not loading**:
   - Verify ConfigMap data syntax
   - Check mount paths in containers
   - Ensure file permissions

3. **Ingress not working**:
   - Verify nginx-ingress is running
   - Check DNS resolution
   - Validate TLS certificates

### Useful Commands

```powershell
# Check ArgoCD sync status
kubectl get applications -n argocd

# View pod logs
kubectl logs -n plex deployment/plex
kubectl logs -n arr deployment/sonarr
kubectl logs -n downloads deployment/qbittorrent

# Check service endpoints
kubectl get endpoints -n plex
kubectl get endpoints -n arr
kubectl get endpoints -n downloads
kubectl get endpoints -n dashboard

# Describe failing pods
kubectl describe pod -n arr <pod-name>
```

## Advanced Patterns

See `_template-examples.yaml` for advanced configuration patterns including:
- Multiple containers per pod
- Init containers
- Complex networking
- Security contexts
- Health checks

## Resources

- [BJW-S App Template Chart](https://github.com/bjw-s/helm-charts/tree/main/charts/other/app-template)
- [Chart Documentation](https://bjw-s-labs.github.io/helm-charts/docs/app-template/)
- [Values.yaml Reference](https://github.com/bjw-s/helm-charts/blob/main/charts/other/app-template/values.yaml)
- [Common Application Examples](https://github.com/onedr0p/home-ops)
