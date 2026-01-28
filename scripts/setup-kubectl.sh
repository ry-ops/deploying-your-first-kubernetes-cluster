#!/bin/bash

###############################################################################
# kubectl Setup Script
#
# This script configures kubectl to work with your K3s cluster. It handles
# kubeconfig setup for both local and remote access.
#
# Usage: ./setup-kubectl.sh [OPTIONS]
#
# Options:
#   --remote SERVER_IP   Configure kubectl for remote access
#   --user USERNAME      Specify the user to configure (default: current user)
#
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse arguments
REMOTE_SERVER=""
TARGET_USER="${SUDO_USER:-$USER}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --remote)
            REMOTE_SERVER="$2"
            shift 2
            ;;
        --user)
            TARGET_USER="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

log_info "Configuring kubectl for user: $TARGET_USER"

# Determine user home directory
if [[ "$TARGET_USER" == "root" ]]; then
    USER_HOME="/root"
else
    USER_HOME=$(eval echo ~$TARGET_USER)
fi

# Check if K3s is installed
if [[ ! -f /etc/rancher/k3s/k3s.yaml ]]; then
    log_error "K3s kubeconfig not found at /etc/rancher/k3s/k3s.yaml"
    log_info "Please install K3s first using: ./install-k3s.sh"
    exit 1
fi

# Create .kube directory
log_info "Creating .kube directory at $USER_HOME/.kube"
mkdir -p "$USER_HOME/.kube"

# Copy kubeconfig
if [[ -z "$REMOTE_SERVER" ]]; then
    # Local configuration
    log_info "Setting up local kubectl configuration..."

    if [[ $EUID -eq 0 ]]; then
        cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
        chown -R $TARGET_USER:$TARGET_USER "$USER_HOME/.kube"
    else
        sudo cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
        sudo chown -R $TARGET_USER:$TARGET_USER "$USER_HOME/.kube"
    fi

    chmod 600 "$USER_HOME/.kube/config"
    log_info "Kubeconfig copied to $USER_HOME/.kube/config"
else
    # Remote configuration
    log_info "Setting up remote kubectl configuration for server: $REMOTE_SERVER"

    if [[ $EUID -eq 0 ]]; then
        cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
        sed -i "s/127.0.0.1/$REMOTE_SERVER/g" "$USER_HOME/.kube/config"
        chown -R $TARGET_USER:$TARGET_USER "$USER_HOME/.kube"
    else
        sudo cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
        sudo sed -i "s/127.0.0.1/$REMOTE_SERVER/g" "$USER_HOME/.kube/config"
        sudo chown -R $TARGET_USER:$TARGET_USER "$USER_HOME/.kube"
    fi

    chmod 600 "$USER_HOME/.kube/config"
    log_info "Kubeconfig updated for remote access"
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    log_warn "kubectl not found in PATH"
    log_info "Installing kubectl..."

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            KUBECTL_ARCH="amd64"
            ;;
        aarch64|arm64)
            KUBECTL_ARCH="arm64"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    # Download kubectl
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    log_info "Downloading kubectl $KUBECTL_VERSION for $KUBECTL_ARCH..."

    if [[ $EUID -eq 0 ]]; then
        curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$KUBECTL_ARCH/kubectl"
        chmod +x kubectl
        mv kubectl /usr/local/bin/
    else
        curl -LO "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/$KUBECTL_ARCH/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi

    log_info "kubectl installed successfully"
fi

# Verify kubectl configuration
log_info "Verifying kubectl configuration..."

# Test kubectl as the target user
if [[ "$TARGET_USER" != "$USER" ]] && [[ $EUID -eq 0 ]]; then
    su - $TARGET_USER -c "kubectl version --client --short" &> /dev/null || true
    KUBECTL_WORKS=$(su - $TARGET_USER -c "kubectl get nodes --request-timeout=5s" 2>&1 || echo "FAILED")
else
    kubectl version --client --short &> /dev/null || true
    KUBECTL_WORKS=$(kubectl get nodes --request-timeout=5s 2>&1 || echo "FAILED")
fi

if [[ "$KUBECTL_WORKS" == *"FAILED"* ]] || [[ "$KUBECTL_WORKS" == *"error"* ]]; then
    log_warn "kubectl configuration may have issues"
    log_info "Error details: $KUBECTL_WORKS"
    log_info "You can test manually with: kubectl get nodes"
else
    log_info "kubectl is configured correctly!"
    echo ""
    log_info "Cluster nodes:"
    if [[ "$TARGET_USER" != "$USER" ]] && [[ $EUID -eq 0 ]]; then
        su - $TARGET_USER -c "kubectl get nodes"
    else
        kubectl get nodes
    fi
fi

# Display useful information
echo ""
log_info "kubectl Configuration Complete!"
echo ""
log_info "Useful Commands:"
echo "  kubectl get nodes              - List cluster nodes"
echo "  kubectl get pods -A            - List all pods"
echo "  kubectl cluster-info           - Display cluster info"
echo "  kubectl config view            - View current config"
echo "  kubectl config get-contexts    - List available contexts"
echo ""

if [[ -n "$REMOTE_SERVER" ]]; then
    log_info "Remote Access:"
    echo "  Server: $REMOTE_SERVER"
    echo "  Kubeconfig: $USER_HOME/.kube/config"
    echo ""
    log_warn "Ensure port 6443 is accessible on the remote server"
fi

log_info "For more kubectl commands, see: documentation/KUBECTL-GUIDE.md"
