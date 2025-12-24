# DevContainer Setup for Ombra LabOps

This directory contains the development container configuration for the Ombra LabOps repository. The devcontainer provides a consistent, reproducible development environment with all necessary tools pre-installed.

## Compatibility

This devcontainer works with both:

- **Visual Studio Code** (with the Dev Containers extension)
- **Cursor** (built-in devcontainer support)

## Prerequisites

- Docker Desktop or Docker Engine installed and running
- VS Code with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) OR Cursor (built-in support)
- Git

## Getting Started

### Using VS Code

1. Open the repository in VS Code
2. Press `F1` or `Cmd+Shift+P` (Mac) / `Ctrl+Shift+P` (Windows/Linux)
3. Type "Dev Containers: Reopen in Container"
4. Select the option and wait for the container to build

### Using Cursor

1. Open the repository in Cursor
2. Cursor will detect the `.devcontainer` directory and prompt you to reopen in container
3. Click "Reopen in Container" when prompted
4. Wait for the container to build

## What's Included

### Infrastructure as Code Tools

- **Terraform** - Infrastructure as Code tool
- **Terragrunt** - Thin wrapper for Terraform
- **checkov** - Infrastructure security scanner
- **tflint** - Terraform linter
- **Ansible** - Configuration management and automation

### Kubernetes Tools

- **kubectl** - Kubernetes command-line tool
- **Helm** - Kubernetes package manager
- **kubectx/kubens** - Fast context/namespace switching
- **stern** - Multi-pod log tailing
- **kubectl-neat** - Clean Kubernetes manifests
- **kubectl-tree** - Visualize resource hierarchies
- **k9s** - Terminal UI for Kubernetes

### GitOps Tools

- **ArgoCD CLI** - GitOps command-line tool
- **Infisical CLI** - Secrets management
- **Kustomize** - Kubernetes configuration customization

### Cluster Management

- **clusterctl** - Cluster API command-line tool
- **talosctl** - Talos Linux management tool

### Validation & Linting

- **yamllint** - YAML linter
- **shellcheck** - Shell script static analysis tool

### Developer Tools

- **fzf** - Fuzzy finder for command history and files
- **ripgrep (rg)** - Fast grep alternative
- **bat** - Better cat with syntax highlighting
- **fd** - Fast find alternative
- **Git** - Version control
- **jq** - JSON processor
- **curl** - HTTP client
- **bash-completion** - Bash tab completion

### Git Hooks

- **lefthook** - Fast git hooks manager (runs validation automatically)

### Pre-configured Settings

- Shell completions for kubectl, helm, and terraform
- Comprehensive aliases (see [ALIASES.md](ALIASES.md))
- YAML/Kubernetes syntax validation
- Terraform formatting and linting
- Security scanning with checkov
- Git hooks via lefthook (automatic validation)
- EditorConfig support

## Documentation

### Comprehensive Guides

- **[TOOLS.md](TOOLS.md)** - Complete documentation for all installed tools
- **[ALIASES.md](ALIASES.md)** - Comprehensive aliases reference with usage examples
- **[WORKFLOWS.md](WORKFLOWS.md)** - Common IaC workflows and step-by-step guides
- **[lefthook.md](lefthook.md)** - Git hooks documentation and configuration

### Quick Reference

- **[agents.md](../agents.md)** - AI agent quick reference and tool matrix

### Quick Aliases Reference

See [ALIASES.md](ALIASES.md) for complete documentation. Common aliases:

**Kubernetes**: `k`, `kg`, `kd`, `ka`, `kl`, `klogs` (stern), `kneat`, `ktree`
**Terraform**: `tf`, `tfa`, `tfp`, `tfv`, `tff`, `tflint`, `checkov`
**GitOps**: `argo`, `argo-sync`, `argo-status`
**Git**: `gs`, `ga`, `gc`, `gp`, `gl`, `gd`
**Dev Tools**: `cat` (bat), `find` (fd), `grep` (rg)

