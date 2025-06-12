# Scripts

This directory contains PowerShell scripts for managing the Ombra Kubernetes cluster lifecycle and GitOps setup.

## Scripts Overview

### `get-cluster-configs.ps1`
**Purpose**: Extract TalosConfig and Kubeconfig from a deployed CAPI cluster

**Usage**:
```powershell
./get-cluster-configs.ps1 [-ClusterName "ombra"] [-OutputDir "."]
```

**What it does**:
- Retrieves the Talos configuration from the cluster secret
- Extracts the kubeconfig using Talos CLI
- Saves both configurations to the specified output directory
- Validates cluster connectivity

**Prerequisites**:
- `kubectl` access to management cluster
- `talosctl` CLI tool installed
- Cluster must be in "Provisioned" state

### `reset-cluster.ps1`
**Purpose**: Clean up and redeploy cluster resources

**Usage**:
```powershell
./reset-cluster.ps1
```

**What it does**:
- Removes existing cluster resources from management cluster
- Waits for cleanup to complete
- Redeploys cluster using YAML manifests
- Monitors deployment progress

**Use Cases**:
- Cluster deployment failed and needs reset
- Configuration changes require clean redeploy
- Testing cluster deployment process


**Features**:
- Automatic port-forwarding setup
- Admin password retrieval
- Health checks and validation
- Sample application deployment

## Prerequisites

All scripts require:
- PowerShell 5.1 or higher
- `kubectl` CLI tool
- Access to appropriate cluster contexts

Additional requirements per script:
- `get-cluster-configs.ps1`: `talosctl` CLI

## Common Parameters

### ClusterName
Default: `"ombra"`
The name of the cluster as defined in the CAPI cluster resource.

### KubeconfigPath
Default: `"./ombra-kubeconfig"`
Path to the kubeconfig file for the target cluster.

### OutputDir
Default: `"."`
Directory where generated configuration files will be saved.

## Error Handling

All scripts include:
- Comprehensive error checking
- Helpful error messages
- Cleanup on failure
- Progress indicators

## Examples

### Complete Cluster Setup Workflow
```powershell
# 1. Deploy cluster (using kubectl or reset script)
./reset-cluster.ps1

# 2. Wait for cluster to be ready, then get configs
./get-cluster-configs.ps1 -OutputDir "./cluster-infrastructure"

```

### Development Workflow
```powershell
# Make changes to cluster manifests, then reset
./reset-cluster.ps1

# After successful deployment, update configs
./get-cluster-configs.ps1

```

## Troubleshooting

### Common Issues

**Script execution policy**:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**kubectl context**:
Ensure you're connected to the management cluster before running deployment scripts:
```powershell
kubectl config current-context
kubectl get nodes
```

**Missing CLI tools**:
- Install `kubectl`: [Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/)
- Install `talosctl`: [Talos documentation](https://talos.dev/docs/)

### Script-specific Issues

**get-cluster-configs.ps1**:
- Verify cluster is in "Provisioned" state
- Check Talos control plane endpoint accessibility
- Ensure proper RBAC permissions

**reset-cluster.ps1**:
- Confirm management cluster connectivity
- Verify YAML manifest paths
- Check for stuck resources that need manual cleanup

## Best Practices

1. **Always check prerequisites** before running scripts
2. **Use version control** to track configuration changes
3. **Test in development** before applying to production
4. **Monitor progress** and logs during execution
5. **Keep backups** of working configurations
