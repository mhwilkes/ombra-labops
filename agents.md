# AI Agent Documentation Index

This document serves as the primary entry point for AI agents working with this repository. It provides an overview of available tools, quick references, and links to detailed documentation.

## Quick Reference

### Tool Availability Matrix

| Tool | Purpose | Command | Documentation |
|------|---------|---------|---------------|
| **Terraform** | IaC tool | `terraform`, `tf` | [TOOLS.md](.devcontainer/TOOLS.md#terraform) |
| **Terragrunt** | Terraform wrapper | `terragrunt`, `tg` | [TOOLS.md](.devcontainer/TOOLS.md#terragrunt) |
| **checkov** | Security scanner | `checkov` | [TOOLS.md](.devcontainer/TOOLS.md#checkov) |
| **tflint** | Terraform linter | `tflint` | [TOOLS.md](.devcontainer/TOOLS.md#tflint) |
| **kubectl** | Kubernetes CLI | `kubectl`, `k` | [TOOLS.md](.devcontainer/TOOLS.md#kubectl) |
| **helm** | Kubernetes package manager | `helm`, `h` | [TOOLS.md](.devcontainer/TOOLS.md#helm) |
| **kubectx/kubens** | Context/namespace switching | `kubectx`, `kubens` | [TOOLS.md](.devcontainer/TOOLS.md#kubectx--kubens) |
| **stern** | Multi-pod log tailing | `stern`, `klogs` | [TOOLS.md](.devcontainer/TOOLS.md#stern) |
| **argocd** | GitOps CLI | `argocd`, `argo` | [TOOLS.md](.devcontainer/TOOLS.md#argocd-cli) |
| **infisical** | Secrets management | `infisical` | [TOOLS.md](.devcontainer/TOOLS.md#infisical-cli) |
| **yamllint** | YAML linter | `yamllint` | [TOOLS.md](.devcontainer/TOOLS.md#yamllint) |
| **shellcheck** | Shell linter | `shellcheck` | [TOOLS.md](.devcontainer/TOOLS.md#shellcheck) |
| **fzf** | Fuzzy finder | `fzf` | [TOOLS.md](.devcontainer/TOOLS.md#fzf) |
| **ripgrep** | Fast grep | `rg`, `grep` | [TOOLS.md](.devcontainer/TOOLS.md#ripgrep) |
| **bat** | Better cat | `bat`, `cat` | [TOOLS.md](.devcontainer/TOOLS.md#bat) |
| **fd** | Fast find | `fd`, `find` | [TOOLS.md](.devcontainer/TOOLS.md#fd) |
| **lefthook** | Git hooks | `lefthook`, `hooks` | [lefthook.md](.devcontainer/lefthook.md) |

## Documentation Structure

### Main Documentation Files

1. **[.devcontainer/TOOLS.md](.devcontainer/TOOLS.md)** - Comprehensive documentation for all installed tools
   - Installation details
   - Usage examples
   - Configuration options
   - Integration patterns

2. **[.devcontainer/ALIASES.md](.devcontainer/ALIASES.md)** - Complete aliases reference
   - All available aliases organized by category
   - Usage examples
   - When to use each alias

3. **[.devcontainer/WORKFLOWS.md](.devcontainer/WORKFLOWS.md)** - Common IaC workflows
   - Terraform workflows
   - Kubernetes debugging
   - GitOps deployment
   - Troubleshooting guides

4. **[.devcontainer/lefthook.md](.devcontainer/lefthook.md)** - Git hooks documentation
   - Hook configuration
   - Manual execution
   - Troubleshooting

### Configuration Files

- **[.yamllint](.yamllint)** - YAML linting rules
- **[.tflint.hcl](.tflint.hcl)** - Terraform linting configuration
- **[.checkov.yaml](.checkov.yaml)** - Security scanning configuration
- **[.lefthook.yml](.lefthook.yml)** - Git hooks configuration

## Common Task Patterns

### Terraform Operations

```bash
# Initialize Terraform
tf init

# Validate Terraform code
tf validate
tflint

# Security scan
checkov --directory . --framework terraform

# Plan changes
tf plan

# Apply changes
tf apply
```

### Kubernetes Operations

```bash
# Switch context
kubectx <context-name>

# Switch namespace
kubens <namespace>

# Get resources
k get pods -A
k get deployments

# View logs (multi-pod)
stern <pod-pattern>
```

### GitOps Operations

```bash
# List ArgoCD applications
argo app list

# Get application status
argo app get <app-name>

# Sync application
argo app sync <app-name>

# Get Infisical secrets
infisical secrets get <secret-name>
```

### Validation and Linting

```bash
# Lint YAML files
yamllint <file.yaml>

# Lint Terraform
tflint

# Lint shell scripts
shellcheck <script.sh>

# Security scan
checkov --directory .
```

## Tool Integration Examples

### Workflow: Terraform + Security Scan

```bash
# 1. Format Terraform
terraform fmt -recursive

# 2. Lint Terraform
tflint

# 3. Validate Terraform
terraform validate

# 4. Security scan
checkov --directory . --framework terraform
```

### Workflow: Kubernetes Debugging

```bash
# 1. Switch to correct context
kubectx <cluster-name>

# 2. Switch to namespace
kubens <namespace>

# 3. Tail logs from multiple pods
stern <pod-pattern>

# 4. Get resource details
kubectl get <resource> -o yaml
```

### Workflow: GitOps Deployment

```bash
# 1. Update GitOps manifests
# Edit files in gitops/ directory

# 2. Validate YAML
yamllint gitops/**/*.yaml

# 3. Check ArgoCD sync status
argo app get <app-name>

# 4. Sync if needed
argo app sync <app-name>
```

## Error Handling Patterns

### Check Tool Availability

```bash
# Check if tool is installed
command -v <tool-name> >/dev/null 2>&1 && echo "Installed" || echo "Not installed"

# Examples
command -v terraform && terraform --version
command -v kubectl && kubectl version --client
command -v argocd && argocd version --client
```

### Handle Tool Errors

- **Terraform errors**: Check `.terraform/` directory, provider versions
- **Kubernetes errors**: Verify kubeconfig, context, namespace
- **ArgoCD errors**: Check application sync status, repository access
- **Linting errors**: Review configuration files (`.yamllint`, `.tflint.hcl`)

## Best Practices for AI Agents

1. **Always check tool availability** before using commands
2. **Use aliases** when available (see [ALIASES.md](.devcontainer/ALIASES.md))
3. **Run validation** before making changes (linting, security scans)
4. **Check git hooks** - lefthook will run automatically on commit
5. **Reference documentation** for tool-specific options and flags
6. **Use appropriate tools** for the task (see tool matrix above)

## Quick Links

- [DevContainer README](.devcontainer/README.md) - Getting started guide
- [Repository README](README.md) - Project overview
- [Cluster Infrastructure](cluster-infrastructure/README.md) - Cluster setup
- [GitOps Configuration](gitops/README.md) - ArgoCD setup

## Notes for AI Agents

- All tools are installed in the devcontainer via `.devcontainer/post-create.sh`
- Aliases are configured in `.bashrc` and documented in [ALIASES.md](.devcontainer/ALIASES.md)
- Git hooks run automatically via lefthook (see [lefthook.md](.devcontainer/lefthook.md))
- Configuration files are at the repository root (`.yamllint`, `.tflint.hcl`, etc.)
- When suggesting commands, prefer aliases for brevity and consistency

