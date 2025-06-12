# Script to extract TalosConfig and Kubeconfig from CAPI cluster
# Created: June 11, 2025

param(
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "ombra",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get the script's directory and calculate the repository root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir

# Set default output directory to repository root if not specified
if (-not $OutputDir) {
    $OutputDir = $RepoRoot
}

Write-Host "Script directory: $ScriptDir" -ForegroundColor Gray
Write-Host "Repository root: $RepoRoot" -ForegroundColor Gray
Write-Host "Output directory: $OutputDir" -ForegroundColor Gray

function Write-Step {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
}

function Get-Base64DecodedContent {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Base64String
    )
    
    try {
        return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Base64String))
    } catch {
        Write-Error "Failed to decode base64 content: $_"
        return $null
    }
}

function Extract-ClusterConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$SecretName,
        
        [Parameter(Mandatory=$true)]
        [string]$DataKey,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory=$true)]
        [string]$Description
    )
    
    Write-Host "`n> Extracting $Description..." -ForegroundColor Yellow
    
    try {
        # Get the secret
        $secretData = kubectl get secret $SecretName -o jsonpath="{.data.$DataKey}" 2>$null
        
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($secretData)) {
            Write-Warning "Secret '$SecretName' not found or empty. Cluster may not be ready yet."
            return $false
        }
        
        # Decode and save
        $decodedContent = Get-Base64DecodedContent -Base64String $secretData
        
        if ($null -eq $decodedContent) {
            Write-Warning "Failed to decode $Description"
            return $false
        }
        
        $outputPath = Join-Path $OutputDir $OutputFile
        $decodedContent | Out-File -FilePath $outputPath -Encoding UTF8 -NoNewline
        
        Write-Host "✓ $Description saved to: $outputPath" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "Failed to extract $Description`: $_"
        return $false
    }
}

function Test-ClusterConnectivity {
    param (
        [Parameter(Mandatory=$true)]
        [string]$KubeconfigPath,
        
        [Parameter(Mandatory=$true)]
        [string]$TalosconfigPath
    )
    
    Write-Step "Testing cluster connectivity"
    
    if (Test-Path $KubeconfigPath) {
        Write-Host "`n> Testing Kubernetes API connectivity..." -ForegroundColor Yellow
        
        try {
            $nodes = kubectl --kubeconfig=$KubeconfigPath get nodes --no-headers 2>$null
            if ($LASTEXITCODE -eq 0) {
                $nodeCount = ($nodes | Measure-Object).Count
                Write-Host "✓ Kubernetes API accessible - $nodeCount nodes found" -ForegroundColor Green
                
                # Show node status
                Write-Host "`n> Node Status:" -ForegroundColor Yellow
                kubectl --kubeconfig=$KubeconfigPath get nodes -o wide
            } else {
                Write-Warning "Kubernetes API not accessible yet"
            }
        } catch {
            Write-Warning "Failed to test Kubernetes connectivity: $_"
        }
    }
    
    if (Test-Path $TalosconfigPath) {
        Write-Host "`n> Testing Talos API connectivity..." -ForegroundColor Yellow
        
        try {
            # Try to get cluster endpoint from ProxmoxCluster
            $endpoint = kubectl get proxmoxcluster proxmox-cluster -o jsonpath='{.spec.controlPlaneEndpoint.host}' 2>$null
            
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($endpoint)) {
                Write-Host "  Using endpoint: $endpoint" -ForegroundColor Gray
                
                $talosVersion = talosctl --talosconfig=$TalosconfigPath -n $endpoint version --short 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✓ Talos API accessible" -ForegroundColor Green
                    Write-Host "  $talosVersion" -ForegroundColor Gray
                } else {
                    Write-Warning "Talos API not accessible yet at $endpoint"
                }
            } else {
                Write-Warning "Could not determine cluster endpoint"
            }
        } catch {
            Write-Warning "Failed to test Talos connectivity: $_"
        }
    }
}

