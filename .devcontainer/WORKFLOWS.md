# Common IaC Workflows

This document provides step-by-step workflows for common Infrastructure as Code tasks. Each workflow combines multiple tools to accomplish specific goals.

## Table of Contents

- [Terraform Workflows](#terraform-workflows)
- [Kubernetes Workflows](#kubernetes-workflows)
- [GitOps Workflows](#gitops-workflows)
- [Debugging Workflows](#debugging-workflows)
- [Validation Workflows](#validation-workflows)

---

## Terraform Workflows

### Workflow: Create and Deploy Terraform Infrastructure

**Goal**: Create new Terraform configuration and deploy it safely.

**Steps**:

1. **Initialize Terraform**:

   ```bash
   tfi
   ```

2. **Format code**:

   ```bash
   tff
   ```

3. **Lint code**:

   ```bash
   tflint
   ```

4. **Validate configuration**:

   ```bash
   tfv
   ```

5. **Security scan**:

   ```bash
   checkov --directory . --framework terraform
   ```

6. **Plan changes**:

   ```bash
   tfp
   ```

7. **Review plan output**:

   ```bash
   # Review the plan carefully
   tfp | bat
   ```

8. **Apply changes**:

   ```bash
   tfa
   ```

**AI Agent Notes**: Always run validation and security scans before applying. Use aliases for brevity.

---

### Workflow: Update Existing Terraform Configuration

**Goal**: Modify existing Terraform code and deploy changes.

**Steps**:

1. **Make changes to `.tf` files**

2. **Format code**:

   ```bash
   tff
   ```

3. **Lint code**:

   ```bash
   tflint
   ```

4. **Validate**:

   ```bash
   tfv
   ```

5. **Plan changes**:

   ```bash
   tfp
   ```

6. **Review plan**:

   ```bash
   # Check what will change
   tfp | grep -E "will be|must be|will replace"
   ```

7. **Apply if plan looks good**:

   ```bash
   tfa
   ```

**AI Agent Notes**: Git hooks will run automatically on commit. Review plan output carefully before applying.

---

### Workflow: Refactor Terraform Code

**Goal**: Improve Terraform code structure without changing infrastructure.

**Steps**:

1. **Backup current state** (if using local state):

   ```bash
   cp terraform.tfstate terraform.tfstate.backup
   ```

2. **Refactor code** (rename resources, reorganize files, etc.)

3. **Format code**:

   ```bash
   tff
   ```

4. **Lint code**:

   ```bash
   tflint
   ```

5. **Validate**:

   ```bash
   tfv
   ```

6. **Plan to verify no changes**:

   ```bash
   tfp
   # Should show "No changes"
   ```

7. **Commit changes**:

   ```bash
   ga .
   gc -m "refactor: improve Terraform code structure"
   ```

**AI Agent Notes**: Always verify with `terraform plan` that refactoring doesn't change infrastructure.

---

## Kubernetes Workflows

### Workflow: Debug Pod Issues

**Goal**: Troubleshoot a failing pod in Kubernetes.

**Steps**:

1. **Switch to correct context**:

   ```bash
   kctx-switch <cluster-name>
   ```

2. **Switch to namespace**:

   ```bash
   kns-switch <namespace>
   ```

3. **Check pod status**:

   ```bash
   kg pods
   kg pods -o wide
   ```

4. **Describe pod for details**:

   ```bash
   kd pod <pod-name>
   ```

5. **View pod logs**:

   ```bash
   kl <pod-name>
   kl -f <pod-name>  # Follow logs
   ```

6. **If multiple pods, use stern**:

   ```bash
   klogs <pod-pattern>
   ```

7. **Execute in pod for debugging**:

   ```bash
   ke <pod-name> -- /bin/sh
   ```

**AI Agent Notes**: Use `stern` for multi-pod deployments.

---

### Workflow: Deploy New Kubernetes Application

**Goal**: Deploy a new application to Kubernetes.

**Steps**:

1. **Create or review manifests**:

   ```bash
   # View manifest
   bat deployment.yaml

   # Validate YAML
   yaml-lint deployment.yaml
   ```

2. **Validate with kubectl**:

   ```bash
   k apply --dry-run=client -f deployment.yaml
   ```

3. **Apply manifest**:

   ```bash
   ka -f deployment.yaml
   ```

4. **Verify deployment**:

   ```bash
   kg pods -w  # Watch pods
   kg deployments
   ```

5. **Check logs**:

   ```bash
   klogs <pod-pattern>
   ```

**AI Agent Notes**: Always validate YAML and use dry-run before applying. Git hooks will validate on commit.

---

### Workflow: Update Kubernetes Application

**Goal**: Update an existing Kubernetes application.

**Steps**:

1. **Get current configuration**:

   ```bash
   k get deployment <name> -o yaml > deployment-current.yaml
   ```

2. **Get current configuration**:

   ```bash
   k get deployment <name> -o yaml > deployment-current.yaml
   ```

3. **Make changes to manifest**

4. **Validate YAML**:

   ```bash
   yaml-lint deployment.yaml
   ```

5. **Dry-run apply**:

   ```bash
   k apply --dry-run=client -f deployment.yaml
   ```

6. **Apply changes**:

   ```bash
   ka -f deployment.yaml
   ```

7. **Monitor rollout**:

   ```bash
   k rollout status deployment/<name>
   ```

8. **View logs**:

   ```bash
   klogs <pod-pattern>
   ```

**AI Agent Notes**: Always validate YAML and use dry-run before applying.

---

## GitOps Workflows

### Workflow: Deploy via ArgoCD

**Goal**: Deploy application using GitOps with ArgoCD.

**Steps**:

1. **Update GitOps manifests**:

   ```bash
   # Edit files in gitops/ directory
   bat gitops/apps/workloads/<app>/app.yaml
   ```

2. **Validate YAML**:

   ```bash
   yaml-lint gitops/**/*.yaml
   ```

3. **Commit changes**:

   ```bash
   ga gitops/
   gc -m "feat: add new application"
   gp
   ```

4. **Check ArgoCD sync status**:

   ```bash
   argo app get <app-name>
   ```

5. **Sync if needed**:

   ```bash
   argo-sync <app-name>
   ```

6. **Monitor sync**:

   ```bash
   argo app get <app-name> -w
   ```

**AI Agent Notes**: ArgoCD will sync automatically. Use `argo app get` to check status. Manual sync may be needed for immediate deployment.

---

### Workflow: Update ArgoCD Application

**Goal**: Update an ArgoCD-managed application.

**Steps**:

1. **Get current application config**:

   ```bash
   argo app manifests <app-name> > app-current.yaml
   ```

2. **Update GitOps manifests**:

   ```bash
   # Edit files in gitops/ directory
   bat gitops/apps/workloads/<app>/app.yaml
   ```

3. **Validate YAML**:

   ```bash
   yaml-lint gitops/**/*.yaml
   ```

4. **Commit and push**:

   ```bash
   ga gitops/
   gc -m "feat: update application configuration"
   gp
   ```

5. **Wait for ArgoCD sync** (or sync manually):

   ```bash
   argo-sync <app-name>
   ```

6. **Verify deployment**:

   ```bash
   kctx-switch <cluster>
   kns-switch <namespace>
   kg pods
   klogs <pod-pattern>
   ```

**AI Agent Notes**: ArgoCD syncs automatically based on Git changes. Manual sync provides immediate deployment.

---

## Debugging Workflows

### Workflow: Debug Multi-Pod Deployment

**Goal**: Debug issues affecting multiple pods.

**Steps**:

1. **Switch to correct context and namespace**:

   ```bash
   kctx-switch <cluster>
   kns-switch <namespace>
   ```

2. **List pods**:

   ```bash
   kg pods
   ```

3. **View logs from all matching pods**:

   ```bash
   klogs <pod-pattern>  # e.g., "app-*"
   ```

4. **View resource tree**:

   ```bash
   ktree deployment <deployment-name>
   ```

5. **Describe resources**:

   ```bash
   kd deployment <deployment-name>
   kd service <service-name>
   ```

6. **Check events**:

   ```bash
   kg events --sort-by='.lastTimestamp'
   ```

**AI Agent Notes**: `stern` (aliased as `klogs`) is essential for multi-pod debugging. It tails logs from all matching pods simultaneously.

---

### Workflow: Investigate Resource Dependencies

**Goal**: Understand resource relationships and dependencies.

**Steps**:

1. **Get manifest**:

   ```bash
   k get deployment <name> -o yaml > deployment.yaml
   bat deployment.yaml
   ```

2. **Check related resources**:

   ```bash
   kg all
   kg all -l app=<app-label>
   ```

3. **Describe resources**:

   ```bash
   kd deployment <name>
   kd service <name>
   kd ingress <name>
   ```

4. **Check resource events**:

   ```bash
   kg events --sort-by='.lastTimestamp'
   ```

**AI Agent Notes**: Use `kubectl describe` and `kubectl get` to understand resource relationships and dependencies.

---

## Validation Workflows

### Workflow: Pre-Commit Validation

**Goal**: Validate all changes before committing.

**Steps**:

1. **Format Terraform**:

   ```bash
   tff
   ```

2. **Lint Terraform**:

   ```bash
   tflint
   ```

3. **Validate Terraform**:

   ```bash
   tfv
   ```

4. **Lint YAML**:

   ```bash
   yaml-lint .
   ```

5. **Lint shell scripts**:

   ```bash
   shell-check *.sh
   ```

6. **Security scan**:

   ```bash
   checkov --directory .
   ```

7. **Commit** (hooks will run automatically):

   ```bash
   ga .
   gc -m "feat: add new feature"
   ```

**AI Agent Notes**: Git hooks run automatically. This workflow is for manual validation before committing.

---

### Workflow: Comprehensive Security Scan

**Goal**: Perform thorough security scanning of all infrastructure code.

**Steps**:

1. **Terraform security scan**:

   ```bash
   checkov --directory . --framework terraform
   ```

2. **Kubernetes security scan**:

   ```bash
   checkov --directory . --framework kubernetes
   ```

3. **Helm security scan** (if using Helm):

   ```bash
   checkov --directory . --framework helm
   ```

4. **Combined scan**:

   ```bash
   checkov --directory . --framework terraform --framework kubernetes --framework helm
   ```

5. **Review findings**:

   ```bash
   # Checkov output shows issues with remediation steps
   ```

6. **Fix issues and re-scan**:

   ```bash
   # Fix issues in code
   checkov --directory . --framework terraform --framework kubernetes
   ```

**AI Agent Notes**: Run comprehensive scans before major deployments. Checkov provides remediation guidance for each issue.

---

## Integration Patterns

### Pattern: Terraform + Kubernetes + GitOps

**Complete workflow for deploying infrastructure and applications**:

1. **Deploy infrastructure with Terraform**:

   ```bash
   tfi && tfp && tfa
   ```

2. **Get kubeconfig**:

   ```bash
   # From Terraform output or cluster management tool
   ```

3. **Switch kubectl context**:

   ```bash
   kctx-switch <cluster>
   ```

4. **Deploy GitOps (ArgoCD)**:

   ```bash
   ka -f gitops/bootstrap/argocd-install.yaml
   ```

5. **Create ArgoCD applications**:

   ```bash
   ka -f gitops/bootstrap/app-of-apps.yaml
   ```

6. **Monitor GitOps sync**:

   ```bash
   argo app list
   argo app get <app-name>
   ```

**AI Agent Notes**: This pattern combines Terraform for infrastructure and ArgoCD for application deployment.

---

## Troubleshooting

### Common Issues

1. **Terraform validation fails**:
   - Check provider versions
   - Verify required variables are set
   - Check `.terraform/` directory exists

2. **Kubernetes apply fails**:
   - Verify kubeconfig and context
   - Check namespace exists
   - Validate YAML syntax

3. **ArgoCD sync fails**:
   - Check repository access
   - Verify application configuration
   - Check cluster connectivity

4. **Git hooks fail**:
   - Run hooks manually to see detailed output
   - Check tool availability
   - Review configuration files

### Getting Help

- Review tool-specific documentation in [TOOLS.md](TOOLS.md)
- Check [lefthook.md](lefthook.md) for git hooks issues
- See [ALIASES.md](ALIASES.md) for command shortcuts
- Review [agents.md](../agents.md) for quick reference

---

## Related Documentation

- [TOOLS.md](TOOLS.md) - Tool documentation
- [ALIASES.md](ALIASES.md) - Aliases reference
- [lefthook.md](lefthook.md) - Git hooks documentation
- [agents.md](../agents.md) - AI agent quick reference