## VS Code / Cursor Extensions

The following extensions are automatically installed in the devcontainer:

- **YAML** (Red Hat) - YAML language support with Kubernetes schema validation
- **Kubernetes** (Microsoft) - Kubernetes tools
- **Docker** (Microsoft) - Docker support
- **Terraform** (HashiCorp) - Terraform language support
- **Checkov** (Bridgecrew) - Security scanning
- **Ansible** (Red Hat) - Ansible support
- **Error Lens** - Inline error highlighting
- **Better Comments** - Enhanced comment highlighting
- **Todo Tree** - Task and TODO highlighting
- **GitLens** - Enhanced Git capabilities
- **EditorConfig** - EditorConfig support
- **ShellCheck** - Bash/Shell linting
- **Prettify JSON** - JSON formatting

## File Associations

The devcontainer automatically associates file types:

- `*.yaml`, `*.yml` → YAML
- `talosconfig*` → YAML
- `clusterctl-config*.yaml` → YAML
- `renovate.json` → JSONC (JSON with Comments)
- `*.tf` → Terraform
- `*.tfvars` → Terraform Variables
- `*.hcl` → Terraform

## Mounted Directories

The following directories from your host are mounted into the container:

- `~/.kube` → Container's `~/.kube` (for kubectl config)
- `~/.cluster-api` → Container's `~/.cluster-api` (for clusterctl config)

## Post-Create Setup

When the container is first created, the `post-create.sh` script automatically:

1. Installs additional tools not available as devcontainer features
2. Sets up lefthook git hooks (if `.lefthook.yml` exists)
3. Verifies all tool installations
4. Sets up shell completions
5. Configures comprehensive aliases (see [ALIASES.md](ALIASES.md))
6. Displays a summary of installed tools and versions

## Git Hooks

Lefthook automatically runs validation on commit and push:

- **Pre-commit**: Terraform formatting, linting, YAML validation, shellcheck
- **Pre-push**: Terraform validation, security scanning with checkov

See [lefthook.md](lefthook.md) for detailed documentation.

## Troubleshooting

### Container won't start

- Ensure Docker is running
- Check Docker logs: `docker logs <container-id>`
- Try rebuilding: In VS Code/Cursor, run "Dev Containers: Rebuild Container"

### Tools not found

- The post-create script runs automatically on first build
- If tools are missing, check the terminal output for errors
- Manually run: `bash .devcontainer/post-create.sh`

### kubectl context issues

- Ensure your `~/.kube/config` file exists on the host
- The container mounts this automatically
- Verify with: `kubectl config get-contexts`

### ShellCheck not working

- Verify installation: `shellcheck --version`
- Check VS Code/Cursor settings for ShellCheck extension
- Ensure `.shellcheckrc` exists in the repository root

## Customization

To customize the devcontainer:

1. Edit `.devcontainer/devcontainer.json` for configuration changes
2. Edit `.devcontainer/post-create.sh` to add additional setup steps
3. Rebuild the container to apply changes

## Best Practices

1. **Always work in the devcontainer** - This ensures consistency across all developers
2. **Commit `.devcontainer/` directory** - This allows others to use the same environment
3. **Use the provided aliases** - See [ALIASES.md](ALIASES.md) for complete reference
4. **Let format-on-save work** - It keeps code consistently formatted
5. **Git hooks run automatically** - Validation happens on commit/push via lefthook
6. **Review workflows** - See [WORKFLOWS.md](WORKFLOWS.md) for common task patterns
7. **Security scanning** - checkov runs automatically on push to catch security issues

## Resources

- [Dev Containers Specification](https://containers.dev/)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Cursor Documentation](https://cursor.sh/docs)

## Support

For issues or questions:

1. Check this README
2. Review the post-create script output
3. Check VS Code/Cursor Dev Container logs
4. Open an issue in the repository
