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

---
Questions or tweaks? Extend this overlay or create another specialized one (e.g. `daemonset-agent-hardened`).
