# K3s Setup Guide

A comprehensive guide to installing, configuring, and managing K3s Kubernetes clusters.

## Table of Contents

- [What is K3s?](#what-is-k3s)
- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
- [Configuration Options](#configuration-options)
- [Cluster Setup](#cluster-setup)
- [High Availability](#high-availability)
- [Upgrading K3s](#upgrading-k3s)
- [Uninstalling K3s](#uninstalling-k3s)

## What is K3s?

K3s is a highly available, certified Kubernetes distribution designed for production workloads in resource-constrained environments. It's perfect for:

- **Edge computing**: IoT and edge deployments
- **Development**: Local Kubernetes development
- **CI/CD**: Continuous integration pipelines
- **ARM devices**: Raspberry Pi and similar hardware
- **Production**: Lightweight production workloads

### Key Features

- **Lightweight**: Single binary less than 100MB
- **Simple**: Easy to install and manage
- **Secure**: Secure by default with sensible defaults
- **Production Ready**: CNCF certified Kubernetes distribution
- **Low Resource**: Runs with 512MB RAM

## System Requirements

### Minimum Requirements

- **CPU**: 1 core
- **RAM**: 512MB (1GB recommended)
- **Disk**: 2GB
- **OS**: Linux (Ubuntu, Debian, CentOS, RHEL, etc.)

### Recommended for Production

- **CPU**: 2+ cores
- **RAM**: 2GB+
- **Disk**: 20GB+
- **OS**: Long-term support Linux distribution

### Network Requirements

- **Port 6443**: Kubernetes API server
- **Port 10250**: Kubelet metrics
- **Ports 30000-32767**: NodePort services (optional)

### Supported Operating Systems

- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- SLES 15+
- Raspberry Pi OS

## Installation Methods

### Method 1: Quick Install (Automated Script)

Use the installation script from this repository:

```bash
cd deploying-your-first-kubernetes-cluster
sudo ./scripts/install-k3s.sh
```

This script:
- Installs K3s with best practices
- Configures kubectl access
- Sets up kubeconfig for non-root users
- Verifies the installation

### Method 2: Official Install Script

Use K3s official installation script:

```bash
curl -sfL https://get.k3s.io | sh -
```

### Method 3: Manual Installation

Download and install manually:

```bash
# Download K3s binary
curl -LO https://github.com/k3s-io/k3s/releases/download/v1.28.4+k3s2/k3s
chmod +x k3s
sudo mv k3s /usr/local/bin/

# Install as a service
sudo k3s server &
```

## Configuration Options

### Basic Options

```bash
# Install without Traefik
curl -sfL https://get.k3s.io | sh -s - --disable traefik

# Install with custom data directory
curl -sfL https://get.k3s.io | sh -s - --data-dir /opt/k3s

# Install with specific Kubernetes version
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.4+k3s2 sh -
```

### Advanced Configuration

Create `/etc/rancher/k3s/config.yaml`:

```yaml
# K3s Server Configuration
write-kubeconfig-mode: "0644"
tls-san:
  - "example.com"
  - "192.168.1.100"

# Disable components
disable:
  - traefik
  - servicelb

# Cluster settings
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"
cluster-dns: "10.43.0.10"

# Data directory
data-dir: "/var/lib/rancher/k3s"
```

Then install:

```bash
curl -sfL https://get.k3s.io | sh -
```

### Environment Variables

Useful environment variables:

```bash
# Installation channel (stable, latest, testing)
export INSTALL_K3S_CHANNEL=stable

# Skip downloading, use local binary
export INSTALL_K3S_SKIP_DOWNLOAD=true

# Install specific version
export INSTALL_K3S_VERSION=v1.28.4+k3s2

# Custom binary directory
export INSTALL_K3S_BIN_DIR=/usr/local/bin

# Custom systemd directory
export INSTALL_K3S_SYSTEMD_DIR=/etc/systemd/system
```

## Cluster Setup

### Single-Node Cluster

Perfect for development and testing:

```bash
# Install K3s server
curl -sfL https://get.k3s.io | sh -

# Verify
kubectl get nodes
```

### Multi-Node Cluster

#### Setup Server Node

On the first server (control plane):

```bash
# Install K3s server
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Get node token
sudo cat /var/lib/rancher/k3s/server/node-token
```

#### Add Worker Nodes

On worker nodes:

```bash
# Replace SERVER_IP and NODE_TOKEN with your values
curl -sfL https://get.k3s.io | K3S_URL=https://SERVER_IP:6443 K3S_TOKEN=NODE_TOKEN sh -
```

Example:

```bash
curl -sfL https://get.k3s.io | \
  K3S_URL=https://192.168.1.100:6443 \
  K3S_TOKEN=K10abc123def456::server:789xyz \
  sh -
```

#### Verify Cluster

```bash
kubectl get nodes
```

### Adding Labels to Nodes

```bash
# Add role label
kubectl label node worker-1 node-role.kubernetes.io/worker=worker

# Add custom labels
kubectl label node worker-1 workload=database
kubectl label node worker-2 workload=web
```

## High Availability

### HA with Embedded etcd

For 3+ server nodes:

#### First Server

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --cluster-init \
  --tls-san=loadbalancer.example.com
```

#### Additional Servers

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --server https://first-server:6443 \
  --token=<TOKEN>
```

### HA with External Database

#### Prerequisites

Setup external PostgreSQL or MySQL database.

#### Install Servers

```bash
curl -sfL https://get.k3s.io | sh -s - server \
  --datastore-endpoint="postgres://username:password@hostname:5432/k3s"
```

All servers connect to the same database.

## Managing K3s

### Service Management

```bash
# Check status
sudo systemctl status k3s

# Start service
sudo systemctl start k3s

# Stop service
sudo systemctl stop k3s

# Restart service
sudo systemctl restart k3s

# Enable on boot
sudo systemctl enable k3s

# Disable on boot
sudo systemctl disable k3s
```

### View Logs

```bash
# View K3s logs
sudo journalctl -u k3s -f

# View last 100 lines
sudo journalctl -u k3s -n 100

# View since timestamp
sudo journalctl -u k3s --since "1 hour ago"
```

### Configuration Files

Important K3s files and directories:

```
/etc/rancher/k3s/               # Configuration directory
├── config.yaml                 # K3s configuration
└── k3s.yaml                    # Kubeconfig file

/var/lib/rancher/k3s/           # Data directory
├── server/
│   ├── node-token              # Node join token
│   └── manifests/              # Auto-deploy manifests
└── agent/

/usr/local/bin/
├── k3s                         # K3s binary
├── kubectl                     # Kubectl symlink
└── crictl                      # Container runtime CLI
```

## Upgrading K3s

### Automated Upgrade

Using the install script:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.28.5+k3s1 sh -
```

### Manual Upgrade

1. **Download new version**:
   ```bash
   curl -LO https://github.com/k3s-io/k3s/releases/download/v1.28.5+k3s1/k3s
   ```

2. **Replace binary**:
   ```bash
   sudo systemctl stop k3s
   sudo mv k3s /usr/local/bin/k3s
   chmod +x /usr/local/bin/k3s
   sudo systemctl start k3s
   ```

3. **Verify upgrade**:
   ```bash
   k3s --version
   kubectl version
   ```

### System Upgrade Controller

For automated upgrades:

```bash
# Install system-upgrade-controller
kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/latest/download/system-upgrade-controller.yaml

# Create upgrade plan
cat <<EOF | kubectl apply -f -
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: server-plan
  namespace: system-upgrade
spec:
  concurrency: 1
  cordon: true
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/control-plane
      operator: In
      values:
      - "true"
  serviceAccountName: system-upgrade
  upgrade:
    image: rancher/k3s-upgrade
  version: v1.28.5+k3s1
EOF
```

## Uninstalling K3s

### Server Node

```bash
/usr/local/bin/k3s-uninstall.sh
```

### Agent Node

```bash
/usr/local/bin/k3s-agent-uninstall.sh
```

### Clean Remaining Files

```bash
# Remove configuration
sudo rm -rf /etc/rancher/k3s

# Remove data
sudo rm -rf /var/lib/rancher/k3s

# Remove CNI
sudo rm -rf /var/lib/cni
```

## Troubleshooting

### K3s Service Won't Start

Check logs:
```bash
sudo journalctl -u k3s -f
```

Common issues:
- Port 6443 already in use
- Insufficient permissions
- Network configuration issues

### Node Not Ready

Check node status:
```bash
kubectl describe node <node-name>
```

Common causes:
- CNI issues
- Disk pressure
- Memory pressure
- Network connectivity

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name>
```

### Network Issues

Test DNS:
```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default
```

Test connectivity:
```bash
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never -- bash
```

## Best Practices

1. **Security**
   - Run latest stable version
   - Enable network policies
   - Use RBAC for access control
   - Regular security updates

2. **Resource Management**
   - Set resource limits
   - Monitor resource usage
   - Plan capacity appropriately

3. **High Availability**
   - Use 3+ server nodes for HA
   - Implement backup strategy
   - Use external database for critical workloads

4. **Monitoring**
   - Deploy monitoring stack
   - Set up alerts
   - Regular health checks

5. **Backups**
   - Backup etcd regularly
   - Document cluster configuration
   - Test restore procedures

## Additional Resources

- [Official K3s Documentation](https://docs.k3s.io/)
- [K3s GitHub Repository](https://github.com/k3s-io/k3s)
- [Rancher Forums](https://forums.rancher.com/)
- [K3s Best Practices](https://docs.k3s.io/advanced)

## Next Steps

- [kubectl Guide](KUBECTL-GUIDE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- Deploy sample applications from `examples/` directory
