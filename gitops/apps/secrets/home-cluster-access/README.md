# Cluster Kubeconfig Access

This application generates a kubeconfig file that allows you to access your Kubernetes cluster via `kubectl`.

## How It Works

A PreSync hook job runs before ArgoCD syncs this application. The job:
1. Finds the ArgoCD cluster secret containing the kubeconfig
2. Extracts the kubeconfig
3. Creates two resources in the `argocd` namespace:
   - **Secret**: `cluster-kubeconfig` - Contains the kubeconfig file (ready to download)
   - **ConfigMap**: `cluster-kubeconfig-view` - Contains base64-encoded kubeconfig (easier to view/copy)

Both resources are labeled with `purpose=cluster-access` for easy filtering in the ArgoCD UI.

## Accessing Your Kubeconfig

### Via ArgoCD UI:

1. **Navigate to Resources**:
   - Go to your ArgoCD UI
   - Click on "Applications" → Select "home-cluster-access" or "secrets-stack"
   - Click on the "Resources" tab
   - Filter by label: `purpose=cluster-access`

2. **Download the Secret**:
   - Find the secret `cluster-kubeconfig` in the `argocd` namespace
   - Click on it to view details
   - Download the `kubeconfig` key value
   - Save it as `~/.kube/config` or use with: `kubectl --kubeconfig=./kubeconfig get nodes`

3. **Or View the ConfigMap**:
   - Find the configmap `cluster-kubeconfig-view` in the `argocd` namespace
   - Copy the `kubeconfig.b64` value
   - Decode it: `echo '<base64-value>' | base64 -d > kubeconfig`

### Direct Access (if you have kubectl access):

```bash
# Get the kubeconfig from secret
kubectl -n argocd get secret cluster-kubeconfig -o jsonpath='{.data.kubeconfig}' | base64 -d > ~/.kube/config

# Or get from configmap
kubectl -n argocd get configmap cluster-kubeconfig-view -o jsonpath='{.data.kubeconfig\.b64}' | base64 -d > ~/.kube/config
```

## Troubleshooting

### Job Fails to Find Cluster Secret
- Verify ArgoCD has a cluster secret: Check ArgoCD UI → Settings → Clusters
- The job looks for secrets with label `argocd.argoproj.io/secret-type=cluster`

### Secret Not Appearing
- Check the job logs in the `secrets` namespace
- Verify RBAC permissions are correct
- Manually trigger a sync of the `home-cluster-access` application

### Kubeconfig Not Working
- The job validates the kubeconfig before creating the secret
- Check if the ArgoCD cluster secret is valid
- You may need to regenerate the cluster secret in ArgoCD

## Manual Refresh

To regenerate the kubeconfig, simply trigger a sync of the `home-cluster-access` application in ArgoCD. The PreSync hook will run again and update the secret/configmap.

