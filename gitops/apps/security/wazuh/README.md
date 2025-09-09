# Wazuh on Kubernetes (GitOps via Argo CD)

This folder wires the official Wazuh Kubernetes manifests (v4.12.0) into your cluster using Kustomize and Argo CD.

What’s included:

- Upstream resources for Wazuh namespace, services, StatefulSets (indexer, managers) and dashboard.
- ConfigMaps for indexer, dashboard, and Wazuh manager configs.
- Secrets for credentials and cluster keys (demo values by default; replace via your secret management).
- A Ceph-backed StorageClass named `wazuh-storage` used by Wazuh PVCs.

Prereqs:

- StorageClass `wazuh-storage` points to your Ceph RBD cluster (`ceph-csi-rbd`). Adjust `storageclass-wazuh.yaml` if needed.
- Certs must be generated and placed in `certs/` so Kustomize can create `indexer-certs` and `dashboard-certs` secrets.

Certificate generation (Windows/PowerShell):

1. Ensure OpenSSL is installed and on PATH:

- winget install ShiningLight.OpenSSL
- or choco install openssl.light

1. Generate self-signed certs into the expected folders:

  ```powershell
  ./scripts/generate-wazuh-certs.ps1
  ```

  This creates:

  - certs/indexer_cluster/{root-ca.pem,node.pem,node-key.pem,dashboard.pem,dashboard-key.pem,admin.pem,admin-key.pem,filebeat.pem,filebeat-key.pem}
  - certs/dashboard_http/{cert.pem,key.pem,root-ca.pem}

  Note: For production, replace with CA-issued certs.

TLS certificates (per Wazuh docs):

- Generate indexer certs (root CA, admin, node, dashboard, filebeat). You can use the upstream script for guidance.
- Generate dashboard HTTPS cert/key.
- Place files under:
  - certs/indexer_cluster/{root-ca.pem,node.pem,node-key.pem,dashboard.pem,dashboard-key.pem,admin.pem,admin-key.pem,filebeat.pem,filebeat-key.pem}
  - certs/dashboard_http/{cert.pem,key.pem}

Kustomize will then create:

- Secret `indexer-certs` with the indexer and related certs.
- Secret `dashboard-certs` with dashboard cert/key and root-ca.

Credentials and keys:

- This kustomization uses Infisical to provision Kubernetes Secrets. Ensure the following keys exist in your Infisical project (example project/env: `ombra-mi-wk` / `prod`):

  - /wazuh/indexer-cred: username, password (base64 not required; Infisical stores plaintext values)
  - /wazuh/dashboard-cred: username, password
  - /wazuh/wazuh-api-cred: username, password
  - /wazuh/wazuh-authd-pass: authd.pass
  - /wazuh/wazuh-cluster-key: key

  The operator will create/update these Kubernetes Secrets in namespace `wazuh`:
  - indexer-cred
  - dashboard-cred
  - wazuh-api-cred
  - wazuh-authd-pass
  - wazuh-cluster-key

  Prerequisite: Deploy `infisical-operator` app, and create the auth secret `infisical-universal-auth` in namespace `infisical-operator-system` (see `scripts/setup-infisical-auth.ps1`).

Apply (Argo CD manages this):

- Argo CD Application at `gitops/apps/security-wazuh.yaml` points here. Once synced, it deploys Wazuh.

Or apply directly with kubectl (useful for a quick test):

1. Set your kubeconfig if needed:

  ```powershell
  $env:KUBECONFIG = "${PWD}/ombra-kubeconfig"
  ```

1. Create namespace (once):

  ```powershell
  kubectl create namespace wazuh --dry-run=client -o yaml | kubectl apply -f -
  ```

1. Apply this kustomization:

  ```powershell
  kubectl apply -k gitops/apps/security/wazuh
  ```

Post-deploy checks (from docs):

- Namespace `wazuh` exists; indexer StatefulSet 3/3 ready; manager master 1/1; workers 2/2; dashboard 1/1.
- Services `wazuh`, `wazuh-workers` (type LoadBalancer), `indexer` (9200), `wazuh-indexer` (headless 9300), and `dashboard` (HTTPS 443) are created.

Security hardening:

- Rotate all default passwords and hashes. Update `internal_users.yml` and related secrets, then re-apply.
- Consider sourcing all secrets from Infisical or sealed-secrets instead of plain YAML.

Storage class:

- The `storageclass-wazuh.yaml` is configured for a Ceph RBD provisioner. If your cluster uses a different provisioner, update the `provisioner` and parameters accordingly. You can list storage classes via:

  ```powershell
  kubectl get sc
  ```

References:

- [Wazuh deployment on Kubernetes](https://documentation.wazuh.com/current/deployment-options/deploying-with-kubernetes/kubernetes-deployment.html)
- [Wazuh Kubernetes configuration](https://documentation.wazuh.com/current/deployment-options/deploying-with-kubernetes/kubernetes-conf.html)
- [wazuh/wazuh-kubernetes v4.12.0](https://github.com/wazuh/wazuh-kubernetes/tree/v4.12.0)
