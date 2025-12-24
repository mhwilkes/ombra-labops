# Aliases Reference

This document provides a comprehensive reference for all aliases configured in the devcontainer. Aliases are organized by category for easy reference.

## Table of Contents

- [Kubernetes Aliases](#kubernetes-aliases)
- [Terraform Aliases](#terraform-aliases)
- [GitOps Aliases](#gitops-aliases)
- [Git Aliases](#git-aliases)
- [Developer Tools Aliases](#developer-tools-aliases)
- [Validation Aliases](#validation-aliases)
- [Git Hooks Aliases](#git-hooks-aliases)

---

## Kubernetes Aliases

### Basic kubectl Shortcuts

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `k` | `kubectl` | Main kubectl command |
| `kg` | `kubectl get` | Get resources |
| `kd` | `kubectl describe` | Describe resource details |
| `ka` | `kubectl apply` | Apply manifest |
| `kdel` | `kubectl delete` | Delete resource |
| `kl` | `kubectl logs` | View logs |
| `ke` | `kubectl exec -it` | Execute command in pod |
| `kctx` | `kubectl config get-contexts` | List contexts |
| `kns` | `kubectl config set-context --current --namespace` | Set namespace |

**Usage Examples**:

```bash
# Get all pods
kg pods

# Get pods in namespace
kg pods -n <namespace>

# Describe pod
kd pod <pod-name>

# Apply manifest
ka -f manifest.yaml

# View logs
kl <pod-name>

# Follow logs
kl -f <pod-name>

# Execute in pod
ke <pod-name> -- /bin/bash

# List contexts
kctx

# Switch namespace
kns <namespace>
```

### Advanced Kubernetes Tools

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `kctx-switch` | `kubectx` | Switch Kubernetes context |
| `kns-switch` | `kubens` | Switch Kubernetes namespace |
| `klogs` | `stern` | Multi-pod log tailing |

**Usage Examples**:

```bash
# Switch context
kctx-switch <context-name>

# Switch namespace
kns-switch <namespace>

# Tail logs from multiple pods
klogs <pod-pattern>
```

---

## Helm Aliases

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `h` | `helm` | Main helm command |
| `hi` | `helm install` | Install chart |
| `hu` | `helm uninstall` | Uninstall release |
| `hls` | `helm list` | List releases |
| `hup` | `helm upgrade` | Upgrade release |

**Usage Examples**:

```bash
# Install chart
hi <release-name> <chart>

# List releases
hls

# Upgrade release
hup <release-name> <chart>

# Uninstall release
hu <release-name>
```

---

## Terraform Aliases

### Basic Terraform Commands

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `tf` | `terraform` | Main terraform command |
| `tfa` | `terraform apply` | Apply changes |
| `tfd` | `terraform destroy` | Destroy infrastructure |
| `tfi` | `terraform init` | Initialize Terraform |
| `tfp` | `terraform plan` | Plan changes |
| `tfv` | `terraform validate` | Validate configuration |
| `tff` | `terraform fmt` | Format Terraform files |
| `tffc` | `terraform fmt -check` | Check formatting |

**Usage Examples**:

```bash
# Initialize
tfi

# Validate
tfv

# Format
tff

# Check formatting
tffc

# Plan
tfp

# Apply
tfa

# Destroy
tfd
```

### Terraform Security and Linting

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `tflint` | `tflint` | Terraform linter |
| `checkov` | `checkov` | Security scanner |

**Usage Examples**:

```bash
# Lint Terraform
tflint

# Security scan
checkov --directory .
```

---

## Terragrunt Aliases

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `tg` | `terragrunt` | Main terragrunt command |
| `tga` | `terragrunt apply` | Apply changes |
| `tgp` | `terragrunt plan` | Plan changes |
| `tgi` | `terragrunt init` | Initialize Terragrunt |
| `tgv` | `terragrunt validate` | Validate configuration |

**Usage Examples**:

```bash
# Initialize
tgi

# Validate
tgv

# Plan
tgp

# Apply
tga
```

---

## GitOps Aliases

### ArgoCD

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `argo` | `argocd` | Main ArgoCD CLI |
| `argo-app` | `argocd app` | ArgoCD app commands |
| `argo-sync` | `argocd app sync` | Sync application |
| `argo-status` | `argocd app get` | Get app status |

**Usage Examples**:

```bash
# List applications
argo app list

# Get application status
argo-status <app-name>

# Sync application
argo-sync <app-name>
```

### Infisical

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `infisical` | `infisical` | Infisical CLI |

**Usage Examples**:

```bash
# Get secret
infisical secrets get <secret-name>

# List secrets
infisical secrets list
```

---

## Git Aliases

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `gs` | `git status` | Show status |
| `ga` | `git add` | Stage files |
| `gc` | `git commit` | Commit changes |
| `gp` | `git push` | Push to remote |
| `gl` | `git pull` | Pull from remote |
| `gd` | `git diff` | Show differences |
| `gb` | `git branch` | List branches |
| `gco` | `git checkout` | Checkout branch |
| `gcm` | `git checkout main \|\| git checkout master` | Checkout main/master |
| `gcb` | `git checkout -b` | Create and checkout branch |

**Usage Examples**:

```bash
# Check status
gs

# Stage files
ga <file>

# Commit
gc -m "message"

# Push
gp

# Pull
gl

# Checkout branch
gco <branch>

# Checkout main
gcm

# Create branch
gcb <branch-name>
```

---

## Developer Tools Aliases

### File Operations

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `cat` | `bat` | Use bat instead of cat |
| `find` | `fd` | Use fd instead of find |
| `grep` | `rg` | Use ripgrep instead of grep |

**Usage Examples**:

```bash
# View file with syntax highlighting
cat <file>

# Find files
find <pattern>

# Search text
grep <pattern>
```

### Navigation

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `ll` | `ls -alF` | Long listing |
| `la` | `ls -A` | List all (including hidden) |
| `l` | `ls -CF` | Compact listing |
| `..` | `cd ..` | Go up one directory |
| `...` | `cd ../..` | Go up two directories |
| `....` | `cd ../../..` | Go up three directories |

**Usage Examples**:

```bash
# Long listing
ll

# List all
la

# Navigate up
..
...
....
```

---

## Validation Aliases

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `yaml-lint` | `yamllint` | YAML linter |
| `shell-check` | `shellcheck` | Shell script linter |

**Usage Examples**:

```bash
# Lint YAML
yaml-lint <file.yaml>

# Lint shell script
shell-check <script.sh>
```

---

## Git Hooks Aliases

| Alias | Full Command | Description |
|-------|--------------|-------------|
| `hooks` | `lefthook` | Run lefthook manually |
| `hooks-run` | `lefthook run` | Run all hooks |

**Usage Examples**:

```bash
# Run all hooks
hooks-run

# Run specific hook
hooks run pre-commit
```

---

## When to Use Aliases vs. Full Commands

### Use Aliases When


- Working interactively in the terminal
- Writing documentation or examples
- Performing common, repetitive tasks
- Quick operations that don't need full command visibility


### Use Full Commands When

- Writing scripts (aliases may not be available)
- Need to see exact command for debugging
- Sharing commands with others who may not have aliases
- Complex commands with many flags

---

## AI Agent Guidelines

When suggesting commands to users or in code:

1. **Prefer aliases** for brevity and consistency
2. **Document aliases** when introducing new ones
3. **Show both** alias and full command in documentation
4. **Check availability** - aliases are configured in `.bashrc` and loaded in interactive shells

---

## Adding New Aliases

To add new aliases:

1. Edit `.devcontainer/post-create.sh`
2. Add alias to the appropriate section in the aliases block
3. Update this document (ALIASES.md)
4. Rebuild the devcontainer

Example:

```bash
# Add to post-create.sh
alias newalias='full command'

# Update ALIASES.md with documentation
```

---

## Related Documentation

- [TOOLS.md](TOOLS.md) - Tool documentation
- [WORKFLOWS.md](WORKFLOWS.md) - Workflow examples using aliases
