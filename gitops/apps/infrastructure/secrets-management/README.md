# Secrets Management Setup Guide

## Overview
This setup uses Infisical for secure secrets management, keeping all sensitive data out of Git repositories.

## Setup Process

### 1. Deploy Infisical Operator (via GitOps)
```bash
# This happens automatically via ArgoCD
kubectl get pods -n infisical-operator-system
```

### 2. Setup Infisical Project
1. Create/login to your Infisical account
2. Create a new project (e.g., "ombra-labops")
3. Go to Settings > Machine Identities
4. Create a Universal Auth identity for Kubernetes
5. Copy the Client ID and Client Secret

### 3. Add Secrets to Infisical
In your Infisical project, create secrets at path `/ceph`:

**Required secrets:**
- `userID`: `admin`
- `userKey`: `[your-ceph-admin-key]`
- `adminID`: `admin` 
- `adminKey`: `[your-ceph-admin-key]`

Get the Ceph admin key from your Proxmox cluster:
```bash
# Run on Proxmox node
ceph auth get-key client.admin
```

### 4. Apply Auth Credentials (Manual)
```powershell
# Run the setup script
.\scripts\setup-infisical-auth.ps1
```

This script will:
- Prompt for your Infisical Client ID and Secret
- Base64 encode them securely
- Create the auth secret in Kubernetes
- Never store credentials in Git

### 5. Deploy Storage (via GitOps)
After auth is set up, the storage applications will deploy automatically.

## Security Benefits

✅ **No secrets in Git**  
✅ **Centralized secret management**  
✅ **Audit trails in Infisical**  
✅ **Easy credential rotation**  
✅ **Environment separation**  

## Verification

```bash
# Check Infisical operator
kubectl get pods -n infisical-operator-system

# Check auth secret exists
kubectl get secret infisical-universal-auth -n infisical-operator-system

# Check storage classes are available
kubectl get storageclass
```

## Troubleshooting

**Issue**: InfisicalSecret CRDs not found  
**Solution**: Ensure Infisical operator is running first

**Issue**: Auth failures  
**Solution**: Re-run setup script with correct credentials

**Issue**: Storage not provisioning  
**Solution**: Verify Ceph cluster connectivity and pool names
