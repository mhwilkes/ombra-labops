# GitOps Setup Script for Talos Cluster
# This script installs ArgoCD and sets up GitOps workflow
# Created: June 11, 2025

param(
    [Parameter(Mandatory=$false)]
    [string]$KubeconfigPath = ".\ombra-kubeconfig",
    
    [Parameter(Mandatory=$false)]
    [string]$ArgoNamespace = "argocd"
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "`n==============================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "==============================================" -ForegroundColor Cyan
}

function Wait-ForDeployment {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Namespace,
        
        [Parameter(Mandatory=$true)]
        [string]$DeploymentName,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 300
    )
    
    Write-Host "⏳ Waiting for deployment $DeploymentName to be ready..." -ForegroundColor Yellow
    
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $ready = kubectl --kubeconfig=$KubeconfigPath get deployment $DeploymentName -n $Namespace -o jsonpath='{.status.readyReplicas}' 2>$null
        $desired = kubectl --kubeconfig=$KubeconfigPath get deployment $DeploymentName -n $Namespace -o jsonpath='{.status.replicas}' 2>$null
        
        if ($ready -eq $desired -and $ready -gt 0) {
            Write-Host "✅ Deployment $DeploymentName is ready!" -ForegroundColor Green
            return $true
        }
        
        Start-Sleep -Seconds 10
        $elapsed += 10
        Write-Host "  Still waiting... ($elapsed/$TimeoutSeconds seconds)" -ForegroundColor Gray
    }
    
    Write-Warning "Timeout waiting for deployment $DeploymentName"
    return $false
}

# Set kubeconfig
$env:KUBECONFIG = $KubeconfigPath

Write-Step "Setting up GitOps with ArgoCD"

# Verify cluster connectivity
Write-Host "🔍 Verifying cluster connectivity..." -ForegroundColor Yellow
try {
    $nodes = kubectl get nodes --no-headers 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cannot connect to cluster. Check your kubeconfig."
        exit 1
    }
    $nodeCount = ($nodes | Measure-Object).Count
    Write-Host "✅ Connected to cluster with $nodeCount nodes" -ForegroundColor Green
} catch {
    Write-Error "Failed to connect to cluster: $_"
    exit 1
}

# Create ArgoCD namespace
Write-Step "Installing ArgoCD"
Write-Host "📦 Creating ArgoCD namespace..." -ForegroundColor Yellow
kubectl create namespace $ArgoNamespace --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
Write-Host "📦 Installing ArgoCD..." -ForegroundColor Yellow
kubectl apply -n $ArgoNamespace -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
Write-Host "⏳ Waiting for ArgoCD to start up..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check ArgoCD deployments
$argoDeployments = @("argocd-application-controller", "argocd-dex-server", "argocd-redis", "argocd-repo-server", "argocd-server")

foreach ($deployment in $argoDeployments) {
    Wait-ForDeployment -Namespace $ArgoNamespace -DeploymentName $deployment -TimeoutSeconds 300
}

Write-Step "Configuring ArgoCD Access"

# Get ArgoCD admin password
Write-Host "🔑 Getting ArgoCD admin password..." -ForegroundColor Yellow
$adminPassword = kubectl -n $ArgoNamespace get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>$null

if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrEmpty($adminPassword)) {
    $decodedPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($adminPassword))
    Write-Host "✅ ArgoCD admin password retrieved" -ForegroundColor Green
    
    # Save credentials to file
    $credentialsFile = "argocd-credentials.txt"
    @"
ArgoCD Credentials
==================
Username: admin
Password: $decodedPassword

Access URLs:
- Port Forward: kubectl port-forward svc/argocd-server -n argocd 8080:443
- Then browse to: https://localhost:8080
- Accept the self-signed certificate

CLI Login:
argocd login localhost:8080 --username admin --password $decodedPassword --insecure
"@ | Out-File -FilePath $credentialsFile -Encoding UTF8
    
    Write-Host "📄 Credentials saved to: $credentialsFile" -ForegroundColor Green
} else {
    Write-Warning "Could not retrieve ArgoCD admin password. Check manually with:"
    Write-Host "kubectl -n $ArgoNamespace get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" -ForegroundColor Gray
}

Write-Step "Creating GitOps Application Structure"

# Create applications directory
$appsDir = "gitops-apps"
if (-not (Test-Path $appsDir)) {
    New-Item -ItemType Directory -Path $appsDir -Force | Out-Null
    Write-Host "📁 Created directory: $appsDir" -ForegroundColor Green
}

