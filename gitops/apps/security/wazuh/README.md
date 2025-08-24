# Wazuh Stack (Kustomize)

This overlay deploys Wazuh Indexer (OpenSearch), Wazuh Dashboard, and Wazuh Manager (master + 2 workers) using Kustomize via Argo CD, aligned with the official Wazuh Kubernetes manifests.

## Prereqs

- Storage classes available: uses `ceph-configs` by default. Adjust PVC sizes in `workloads/*.yaml`.
- Infisical operator installed and Universal Auth secret present.

## Secrets in Infisical

Create the following paths/keys in your project `ombra-mi-wk` env `prod`:

- /wazuh/indexer
  - username (base64 NOT required; Infisical will project raw values)
  - password
- /wazuh/dashboard
  - username
  - password
- /wazuh/api
  - username (default: wazuh-wui)
  - password (meets complexity requirements)
- /wazuh/authd
  - authd.pass (default: password)
- /wazuh/cluster
  - key (shared cluster key)
- /wazuh/certs/indexer
  - root-ca.pem
  - node.pem
  - node-key.pem
  - dashboard.pem
  - dashboard-key.pem
  - admin.pem
  - admin-key.pem
  - filebeat.pem
  - filebeat-key.pem
- /wazuh/certs/dashboard
  - cert.pem
  - key.pem
  - root-ca.pem

Note: You can generate self-signed certs using the scripts in the upstream repo or use cert-manager generated material and export into Infisical.

## Networking

By default, Services `wazuh`, `wazuh-workers`, `indexer`, and `dashboard` are of type LoadBalancer. If you prefer ingress, add an Ingress manifest and set the services to ClusterIP.

## Apply

Managed by Argo CD as `security-wazuh`. Ensure `secrets-management` app is healthy before syncing this app.

## Verify

- kubectl get ns wazuh
- kubectl get sts,deploy,svc -n wazuh
- Access dashboard via its LoadBalancer IP on 443.
