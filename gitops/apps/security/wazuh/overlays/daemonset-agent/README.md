# Wazuh Agent DaemonSet Overlay

This overlay deploys a lightweight node-level Wazuh agent (DaemonSet) that approximates a "service mesh style" sidecar pattern without injecting a sidecar into every workload Pod.

## Rationale

Instead of running an agent sidecar per application Pod (high overhead), this model:

- Runs exactly one privileged agent Pod per Kubernetes node.
- Mounts host log directories (`/var/log`, `/var/log/containers`, `/var/log/pods`, CRI runtime dirs) read-only.
- Ships container/stdout logs plus selected host/system logs to the Wazuh manager cluster.
- Uses the existing `wazuh-authd-pass` registration secret and manager service DNS (`wazuh`).

Good when you want broad visibility of container logs with minimal operational burden.

## Contents

Resources introduced by this overlay:

- `DaemonSet wazuh-agent`
- `ServiceAccount wazuh-agent`
- `ClusterRole/ClusterRoleBinding wazuh-agent` (read-only for basic Pod/Namespace metadata — remove if not needed)
- `ConfigMap wazuh-agent-config` providing a minimal `ossec.conf`

## Config

The `ConfigMap` ships a very small `ossec.conf` fragment. Extend as needed (e.g. `cis_docker`, `kubernetes_audit`, `syscheck`, extra `<localfile>` blocks). For broader host security monitoring, add more hostPath mounts (e.g. `/etc`, `/root` with care) and enable related Wazuh modules.

## Registration / Auth

The agent uses `WAZUH_REGISTRATION_PASSWORD` from Secret `wazuh-authd-pass`. Ensure the manager's `authd` is enabled and the password matches what the manager expects.

## Security Notes

- The container is privileged to ensure access to all runtime logs (some CRI setups require this). For stricter hardening, attempt a least-privilege profile by:
  - Dropping `privileged: true` and selectively adding capabilities if required.
  - Using a read-only root filesystem.
  - Adding seccomp / AppArmor profiles.
- Host path mounts are read-only to reduce risk.

## Tuning

Adjust resource requests/limits in `wazuh-agent-daemonset.yaml`. Add a patch if using this overlay alongside others. Example patch snippet:

```yaml
patches:
  - target:
      kind: DaemonSet
      name: wazuh-agent
    patch: |
      apiVersion: apps/v1
      kind: DaemonSet
      metadata:
        name: wazuh-agent
      spec:
        template:
          spec:
            containers:
              - name: agent
                resources:
                  requests:
                    cpu: 100m
                    memory: 256Mi
                  limits:
                    cpu: 500m
                    memory: 512Mi
```

## Deploying This Overlay

If applying directly (outside Argo CD):

```powershell
kubectl apply -k gitops/apps/security/wazuh/overlays/daemonset-agent
```

Or configure an Argo CD Application to point to this overlay instead of the base or other overlays.

## Next Steps / Enhancements

- Add Kubernetes audit log integration (requires API server audit policy + mount).
- Add file integrity monitoring (mount targeted host directories + enable `<syscheck>` section).
- Integrate with Infisical to parameterize additional agent config settings.
- Optionally label nodes to control scheduling (e.g. exclude small edge nodes).

## StatefulSet Immutability Note

If you modify immutable fields of the manager StatefulSets (e.g. `podManagementPolicy`, `serviceName`, or change/remove a `volumeClaimTemplates` entry) after initial creation, a simple `kubectl apply` will fail with:

```text
spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'ordinals', 'template', 'updateStrategy', 'revisionHistoryLimit', 'persistentVolumeClaimRetentionPolicy' and 'minReadySeconds' are forbidden
```

To proceed you must either:

1. Delete the StatefulSet (retain PVCs) and re-apply:

  ```powershell
  kubectl -n wazuh delete sts wazuh-manager-master wazuh-manager-worker --cascade=orphan
  kubectl apply -k gitops/apps/security/wazuh/overlays/daemonset-agent
  ```

1. Or (recommended with Argo CD) use the included `Replace=true` annotation patches so Argo performs a full object replacement.

PVCs are preserved unless explicitly deleted, so logs and state remain intact.

## Troubleshooting Missing Agents

If no agents appear in the Wazuh manager dashboard or `agent_control -lc`, work through these steps:

* Confirm DaemonSet pods exist.

  ```powershell
  kubectl -n wazuh get ds wazuh-agent
  kubectl -n wazuh get pods -l app=wazuh-agent -o wide
  ```

* Inspect an agent pod log for registration lines (look for `authd` / `Connected to`).

  ```powershell
  kubectl -n wazuh logs -l app=wazuh-agent --tail=100
  ```

* Verify the registration password secret.

  ```powershell
  kubectl -n wazuh get secret wazuh-authd-pass -o yaml
  ```

* Check manager logs.

  ```powershell
  kubectl -n wazuh exec -it sts/wazuh-manager-master -- tail -n 100 /var/ossec/logs/ossec.log
  ```

* Confirm DNS resolution from an agent pod.

  ```powershell
  kubectl -n wazuh exec -it $(kubectl -n wazuh get pods -l app=wazuh-agent -o jsonpath='{.items[0].metadata.name}') -- getent hosts wazuh || nslookup wazuh
  ```

* Test TCP connectivity to manager ports (1514 data, 1515 authd).

  ```powershell
  kubectl -n wazuh run tmp-test --rm -i --image=busybox --restart=Never -- sh -c 'nc -vz wazuh 1514 && nc -vz wazuh 1515'
  ```

* List (and optionally prune) registered agents if duplicates or stale entries exist.

  ```powershell
  kubectl -n wazuh exec -it sts/wazuh-manager-master -- /var/ossec/bin/manage_agents -l
  ```

* Ensure manager authd is enabled (check for `<auth>` block in the manager config or defaults in 4.13+).

After adjustments, delete one agent pod to force re-registration:

```powershell
kubectl -n wazuh delete pod <agent-pod-name>
```

---
Questions or tweaks? Extend this overlay or create another specialized one (e.g. `daemonset-agent-hardened`).
