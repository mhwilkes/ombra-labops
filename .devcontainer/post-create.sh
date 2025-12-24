#!/usr/bin/env bash
# Post-create script for project-specific configurations
# Most tools are installed via devcontainer features
# shellcheck disable=SC2310  # command_exists is intentionally used in if conditions
set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install tools via Homebrew (Homebrew installed via feature)
if command_exists brew; then
    log_info "Installing tools via Homebrew..."
    brew install clusterctl k9s terragrunt tflint stern infisical || log_warning "Some Homebrew packages may have failed to install"
    log_success "Homebrew package installation complete"
else
    log_warning "Homebrew not found, skipping package installation"
fi

# Initialize lefthook if .lefthook.yml exists (lefthook installed via feature)
if [[ -f ".lefthook.yml" ]] || [[ -f "${PWD}/.lefthook.yml" ]]; then
    if command_exists lefthook; then
        log_info "Initializing lefthook git hooks..."
        lefthook install > /dev/null 2>&1 || true
        log_success "lefthook hooks installed"
    fi
fi

# Setup aliases (project-specific configuration)
add_aliases() {
    local shell_config=$1
    if [[ -f "${shell_config}" ]] && ! grep -q "# Ombra LabOps Aliases" "${shell_config}" 2>/dev/null; then
        cat >> "${shell_config}" << 'EOF'

# Ombra LabOps Aliases
export PATH="${HOME}/.local/bin:${PATH}"

# Kubernetes aliases
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias ka='kubectl apply'
alias kdel='kubectl delete'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kctx='kubectl config get-contexts'
alias kns='kubectl config set-context --current --namespace'
alias klogs='stern'  # Multi-pod log tailing

# GitOps aliases
alias argo='argocd'
alias argo-sync='argocd app sync'
alias argo-status='argocd app get'

# Terraform aliases
alias tf='terraform'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'
alias tflint='tflint'

# Terragrunt aliases
alias tg='terragrunt'
alias tga='terragrunt apply'
alias tgp='terragrunt plan'

# Security scanning
alias checkov='checkov'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Dev tools aliases (using bat, fd, rg if available)
if command -v bat >/dev/null 2>&1; then
    alias cat='bat --paging=never'
fi
if command -v fd >/dev/null 2>&1; then
    alias find='fd'
fi
if command -v rg >/dev/null 2>&1; then
    alias grep='rg'
fi

# Other useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
EOF
    fi
}

# Add aliases to both bash and zsh
add_aliases "${HOME}/.bashrc"
add_aliases "${HOME}/.zshrc"

# Setup shell completions (supplement features that may not set them up)
log_info "Setting up shell completions..."

if command_exists kubectl; then
    mkdir -p "${HOME}/.bash_completion.d" "${HOME}/.zsh/completions"
    kubectl completion bash > "${HOME}/.bash_completion.d/kubectl" 2>/dev/null || true
    kubectl completion zsh > "${HOME}/.zsh/completions/_kubectl" 2>/dev/null || true
fi

if command_exists helm; then
    mkdir -p "${HOME}/.bash_completion.d" "${HOME}/.zsh/completions"
    helm completion bash > "${HOME}/.bash_completion.d/helm" 2>/dev/null || true
    helm completion zsh > "${HOME}/.zsh/completions/_helm" 2>/dev/null || true
fi

if command_exists terraform; then
    terraform -install-autocomplete 2>/dev/null || true
fi

if command_exists argocd; then
    mkdir -p "${HOME}/.bash_completion.d" "${HOME}/.zsh/completions"
    argocd completion bash > "${HOME}/.bash_completion.d/argocd" 2>/dev/null || true
    argocd completion zsh > "${HOME}/.zsh/completions/_argocd" 2>/dev/null || true
fi

# Source completions in bashrc if not already done
if [[ -f "${HOME}/.bashrc" ]] && ! grep -q ".bash_completion.d" "${HOME}/.bashrc" 2>/dev/null; then
    cat >> "${HOME}/.bashrc" << 'EOF'

# Load shell completions
if [[ -d "${HOME}/.bash_completion.d" ]]; then
    for f in "${HOME}/.bash_completion.d"/*; do
        [[ -f "${f}" ]] && source "${f}" 2>/dev/null || true
    done
fi
EOF
fi

# Source completions in zshrc if not already done
if [[ -f "${HOME}/.zshrc" ]] && ! grep -q ".zsh/completions" "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" << 'EOF'

# Load zsh completions
if [[ -d "${HOME}/.zsh/completions" ]]; then
    fpath=("${HOME}/.zsh/completions" $fpath)
    autoload -Uz compinit && compinit
fi
EOF
fi

log_success "Shell completions configured"

# Ensure PATH is set correctly before summary
export PATH="${HOME}/.local/bin:${PATH}:/usr/local/bin:/usr/bin:/bin"

# Display summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "                           INSTALLATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

tools=(
    "kubectl"
    "helm"
    "terraform"
    "ansible"
    "terragrunt"
    "tflint"
    "checkov"
    "clusterctl"
    "talosctl"
    "k9s"
    "kubectx"
    "kubens"
    "stern"
    "argocd"
    "infisical"
    "shellcheck"
    "yamllint"
    "git"
    "jq"
)

for tool in "${tools[@]}"; do
    version=""
    if command_exists "${tool}"; then
        # Try to get version, handle different output formats
        # Special cases for tools with non-standard version commands
        case "${tool}" in
            kubectl)
                version_output=$(${tool} version --client 2>&1 || echo "")
                ;;
            helm)
                version_output=$(${tool} version --short 2>&1 || echo "")
                ;;
            *)
                # Try --version first, then version, then other common patterns
                version_output=$(${tool} --version 2>&1 || ${tool} version 2>&1 || echo "")
                ;;
        esac

        if [[ -n "${version_output}" ]]; then
            # Extract version from first line, try to find version pattern
            # Use a subshell to isolate failures
            version=$( (echo "${version_output}" | head -n 1 | grep -oE '[vV]?[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9]+)?' || true) | head -n 1)
        fi
        # If still empty, just show "installed"
        if [[ -z "${version}" ]]; then
            version="installed"
        fi
        printf "${GREEN}✓${NC} %-20s %s\n" "${tool}:" "${version}"
    else
        printf "${YELLOW}✗${NC} %-20s %s\n" "${tool}:" "NOT INSTALLED"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_success "DevContainer setup complete!"
echo ""
log_info "Quick start:"
echo "  • Use 'k' alias for kubectl (e.g., 'k get pods')"
echo "  • Use 'tf' alias for terraform"
echo "  • Use 'tg' alias for terragrunt"
echo "  • Use 'argo' alias for argocd"
echo "  • Shell completions are enabled for kubectl, helm, terraform, and argocd"
echo "  • Git hooks via lefthook will run automatically on commit/push"
echo ""
