# Script to uninstall and reinstall Kubernetes cluster resources
# Created: June 8, 2025

# Set error action preference
$ErrorActionPreference = "Continue"

# Get the script's directory and calculate the repository root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$ClusterInfraPath = Join-Path $RepoRoot "cluster-infrastructure"

Write-Host "Script directory: $ScriptDir" -ForegroundColor Gray
Write-Host "Repository root: $RepoRoot" -ForegroundColor Gray
Write-Host "Cluster infrastructure path: $ClusterInfraPath" -ForegroundColor Gray

function Write-Step {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
}

function Invoke-ClusterCommand {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command,
        
        [Parameter(Mandatory=$true)]
        [string]$Description
    )
    
    Write-Host "`n> $Description" -ForegroundColor Yellow
    Write-Host "> Running: $Command" -ForegroundColor Gray
    
    try {
        Invoke-Expression $Command
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Command completed with non-zero exit code: $LASTEXITCODE" -ForegroundColor Yellow
        } else {
            Write-Host "Command completed successfully" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error executing command: $_" -ForegroundColor Red
    }
}

# STEP 1: Uninstall all resources
Write-Step "STEP 1: Uninstalling all cluster resources"

# Delete in reverse order of dependencies
Invoke-ClusterCommand -Command "kubectl delete -f `"$ClusterInfraPath/workers/machinedeploy-worker.yaml`" --ignore-not-found" -Description "Deleting worker machine deployment"
Invoke-ClusterCommand -Command "kubectl delete -f `"$ClusterInfraPath/workers/talosconfig-workers.yaml`" --ignore-not-found" -Description "Deleting worker Talos config"
Invoke-ClusterCommand -Command "kubectl delete -f `"$ClusterInfraPath/workers/proxmoxmachinetemplate-worker.yaml`" --ignore-not-found" -Description "Deleting worker machine template"
Invoke-ClusterCommand -Command "kubectl delete -f `"$ClusterInfraPath/controlplanes/taloscontrolplane.yaml`" --ignore-not-found" -Description "Deleting Talos control plane"
Invoke-ClusterCommand -Command "kubectl delete -f `"$ClusterInfraPath/controlplanes/cp-machine-template.yaml`" --ignore-not-found" -Description "Deleting control plane machine template"
Invoke-ClusterCommand -Command "kubectl delete -f `"$ClusterInfraPath/controlplanes/cluster.yaml`" --ignore-not-found" -Description "Deleting cluster"
Invoke-ClusterCommand -Command "kubectl delete -f `"$ClusterInfraPath/controlplanes/proxmox.yaml`" --ignore-not-found" -Description "Deleting Proxmox provider"

# Wait for resources to be deleted
Write-Step "Waiting for resources to be fully deleted"
Start-Sleep -Seconds 10
Invoke-ClusterCommand -Command "kubectl get clusters,machines,proxmoxmachines,taloscontrolplanes,machinedeployments" -Description "Verifying all resources are deleted"

# STEP 2: Reinstall all resources
Write-Step "STEP 2: Reinstalling cluster resources"

# Apply in order of dependencies
Invoke-ClusterCommand -Command "kubectl apply -f `"$ClusterInfraPath/controlplanes/proxmox.yaml`"" -Description "Applying Proxmox provider"
Invoke-ClusterCommand -Command "kubectl apply -f `"$ClusterInfraPath/controlplanes/cluster.yaml`"" -Description "Applying cluster configuration"
Invoke-ClusterCommand -Command "kubectl apply -f `"$ClusterInfraPath/controlplanes/cp-machine-template.yaml`"" -Description "Applying control plane machine template"
Invoke-ClusterCommand -Command "kubectl apply -f `"$ClusterInfraPath/controlplanes/taloscontrolplane.yaml`"" -Description "Applying Talos control plane"
Invoke-ClusterCommand -Command "kubectl apply -f `"$ClusterInfraPath/workers/proxmoxmachinetemplate-worker.yaml`"" -Description "Applying worker machine template"
Invoke-ClusterCommand -Command "kubectl apply -f `"$ClusterInfraPath/workers/talosconfig-workers.yaml`"" -Description "Applying worker Talos config"
Invoke-ClusterCommand -Command "kubectl apply -f `"$ClusterInfraPath/workers/machinedeploy-worker.yaml`"" -Description "Applying worker machine deployment"

# STEP 3: Check status
Write-Step "STEP 3: Checking status of deployed resources"

Invoke-ClusterCommand -Command "kubectl get clusters,taloscontrolplanes,machinedeployments" -Description "Checking high-level resources"
Invoke-ClusterCommand -Command "kubectl get machines,proxmoxmachines" -Description "Checking machine resources"
Invoke-ClusterCommand -Command "kubectl get pods -n capmox-system" -Description "Checking CAPMOX controller pods"
Invoke-ClusterCommand -Command "kubectl logs -n capmox-system deployment/capmox-controller-manager -c manager --tail 50" -Description "Checking controller logs"
Invoke-ClusterCommand -Command "kubectl get events --sort-by='.lastTimestamp' | Select-Object -Last 20" -Description "Checking recent events"

Write-Step "Script completed"
Write-Host "To manually check the status, run: kubectl get clusters,machines" -ForegroundColor Magenta
Write-Host "To check controller logs, run: kubectl logs -n capmox-system deployment/capmox-controller-manager -c manager --follow" -ForegroundColor Magenta
