# Deploying Your First Kubernetes Cluster

<p align="center">
  <img src="hero.svg" alt="Deploying Your First Kubernetes Cluster" width="100%">
</p>

A comprehensive guide and toolkit for deploying your first Kubernetes cluster using K3s, a lightweight Kubernetes distribution perfect for learning, development, and production edge deployments.

## Quick Start

Get your Kubernetes cluster running in minutes:

```bash
# Clone the repository
git clone https://github.com/ry-ops/deploying-your-first-kubernetes-cluster.git
cd deploying-your-first-kubernetes-cluster

# Install K3s
./scripts/install-k3s.sh

# Setup kubectl
./scripts/setup-kubectl.sh

# Deploy sample application
kubectl apply -f manifests/
```

## K3s Installation

K3s is a highly available, certified Kubernetes distribution designed for production workloads in resource-constrained environments. It's packaged as a single binary and uses only 512MB of RAM.

### Prerequisites

- Linux-based operating system (Ubuntu, Debian, CentOS, etc.)
- 1GB RAM minimum (2GB recommended)
- 1 CPU core minimum
- Root or sudo access

### Installation Methods

#### Automated Installation (Recommended)

Use our installation script for a quick setup:

```bash
./scripts/install-k3s.sh
```

This script will:
- Install K3s with sensible defaults
- Configure kubectl access
- Set up kubeconfig for the current user
- Verify the installation

#### Manual Installation

If you prefer to install K3s manually:

```bash
curl -sfL https://get.k3s.io | sh -
```

For additional options:

```bash
# Install without Traefik (if you plan to use nginx-ingress)
curl -sfL https://get.k3s.io | sh -s - --disable traefik

# Install as worker node
curl -sfL https://get.k3s.io | K3S_URL=https://myserver:6443 K3S_TOKEN=mynodetoken sh -
```

### Verify Installation

```bash
# Check K3s status
sudo systemctl status k3s

# Check nodes
kubectl get nodes

# Check system pods
kubectl get pods -A
```

## Repository Structure

```
.
├── scripts/              # Installation and setup scripts
│   ├── install-k3s.sh   # K3s installation script
│   └── setup-kubectl.sh # kubectl configuration script
├── manifests/           # Sample Kubernetes manifests
│   ├── deployment.yaml  # Nginx deployment example
│   ├── service.yaml     # Service configuration
│   ├── ingress.yaml     # Ingress controller setup
│   └── configmap.yaml   # ConfigMap example
├── examples/            # Complete application examples
│   ├── wordpress/       # WordPress deployment
│   ├── monitoring/      # Monitoring stack
│   └── multi-tier-app/  # Multi-tier application
└── documentation/       # Detailed guides
    ├── K3S-SETUP.md     # K3s setup guide
    ├── KUBECTL-GUIDE.md # kubectl reference
    └── TROUBLESHOOTING.md # Common issues and solutions
```

## What's Included

### Scripts

- **install-k3s.sh**: Automated K3s installation with best practices
- **setup-kubectl.sh**: Configure kubectl for cluster access

### Sample Manifests

Basic Kubernetes resources to get you started:
- Nginx deployment with 3 replicas
- ClusterIP and LoadBalancer service examples
- Ingress configuration for HTTP routing
- ConfigMap for application configuration

### Examples

Real-world application deployments:
- **WordPress**: Complete WordPress + MySQL setup with persistent storage
- **Monitoring**: Prometheus + Grafana monitoring stack
- **Multi-tier App**: Frontend, backend, and database tier example

### Documentation

Comprehensive guides covering:
- K3s installation and configuration
- kubectl usage and best practices
- Common troubleshooting scenarios

## Next Steps

After deploying your cluster:

1. **Explore the examples**: Deploy the WordPress or monitoring stack
2. **Read the documentation**: Learn about K3s features and kubectl commands
3. **Deploy your own apps**: Use the manifests as templates
4. **Scale up**: Add worker nodes to create a multi-node cluster

## Learning Resources

- [Official K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Check the [TROUBLESHOOTING.md](documentation/TROUBLESHOOTING.md) guide
- Open an issue on GitHub
- Consult the official K3s documentation

## Author

**ry-ops** - DevOps tutorials and infrastructure guides

---

Happy Kubernetes learning!