# Create ArgoCD Application manifest for the apps directory
$appOfAppsManifest = @"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: $ArgoNamespace
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/your-gitops-repo.git  # TODO: Replace with your repo
    targetRevision: HEAD
    path: gitops-apps
  destination:
    server: https://kubernetes.default.svc
    namespace: $ArgoNamespace
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
"@

$appOfAppsManifest | Out-File -FilePath "$appsDir\app-of-apps.yaml" -Encoding UTF8

# Create sample application manifest
$sampleAppManifest = @"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-nginx
  namespace: $ArgoNamespace
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: 15.14.2
    helm:
      releaseName: sample-nginx
      values: |
        service:
          type: ClusterIP
        ingress:
          enabled: false
        resources:
          requests:
            memory: 64Mi
            cpu: 50m
          limits:
            memory: 128Mi
            cpu: 100m
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
"@

$sampleAppManifest | Out-File -FilePath "$appsDir\sample-nginx-app.yaml" -Encoding UTF8

# Create monitoring application manifest
$monitoringAppManifest = @"
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kube-prometheus-stack
  namespace: $ArgoNamespace
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: 65.2.0
    helm:
      releaseName: prometheus
      values: |
        prometheus:
          prometheusSpec:
            resources:
              requests:
                memory: 400Mi
                cpu: 100m
              limits:
                memory: 800Mi
                cpu: 200m
        grafana:
          enabled: true
          adminPassword: admin123
          resources:
            requests:
              memory: 128Mi
              cpu: 50m
            limits:
              memory: 256Mi
              cpu: 100m
        alertmanager:
          enabled: false
        kubeStateMetrics:
          enabled: true
        nodeExporter:
          enabled: true
        prometheusOperator:
          resources:
            requests:
              memory: 100Mi
              cpu: 50m
            limits:
              memory: 200Mi
              cpu: 100m
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
"@

$monitoringAppManifest | Out-File -FilePath "$appsDir\monitoring-app.yaml" -Encoding UTF8

Write-Host "📁 Created sample GitOps applications in: $appsDir" -ForegroundColor Green

Write-Step "Creating Git Repository Setup Instructions"

$gitSetupInstructions = @"
GitOps Setup Instructions
=========================

1. CREATE A GIT REPOSITORY
   - Create a new repository on GitHub/GitLab (e.g., 'homelab-gitops')
   - Clone it locally or push the gitops-apps folder to it

2. UPDATE THE APP-OF-APPS
   - Edit gitops-apps\app-of-apps.yaml
   - Replace 'https://github.com/yourusername/your-gitops-repo.git' with your actual repo URL

3. PUSH TO YOUR REPOSITORY
   git init
   git add .
   git commit -m "Initial GitOps setup"
   git remote add origin https://github.com/yourusername/your-gitops-repo.git
   git push -u origin main

4. DEPLOY THE APP-OF-APPS
   kubectl apply -f gitops-apps\app-of-apps.yaml

5. ACCESS ARGOCD
   # Start port forwarding
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   
   # Open browser to https://localhost:8080
   # Login with admin / (password from argocd-credentials.txt)

6. MANAGE APPLICATIONS
   - Add new applications by creating YAML files in gitops-apps/
   - Push changes to Git
   - ArgoCD will automatically sync them

SAMPLE APPLICATIONS INCLUDED:
- sample-nginx-app.yaml: Simple nginx deployment
- monitoring-app.yaml: Prometheus + Grafana stack

NEXT STEPS:
- Set up ingress controller for external access
- Configure monitoring dashboards
- Add more applications as needed
"@

$gitSetupInstructions | Out-File -FilePath "gitops-setup-instructions.txt" -Encoding UTF8

Write-Step "GitOps Setup Complete!"

Write-Host "🎉 ArgoCD is now installed and ready!" -ForegroundColor Green
Write-Host "📖 See 'gitops-setup-instructions.txt' for next steps" -ForegroundColor Yellow
Write-Host "🔑 ArgoCD credentials are in 'argocd-credentials.txt'" -ForegroundColor Yellow

Write-Host "`n🚀 Quick Start:" -ForegroundColor Cyan
Write-Host "1. kubectl port-forward svc/argocd-server -n argocd 8080:443" -ForegroundColor White
Write-Host "2. Open https://localhost:8080" -ForegroundColor White
Write-Host "3. Login with admin and password from argocd-credentials.txt" -ForegroundColor White

Write-Host "`n📁 Created GitOps structure:" -ForegroundColor Cyan
Write-Host "  gitops-apps/" -ForegroundColor White
Write-Host "  ├── app-of-apps.yaml" -ForegroundColor White
Write-Host "  ├── sample-nginx-app.yaml" -ForegroundColor White
Write-Host "  └── monitoring-app.yaml" -ForegroundColor White
