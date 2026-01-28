#!/bin/bash

###############################################################################
# K3s Installation Script
#
# This script installs K3s, a lightweight Kubernetes distribution, with
# sensible defaults for development and production use.
#
# Usage: ./install-k3s.sh [OPTIONS]
#
# Options:
#   --disable-traefik    Disable Traefik ingress controller
#   --no-deploy          Skip all default deployments (useful for custom setups)
#   --write-kubeconfig-mode MODE  Set kubeconfig file permissions (default: 644)
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

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    log_error "This script is designed for Linux systems only"
    log_info "Current OS: $OSTYPE"
    exit 1
fi

# Check for root/sudo privileges
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root or with sudo privileges"
   exit 1
fi

log_info "Starting K3s installation..."

# Parse command line arguments
K3S_ARGS=""
for arg in "$@"; do
    case $arg in
        --disable-traefik)
            K3S_ARGS="$K3S_ARGS --disable traefik"
            log_info "Traefik will be disabled"
            shift
            ;;
        --no-deploy)
            K3S_ARGS="$K3S_ARGS --no-deploy"
            log_info "Default deployments will be skipped"
            shift
            ;;
        --write-kubeconfig-mode)
            K3S_ARGS="$K3S_ARGS --write-kubeconfig-mode $2"
            shift
            shift
            ;;
        *)
            ;;
    esac
done

# Set kubeconfig permissions if not specified
if [[ ! "$K3S_ARGS" =~ "--write-kubeconfig-mode" ]]; then
    K3S_ARGS="$K3S_ARGS --write-kubeconfig-mode 644"
fi

# Install K3s
log_info "Downloading and installing K3s..."
curl -sfL https://get.k3s.io | sh -s - $K3S_ARGS

# Wait for K3s to be ready
log_info "Waiting for K3s to be ready..."
sleep 10

# Check if K3s is running
if systemctl is-active --quiet k3s; then
    log_info "K3s service is running"
else
    log_error "K3s service failed to start"
    log_info "Check logs with: sudo journalctl -u k3s -f"
    exit 1
fi

# Wait for node to be ready
log_info "Waiting for node to be ready..."
timeout=60
counter=0
while [[ $counter -lt $timeout ]]; do
    if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
        log_info "Node is ready!"
        break
    fi
    sleep 2
    counter=$((counter + 2))
done

if [[ $counter -ge $timeout ]]; then
    log_warn "Timeout waiting for node to be ready"
    log_info "You can check node status with: kubectl get nodes"
fi

# Display cluster information
log_info "K3s installation complete!"
echo ""
log_info "Cluster Information:"
kubectl get nodes
echo ""

log_info "System Pods:"
kubectl get pods -A
echo ""

# Setup kubeconfig for non-root user
if [[ -n "$SUDO_USER" ]]; then
    USER_HOME=$(eval echo ~$SUDO_USER)
    log_info "Setting up kubeconfig for user: $SUDO_USER"

    mkdir -p "$USER_HOME/.kube"
    cp /etc/rancher/k3s/k3s.yaml "$USER_HOME/.kube/config"
    chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/.kube"
    chmod 600 "$USER_HOME/.kube/config"

    log_info "Kubeconfig copied to $USER_HOME/.kube/config"
fi

# Display next steps
echo ""
log_info "Next Steps:"
echo "  1. Verify installation: kubectl get nodes"
echo "  2. Check system pods: kubectl get pods -A"
echo "  3. Deploy sample app: kubectl apply -f manifests/"
echo "  4. Access kubeconfig: /etc/rancher/k3s/k3s.yaml"
echo ""

log_info "To uninstall K3s, run: /usr/local/bin/k3s-uninstall.sh"
echo ""

log_info "K3s is now ready for use!"