function Show-Usage {
    param (
        [Parameter(Mandatory=$true)]
        [string]$KubeconfigPath,
        
        [Parameter(Mandatory=$true)]
        [string]$TalosconfigPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ClusterEndpoint
    )
    
    Write-Step "Usage Instructions"
    
    Write-Host "Your cluster configs are ready! Here's how to use them:`n" -ForegroundColor Green
    
    Write-Host "📋 Kubernetes (kubectl):" -ForegroundColor Cyan
    Write-Host "  kubectl --kubeconfig=$KubeconfigPath get nodes" -ForegroundColor White
    Write-Host "  kubectl --kubeconfig=$KubeconfigPath get pods -A" -ForegroundColor White
    Write-Host "`n  Or set as default:" -ForegroundColor Yellow
    Write-Host "  `$env:KUBECONFIG = `"$KubeconfigPath`"" -ForegroundColor White
    Write-Host "  kubectl get nodes" -ForegroundColor White
    
    Write-Host "`n🔧 Talos (talosctl):" -ForegroundColor Cyan
    Write-Host "  talosctl --talosconfig=$TalosconfigPath -n $ClusterEndpoint version" -ForegroundColor White
    Write-Host "  talosctl --talosconfig=$TalosconfigPath -n $ClusterEndpoint get members" -ForegroundColor White
    Write-Host "  talosctl --talosconfig=$TalosconfigPath -n $ClusterEndpoint dashboard" -ForegroundColor White
    
    Write-Host "`n🔍 Lens IDE:" -ForegroundColor Cyan
    Write-Host "  1. Open Lens" -ForegroundColor White
    Write-Host "  2. Click 'Add Cluster' or press Ctrl+Shift+A" -ForegroundColor White
    Write-Host "  3. Select 'From kubeconfig'" -ForegroundColor White
    Write-Host "  4. Browse to: $KubeconfigPath" -ForegroundColor White
    
    Write-Host "`n📡 Cluster Endpoint: https://$ClusterEndpoint`:6443" -ForegroundColor Magenta
}

# Main execution
Write-Step "Extracting Talos Cluster Configurations"
Write-Host "Cluster: $ClusterName" -ForegroundColor White
Write-Host "Output Directory: $OutputDir" -ForegroundColor White

# Check if kubectl is available
try {
    kubectl version --client --short >$null 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "kubectl is not available or not in PATH"
        exit 1
    }
} catch {
    Write-Error "kubectl is not available: $_"
    exit 1
}

# Check if we're connected to the management cluster
try {
    $currentContext = kubectl config current-context 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Current kubectl context: $currentContext" -ForegroundColor Gray
    } else {
        Write-Warning "No kubectl context set. Make sure you're connected to your management cluster."
    }
} catch {
    Write-Warning "Could not determine current kubectl context"
}

# Define output files
$kubeconfigFile = "$ClusterName-kubeconfig"
$talosconfigFile = "$ClusterName-talosconfig"

# Extract TalosConfig
$talosSuccess = Extract-ClusterConfig -SecretName "$ClusterName-talosconfig" -DataKey "talosconfig" -OutputFile $talosconfigFile -Description "TalosConfig"

# Extract Kubeconfig  
$kubeSuccess = Extract-ClusterConfig -SecretName "$ClusterName-kubeconfig" -DataKey "value" -OutputFile $kubeconfigFile -Description "Kubeconfig"

# Test connectivity if both configs were extracted
if ($talosSuccess -and $kubeSuccess) {
    $kubeconfigPath = Join-Path $OutputDir $kubeconfigFile
    $talosconfigPath = Join-Path $OutputDir $talosconfigFile
    
    Test-ClusterConnectivity -KubeconfigPath $kubeconfigPath -TalosconfigPath $talosconfigPath
    
    # Get cluster endpoint for usage instructions
    try {
        $endpoint = kubectl get proxmoxcluster proxmox-cluster -o jsonpath='{.spec.controlPlaneEndpoint.host}' 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($endpoint)) {
            Show-Usage -KubeconfigPath $kubeconfigPath -TalosconfigPath $talosconfigPath -ClusterEndpoint $endpoint
        }
    } catch {
        Write-Warning "Could not determine cluster endpoint for usage instructions"
    }
} else {
    Write-Host "`n⚠️  Some configurations could not be extracted." -ForegroundColor Yellow
    Write-Host "This usually means the cluster is still initializing." -ForegroundColor Yellow
    Write-Host "Wait a few minutes and run this script again." -ForegroundColor Yellow
    
    # Show what we can check
    Write-Host "`n🔍 To check cluster status:" -ForegroundColor Cyan
    Write-Host "  kubectl get clusters,taloscontrolplanes,machines" -ForegroundColor White
    Write-Host "  kubectl get events --sort-by='.lastTimestamp' | Select-Object -Last 10" -ForegroundColor White
}

Write-Step "Script completed"
