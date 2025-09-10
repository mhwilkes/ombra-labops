# Wazuh TLS via cert-manager

This folder contains `Certificate` resources issued by cert-manager to supply the secrets expected by the upstream Wazuh manifests:

Secrets produced (names MUST match upstream volume secretName references):

- `indexer-certs` (opaque bundle) : Root CA + node/admin/filebeat/dashboard cert/key pairs
- `dashboard-certs` : HTTPS certificate for the dashboard + root CA

Because the upstream Wazuh manifests expect a single secret (`indexer-certs`) containing many different certificate/key filenames, we use the following approach:

1. A self-signed private CA (or ACME-issued wildcard if preferred) is created using a Certificate resource (`wazuh-root-ca`).
2. Individual leaf certificates (admin, node, filebeat, dashboard) are issued by referencing that CA via `issuerRef` that points to a namespaced Issuer created from the CA secret.
3. A `post-render` kustomize patch (or simple `Secret` composition job) would usually be needed to merge them. Instead, we leverage cert-manager `Certificate` with `commonName`/`dnsNames` and the `secretTemplate` annotation keys to shape key filenames. However cert-manager stores only one key/cert pair per secret. So to truly mimic the upstream flat multi-key secret we aggregate certificates using a Kubernetes `Job` (optional) OR we refactor mounts to use separate secrets.

Simpler path adopted here: Refactor the Wazuh manifest mounts to reference separate secrets per component (node/admin/filebeat/dashboard) while keeping environment variable paths the same. This avoids a custom aggregation controller.

Resulting secrets (each standard tls.key/tls.crt):

- `wazuh-node-tls`
- `wazuh-admin-tls`
- `wazuh-filebeat-tls`
- `wazuh-dashboard-tls`
- `wazuh-root-ca` (CA cert stored as tls.crt)

We then patch the StatefulSets/Deployment using projected volumes that merge these individual secrets back into the filenames the upstream manifests expect (e.g. node.pem, node-key.pem, admin.pem, filebeat.pem, root-ca.pem, etc.). This keeps the upstream container args/env unchanged while leveraging cert-manager lifecycle management (renewal & rotation).

If you prefer to retain a literal single secret, an aggregation job or controller would be required; projected volumes are simpler and dynamic.
