# GitOps Setup Script for Ombra Cluster
# This script sets up ArgoCD and deploys the infrastructure components

param(
    [string]$RepoUrl = "https://github.com/mhwilkes/ombra-labops.git",
    [string]$KubeconfigPath = ".\ombra-kubeconfig",
    [switch]$SkipArgoInstall,
    [switch]$DryRun
)

Write-Host "🚀 Setting up GitOps for Ombra Cluster" -ForegroundColor Green

# Set kubeconfig
if (Test-Path $KubeconfigPath) {
    $env:KUBECONFIG = $KubeconfigPath
    Write-Host "✅ Using kubeconfig: $KubeconfigPath" -ForegroundColor Green
} else {
    Write-Error "❌ Kubeconfig not found at: $KubeconfigPath"
    exit 1
}

# Test cluster connection
Write-Host "🔍 Testing cluster connection..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes --no-headers 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cluster connection successful" -ForegroundColor Green
        Write-Host "📊 Found $($nodes.Count) nodes" -ForegroundColor Cyan
    } else {
        throw "Failed to connect to cluster"
    }
} catch {
    Write-Error "❌ Cannot connect to cluster. Please check your kubeconfig."
    exit 1
}

if (!$SkipArgoInstall) {
    # Create ArgoCD namespace
    Write-Host "📦 Creating ArgoCD namespace..." -ForegroundColor Yellow
    if (!$DryRun) {
        kubectl apply -f .\gitops\bootstrap\argocd-namespace.yaml
    } else {
        Write-Host "DRY RUN: kubectl apply -f .\gitops\bootstrap\argocd-namespace.yaml"
    }

    # Install ArgoCD
    Write-Host "🔧 Installing ArgoCD..." -ForegroundColor Yellow
    if (!$DryRun) {
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Wait for ArgoCD to be ready
        Write-Host "⏳ Waiting for ArgoCD to be ready..." -ForegroundColor Yellow
        kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=300s
    } else {
        Write-Host "DRY RUN: kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
    }
}

# Update App of Apps with correct repo URL
if ($RepoUrl -ne "https://github.com/mhwilkes/ombra-labops.git") {
    Write-Host "🔄 Updating repository URL in configurations..." -ForegroundColor Yellow
    $appOfAppsContent = Get-Content .\gitops\bootstrap\app-of-apps.yaml -Raw
    $appOfAppsContent = $appOfAppsContent -replace "https://github.com/mhwilkes/ombra-labops.git", $RepoUrl
    $appOfAppsContent | Set-Content .\gitops\bootstrap\app-of-apps.yaml
}

# Deploy App of Apps
Write-Host "🎯 Deploying App of Apps..." -ForegroundColor Yellow
if (!$DryRun) {
    kubectl apply -f .\gitops\bootstrap\app-of-apps.yaml
} else {
    Write-Host "DRY RUN: kubectl apply -f .\gitops\bootstrap\app-of-apps.yaml"
}

Write-Host "✅ GitOps setup completed!" -ForegroundColor Green
Write-Host ""
Write-Host "🎉 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Access ArgoCD UI:"
Write-Host "   kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor Yellow
Write-Host "   Open: https://localhost:8080" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Get ArgoCD admin password:"
Write-Host "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=`"{.data.password}`" | base64 -d" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Update repository URLs in the following files:" -ForegroundColor Yellow
Write-Host "   - gitops/bootstrap/app-of-apps.yaml"
Write-Host "   - gitops/apps/infrastructure.yaml"
Write-Host "   - gitops/apps/workloads.yaml"
Write-Host "   - gitops/apps/infrastructure/cert-manager.yaml"
Write-Host "   - gitops/apps/workloads/hello-world.yaml"
Write-Host ""
Write-Host "4. Update IP addresses in:" -ForegroundColor Yellow
Write-Host "   - gitops/apps/infrastructure/cilium.yaml (API server and LoadBalancer IPs)"
Write-Host "   - gitops/apps/infrastructure/nginx-ingress.yaml (LoadBalancer IP)"
Write-Host ""
Write-Host "5. Update domain names in:" -ForegroundColor Yellow
Write-Host "   - gitops/apps/workloads/hello-world/deployment.yaml"
Write-Host "   - gitops/apps/infrastructure/cert-manager/issuers.yaml (email address)"
Write-Host ""
Write-Host "📚 Check the GitOps README for more information: gitops/README.md" -ForegroundColor Cyan
