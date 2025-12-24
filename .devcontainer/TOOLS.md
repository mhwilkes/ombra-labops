# DevContainer Tools Documentation

This document provides comprehensive documentation for all tools installed in the devcontainer. Each tool includes installation details, usage examples, and configuration options.

## Table of Contents

- [Terraform Tools](#terraform-tools)
  - [Terraform](#terraform)
  - [Terragrunt](#terragrunt)
  - [checkov](#checkov)
  - [tflint](#tflint)
- [Kubernetes Tools](#kubernetes-tools)
  - [kubectl](#kubectl)
  - [helm](#helm)
  - [kubectx / kubens](#kubectx--kubens)
  - [stern](#stern)
  - [k9s](#k9s)
- [GitOps Tools](#gitops-tools)
  - [ArgoCD CLI](#argocd-cli)
  - [Infisical CLI](#infisical-cli)
  - [Kustomize](#kustomize)
- [Cluster Management](#cluster-management)
  - [clusterctl](#clusterctl)
  - [talosctl](#talosctl)
- [Validation & Linting](#validation--linting)
  - [yamllint](#yamllint)
  - [shellcheck](#shellcheck)
- [Developer Tools](#developer-tools)
  - [fzf](#fzf)
  - [ripgrep](#ripgrep)
  - [bat](#bat)
  - [fd](#fd)
- [Configuration Management](#configuration-management)
  - [Ansible](#ansible)

---

## Terraform Tools

### Terraform

**Purpose**: Infrastructure as Code tool for provisioning and managing cloud infrastructure.

**Installation**: Installed via devcontainer feature.

**Usage Examples**:

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

**Aliases**: `tf`, `tfa`, `tfd`, `tfi`, `tfp`, `tfv`, `tff`, `tffc`

**Configuration**: Terraform files use `.tf` extension. See [ALIASES.md](ALIASES.md) for alias details.

**AI Agent Notes**: Use `tf` alias for brevity. Always run `terraform validate` before applying changes.

---

### Terragrunt

**Purpose**: Thin wrapper for Terraform that provides DRY configuration and remote state management.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Initialize Terragrunt
terragrunt init

# Plan changes
terragrunt plan

# Apply changes
terragrunt apply

# Validate
terragrunt validate
```

**Aliases**: `tg`, `tga`, `tgp`, `tgi`, `tgv`

**AI Agent Notes**: Use `tg` alias. Terragrunt wraps Terraform commands, so most Terraform flags work.

---

### checkov

**Purpose**: Static code analysis tool for infrastructure as code security scanning. Supports Terraform, Kubernetes, Helm, and more.

**Installation**: Installed via pip3 in `post-create.sh`.

**Usage Examples**:

```bash
# Scan current directory
checkov --directory .

# Scan specific framework
checkov --directory . --framework terraform
checkov --directory . --framework kubernetes

# Scan multiple frameworks
checkov --directory . --framework terraform --framework kubernetes

# Quiet mode
checkov --directory . --quiet

# Output to file
checkov --directory . --output json > checkov-results.json
```

**Configuration**: See [.checkov.yaml](../.checkov.yaml) for configuration options.

**AI Agent Notes**: Run checkov before committing Terraform or Kubernetes changes. It catches security misconfigurations automatically.

---

### tflint

**Purpose**: Terraform linter that finds errors and best practices violations.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Lint current directory
tflint

# Lint specific file
tflint main.tf

# Initialize plugins
tflint --init

# Format output as JSON
tflint --format json
```

**Configuration**: See [.tflint.hcl](../.tflint.hcl) for linting rules and plugin configuration.

**AI Agent Notes**: Run tflint after `terraform fmt` to catch issues before validation. Configuration is in `.tflint.hcl`.

---

## Kubernetes Tools

### kubectl

**Purpose**: Command-line tool for interacting with Kubernetes clusters.

**Installation**: Installed via devcontainer feature.

**Usage Examples**:

```bash
# Get resources
kubectl get pods
kubectl get deployments
kubectl get services

# Describe resource
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # Follow logs

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/bash

# Apply manifest
kubectl apply -f manifest.yaml

# Delete resource
kubectl delete pod <pod-name>
```

**Aliases**: `k`, `kg`, `kd`, `ka`, `kdel`, `kl`, `ke`, `kctx`, `kns`

**AI Agent Notes**: Use `k` alias for brevity. Most common operations have aliases (see [ALIASES.md](ALIASES.md)).

---

### helm

**Purpose**: Kubernetes package manager for managing Helm charts.

**Installation**: Installed via devcontainer feature.

**Usage Examples**:

```bash
# Install chart
helm install <release-name> <chart>

# List releases
helm list

# Upgrade release
helm upgrade <release-name> <chart>

# Uninstall release
helm uninstall <release-name>

# Search charts
helm search repo <keyword>
```

**Aliases**: `h`, `hi`, `hu`, `hls`, `hup`

**AI Agent Notes**: Use `h` alias. Helm is used extensively in GitOps configurations.

---

### kubectx / kubens

**Purpose**: Fast context and namespace switching for kubectl.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# List contexts
kubectx

# Switch context
kubectx <context-name>

# List namespaces
kubens

# Switch namespace
kubens <namespace>
```

**Aliases**: `kctx-switch` (kubectx), `kns-switch` (kubens)

**AI Agent Notes**: Essential for multi-cluster environments. Use `kubectx` to switch between clusters quickly.

---

### stern

**Purpose**: Multi-pod log tailing for Kubernetes. Follows logs from multiple pods matching a pattern.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Tail logs from pods matching pattern
stern <pod-pattern>

# Tail logs in specific namespace
stern <pod-pattern> -n <namespace>

# Tail logs with timestamps
stern <pod-pattern> --timestamps

# Tail logs from multiple namespaces
stern <pod-pattern> --all-namespaces
```

**Aliases**: `klogs`

**AI Agent Notes**: Much better than `kubectl logs` for debugging multi-pod deployments. Use patterns like `app-*` to match multiple pods.

---

### k9s

**Purpose**: Terminal UI for Kubernetes cluster management.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Launch k9s
k9s

# Launch with specific namespace
k9s -n <namespace>

# Launch with specific context
k9s --context <context-name>
```

**AI Agent Notes**: Interactive tool, not suitable for automation. Use for manual cluster inspection.

---

## GitOps Tools

### ArgoCD CLI

**Purpose**: Command-line interface for ArgoCD GitOps operations.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Login to ArgoCD
argocd login <argocd-server>

# List applications
argocd app list

# Get application status
argocd app get <app-name>

# Sync application
argocd app sync <app-name>

# Get application manifests
argocd app manifests <app-name>

# Delete application
argocd app delete <app-name>
```

**Aliases**: `argo`, `argo-app`, `argo-sync`, `argo-status`

**AI Agent Notes**: Essential for GitOps workflows. Use `argo app get` to check sync status before making changes.

---

### Infisical CLI

**Purpose**: Command-line interface for Infisical secrets management.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Login to Infisical
infisical login

# Get secret
infisical secrets get <secret-name>

# Set secret
infisical secrets set <secret-name>=<value>

# List secrets
infisical secrets list
```

**AI Agent Notes**: Used for managing secrets in the homelab. Integrates with Kubernetes via Infisical operator.

---

### Kustomize

**Purpose**: Template-free customization of Kubernetes YAML configurations.

**Installation**: Bundled with kubectl (available via `kubectl kustomize`).

**Usage Examples**:

```bash
# Build kustomization
kubectl kustomize <directory>

# Apply kustomization
kubectl apply -k <directory>

# Build and view
kubectl kustomize <directory> | kubectl-neat
```

**AI Agent Notes**: Used extensively in GitOps configurations. Access via `kubectl kustomize` command.

---

## Cluster Management

### clusterctl

**Purpose**: Cluster API command-line tool for managing Kubernetes clusters declaratively.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Initialize cluster API
clusterctl init

# Generate cluster manifest
clusterctl generate cluster <cluster-name> > cluster.yaml

# Get cluster kubeconfig
clusterctl get kubeconfig <cluster-name> > kubeconfig
```

**AI Agent Notes**: Used for managing the homelab Kubernetes cluster via Cluster API. See [cluster-infrastructure/README.md](../cluster-infrastructure/README.md).

---

### talosctl

**Purpose**: Command-line tool for managing Talos Linux Kubernetes nodes.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Generate Talos configuration
talosctl gen config <cluster-name> <cluster-endpoint>

# Apply configuration
talosctl apply-config --insecure --nodes <node-ip> --file <config.yaml>

# Get kubeconfig
talosctl kubeconfig <node-ip>
```

**AI Agent Notes**: Used for managing Talos Linux nodes in the homelab cluster. See cluster-infrastructure documentation.

---

## Validation & Linting

### yamllint

**Purpose**: YAML linter that checks syntax and style.

**Installation**: Installed via pip3 in `post-create.sh`.

**Usage Examples**:

```bash
# Lint file
yamllint <file.yaml>

# Lint directory
yamllint <directory>

# Lint with custom config
yamllint -c .yamllint <file.yaml>

# Show all problems
yamllint -d relaxed <file.yaml>
```

**Configuration**: See [.yamllint](../.yamllint) for rules and configuration.

**AI Agent Notes**: Run yamllint on all YAML files before committing. Configuration is in `.yamllint` at repository root.

---

### shellcheck

**Purpose**: Static analysis tool for shell scripts.

**Installation**: Installed via apt-get in `post-create.sh`.

**Usage Examples**:

```bash
# Check script
shellcheck <script.sh>

# Check with external sources
shellcheck --external-sources <script.sh>

# Show all issues
shellcheck -e SC2034 <script.sh>  # Exclude specific codes
```

**AI Agent Notes**: Run shellcheck on all shell scripts. VS Code extension provides inline feedback.

---

## Developer Tools

### fzf

**Purpose**: Fuzzy finder for command-line history and file search.

**Installation**: Installed from GitHub in `post-create.sh`.

**Usage Examples**:

```bash
# Search command history (Ctrl+R)
# Built into shell

# Find files
fzf

# Find files and open
vim $(fzf)

# Search in files
rg <pattern> | fzf
```

**AI Agent Notes**: Interactive tool. Provides fuzzy search for history and files. Keybindings configured in `.bashrc`.

---

### ripgrep

**Purpose**: Fast grep alternative for searching text in files.

**Installation**: Installed via apt-get in `post-create.sh`.

**Usage Examples**:

```bash
# Search for pattern
rg <pattern>

# Search in specific file types
rg <pattern> -t yaml

# Search with context
rg <pattern> -C 3

# Case insensitive
rg -i <pattern>
```

**Aliases**: `grep` (aliased to `rg`)

**AI Agent Notes**: Much faster than grep. Use `rg` for all text search operations.

---

### bat

**Purpose**: Better cat with syntax highlighting and Git integration.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# View file with syntax highlighting
bat <file>

# Show line numbers
bat -n <file>

# Show non-printable characters
bat -A <file>
```

**Aliases**: `cat` (aliased to `bat`)

**AI Agent Notes**: Use `bat` instead of `cat` for better file viewing. Syntax highlighting helps with code review.

---

### fd

**Purpose**: Fast find alternative with better defaults.

**Installation**: Installed from GitHub releases in `post-create.sh`.

**Usage Examples**:

```bash
# Find files
fd <pattern>

# Find files by extension
fd -e yaml

# Find in specific directory
fd <pattern> <directory>

# Case insensitive
fd -i <pattern>
```

**Aliases**: `find` (aliased to `fd`)

**AI Agent Notes**: Faster and more intuitive than find. Use `fd` for all file search operations.

---

## Configuration Management

### Ansible

**Purpose**: Configuration management and automation tool.

**Installation**: Installed via pip3 in `post-create.sh`.

**Usage Examples**:

```bash
# Run playbook
ansible-playbook <playbook.yml>

# Run with inventory
ansible-playbook -i <inventory> <playbook.yml>

# Check syntax
ansible-playbook --syntax-check <playbook.yml>

# Dry run
ansible-playbook --check <playbook.yml>
```

**AI Agent Notes**: Used for configuration management. See Ansible documentation for playbook syntax.

---

## Tool Integration

### Common Workflows

See [WORKFLOWS.md](WORKFLOWS.md) for detailed workflow examples combining multiple tools.

### Quick Checks

Before committing changes, run:

```bash
# Format Terraform
terraform fmt -recursive

# Lint Terraform
tflint

# Lint YAML
yamllint .

# Security scan
checkov --directory .
```

### Git Hooks

All validation runs automatically via lefthook. See [lefthook.md](lefthook.md) for details.

---

## Additional Resources

- [ALIASES.md](ALIASES.md) - Complete aliases reference
- [WORKFLOWS.md](WORKFLOWS.md) - Common workflows
- [lefthook.md](lefthook.md) - Git hooks documentation
- [agents.md](../agents.md) - AI agent quick reference

