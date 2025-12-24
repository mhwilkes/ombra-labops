#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install from GitHub release
install_gh_release() {
    local repo=$1
    local binary_name=$2
    local install_path=$3
    local version=${4:-latest}

    log_info "Installing ${binary_name} from ${repo}..."

    if [ "$version" = "latest" ]; then
        local download_url
        download_url=$(curl -sL "https://api.github.com/repos/${repo}/releases/latest" | \
            grep -o "https://.*/download/.*/.*linux.*amd64.*" | head -n 1 | \
            grep -v "\.sha256" | grep -v "\.sig" | head -n 1)
    else
        local download_url
        download_url=$(curl -sL "https://api.github.com/repos/${repo}/releases/tags/${version}" | \
            grep -o "https://.*/download/.*/.*linux.*amd64.*" | head -n 1 | \
            grep -v "\.sha256" | grep -v "\.sig" | head -n 1)
    fi

    if [ -z "$download_url" ]; then
        log_error "Failed to find download URL for ${binary_name}"
        return 1
    fi

    local temp_file
    temp_file=$(mktemp)
    curl -fsSL "${download_url}" -o "${temp_file}"
    chmod +x "${temp_file}"

    # Extract if it's a tarball
    if echo "${download_url}" | grep -q "\.tar\.gz"; then
        mkdir -p "$(dirname "${install_path}")"
        tar -xzf "${temp_file}" -C "$(dirname "${install_path}")" "${binary_name}" 2>/dev/null || \
            tar -xzf "${temp_file}" -C "$(dirname "${install_path}")" --strip-components=1
        mv "$(dirname "${install_path}")/${binary_name}" "${install_path}" 2>/dev/null || true
    else
        mkdir -p "$(dirname "${install_path}")"
        mv "${temp_file}" "${install_path}"
    fi

    chmod +x "${install_path}"
    rm -f "${temp_file}"
    log_success "Installed ${binary_name}"
}

# Update package lists
log_info "Updating package lists..."
sudo apt-get update -qq

# Install base dependencies
log_info "Installing base dependencies..."
sudo apt-get install -y -qq \
    curl \
    wget \
    git \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    shellcheck \
    build-essential \
    python3-pip \
    python3-setuptools \
    bash-completion \
    > /dev/null

log_success "Base dependencies installed"

# Install Ansible
if ! command_exists ansible; then
    log_info "Installing Ansible..."
    pip3 install --user --break-system-packages ansible ansible-lint > /dev/null 2>&1 || \
        pip3 install --user ansible ansible-lint > /dev/null 2>&1
    export PATH="${HOME}/.local/bin:${PATH}"
    log_success "Ansible installed"
else
    log_info "Ansible already installed"
fi

# Install Terragrunt
if ! command_exists terragrunt; then
    log_info "Installing Terragrunt..."
    tg_version=$(curl -sL "https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest" | \
        jq -r '.tag_name' | sed 's/v//')
    wget -q "https://github.com/gruntwork-io/terragrunt/releases/download/v${tg_version}/terragrunt_linux_amd64" \
        -O /tmp/terragrunt
    sudo mv /tmp/terragrunt /usr/local/bin/terragrunt
    sudo chmod +x /usr/local/bin/terragrunt
    log_success "Terragrunt installed"
else
    log_info "Terragrunt already installed"
fi

# Install clusterctl
if ! command_exists clusterctl; then
    log_info "Installing clusterctl..."
    install_gh_release "kubernetes-sigs/cluster-api" "clusterctl-linux-amd64" "/usr/local/bin/clusterctl"
    log_success "clusterctl installed"
else
    log_info "clusterctl already installed"
fi

# Install talosctl
if ! command_exists talosctl; then
    log_info "Installing talosctl..."
    install_gh_release "siderolabs/talos" "talosctl-linux-amd64" "/usr/local/bin/talosctl"
    log_success "talosctl installed"
else
    log_info "talosctl already installed"
fi

# Install k9s
if ! command_exists k9s; then
    log_info "Installing k9s..."
    install_gh_release "derailed/k9s" "k9s_Linux_amd64.tar.gz" "/usr/local/bin/k9s"
    log_success "k9s installed"
else
    log_info "k9s already installed"
fi

# Install checkov (Terraform/K8s security scanner)
if ! command_exists checkov; then
    log_info "Installing checkov..."
    pip3 install --user --break-system-packages checkov > /dev/null 2>&1 || \
        pip3 install --user checkov > /dev/null 2>&1
    export PATH="${HOME}/.local/bin:${PATH}"
    log_success "checkov installed"
else
    log_info "checkov already installed"
fi

# Install tflint (Terraform linter)
if ! command_exists tflint; then
    log_info "Installing tflint..."
    tflint_version=$(curl -sL "https://api.github.com/repos/terraform-linters/tflint/releases/latest" | \
        jq -r '.tag_name' | sed 's/v//')
    tflint_url="https://github.com/terraform-linters/tflint/releases/download/v${tflint_version}/tflint_linux_amd64.zip"
    wget -q "${tflint_url}" -O /tmp/tflint.zip
    unzip -q -o /tmp/tflint.zip -d /tmp/tflint
    sudo mv /tmp/tflint/tflint /usr/local/bin/tflint
    sudo chmod +x /usr/local/bin/tflint
    rm -rf /tmp/tflint.zip /tmp/tflint
    log_success "tflint installed"
else
    log_info "tflint already installed"
fi

# Install yamllint
if ! command_exists yamllint; then
    log_info "Installing yamllint..."
    pip3 install --user --break-system-packages yamllint > /dev/null 2>&1 || \
        pip3 install --user yamllint > /dev/null 2>&1
    export PATH="${HOME}/.local/bin:${PATH}"
    log_success "yamllint installed"
else
    log_info "yamllint already installed"
fi

# Setup shell completions
log_info "Setting up shell completions..."

# kubectl completion
if command_exists kubectl; then
    kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
fi

# helm completion
if command_exists helm; then
    helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
fi

# terraform completion (if available)
if command_exists terraform; then
    terraform -install-autocomplete 2>/dev/null || true
fi

log_success "Shell completions configured"

# Create helpful aliases
log_info "Setting up aliases..."
cat >> "${HOME}/.bashrc" << 'EOF'

# IaC and Kubernetes aliases
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias ka='kubectl apply'
alias kdel='kubectl delete'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kctx='kubectl config get-contexts'
alias kns='kubectl config set-context --current --namespace'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gb='git branch'
alias gco='git checkout'

# Terraform aliases
alias tf='terraform'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfv='terraform validate'

# Terragrunt aliases
alias tg='terragrunt'
alias tga='terragrunt apply'
alias tgp='terragrunt plan'

# Other useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

EOF

log_success "Aliases configured"

# Verify installations
log_info "Verifying tool installations..."
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
    "clusterctl"
    "talosctl"
    "k9s"
    "shellcheck"
    "checkov"
    "tflint"
    "yamllint"
    "git"
    "jq"
)

for tool in "${tools[@]}"; do
    if command_exists "$tool"; then
        version=$($tool --version 2>&1 | head -n 1 | cut -d' ' -f2- | cut -d',' -f1 | head -c 30)
        printf "${GREEN}✓${NC} %-15s %s\n" "${tool}:" "${version}"
    else
        printf "${RED}✗${NC} %-15s %s\n" "${tool}:" "NOT INSTALLED"
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
echo "  • Shell completions are enabled for kubectl, helm, and terraform"
echo ""
