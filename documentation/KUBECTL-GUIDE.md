# kubectl Guide

A comprehensive guide to using kubectl, the Kubernetes command-line tool, for managing your K3s cluster.

## Table of Contents

- [Installation](#installation)
- [Configuration](#configuration)
- [Basic Commands](#basic-commands)
- [Working with Pods](#working-with-pods)
- [Working with Deployments](#working-with-deployments)
- [Working with Services](#working-with-services)
- [Namespaces](#namespaces)
- [ConfigMaps and Secrets](#configmaps-and-secrets)
- [Logs and Debugging](#logs-and-debugging)
- [Advanced Operations](#advanced-operations)
- [Useful Aliases](#useful-aliases)

## Installation

### Using K3s

kubectl is automatically installed with K3s:

```bash
# Verify installation
kubectl version --client

# K3s also provides k3s kubectl
k3s kubectl version
```

### Manual Installation

#### Linux

```bash
# Download latest version
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Install
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify
kubectl version --client
```

#### macOS

```bash
# Using Homebrew
brew install kubectl

# Or download directly
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Windows

```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or download from https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

## Configuration

### Kubeconfig Setup

kubectl uses kubeconfig to connect to clusters:

```bash
# K3s kubeconfig location
/etc/rancher/k3s/k3s.yaml

# Standard location
~/.kube/config
```

### Setup kubectl for K3s

Use the provided script:

```bash
./scripts/setup-kubectl.sh
```

Or manually:

```bash
# Copy kubeconfig
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
chmod 600 ~/.kube/config
```

### Multiple Clusters

#### View Contexts

```bash
# List all contexts
kubectl config get-contexts

# Show current context
kubectl config current-context
```

#### Switch Contexts

```bash
# Switch to different context
kubectl config use-context <context-name>

# Set namespace for current context
kubectl config set-context --current --namespace=<namespace>
```

#### Add New Cluster

```bash
kubectl config set-cluster <cluster-name> \
  --server=https://example.com:6443 \
  --certificate-authority=ca.crt

kubectl config set-credentials <user-name> \
  --client-certificate=client.crt \
  --client-key=client.key

kubectl config set-context <context-name> \
  --cluster=<cluster-name> \
  --user=<user-name>
```

## Basic Commands

### Cluster Information

```bash
# Cluster info
kubectl cluster-info

# Cluster version
kubectl version

# Node information
kubectl get nodes
kubectl get nodes -o wide

# API resources
kubectl api-resources

# API versions
kubectl api-versions
```

### Get Resources

```bash
# Get all resources in current namespace
kubectl get all

# Get specific resource type
kubectl get pods
kubectl get services
kubectl get deployments

# Get from all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Get with labels
kubectl get pods -l app=nginx
kubectl get pods -l 'environment in (prod,staging)'

# Get with field selector
kubectl get pods --field-selector=status.phase=Running

# Watch resources (live updates)
kubectl get pods -w
```

### Describe Resources

```bash
# Detailed information
kubectl describe node <node-name>
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>

# Describe all pods
kubectl describe pods
```

### Create Resources

```bash
# Create from file
kubectl create -f <file.yaml>
kubectl create -f <directory>/

# Create from URL
kubectl create -f https://example.com/manifest.yaml

# Apply (create or update)
kubectl apply -f <file.yaml>

# Dry run (test without creating)
kubectl apply -f <file.yaml> --dry-run=client
kubectl apply -f <file.yaml> --dry-run=server
```

### Delete Resources

```bash
# Delete by file
kubectl delete -f <file.yaml>

# Delete by name
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>

# Delete all of a type
kubectl delete pods --all

# Force delete
kubectl delete pod <pod-name> --force --grace-period=0

# Delete with label selector
kubectl delete pods -l app=nginx
```

## Working with Pods

### Get Pods

```bash
# List pods
kubectl get pods

# Detailed output
kubectl get pods -o wide

# JSON output
kubectl get pods -o json

# YAML output
kubectl get pods -o yaml

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# Sort by creation time
kubectl get pods --sort-by=.metadata.creationTimestamp
```

### Create Pods

```bash
# Run single pod
kubectl run nginx --image=nginx

# Run with port
kubectl run nginx --image=nginx --port=80

# Run with environment variables
kubectl run nginx --image=nginx --env="ENV=prod"

# Run with labels
kubectl run nginx --image=nginx --labels="app=nginx,tier=frontend"

# Dry run to generate YAML
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
```

### Execute Commands

```bash
# Execute command in pod
kubectl exec <pod-name> -- <command>

# Interactive shell
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it <pod-name> -- sh

# Specific container in pod
kubectl exec -it <pod-name> -c <container-name> -- bash

# Run commands
kubectl exec <pod-name> -- ls /
kubectl exec <pod-name> -- env
```

### Port Forwarding

```bash
# Forward port from pod
kubectl port-forward <pod-name> 8080:80

# Forward from service
kubectl port-forward service/<service-name> 8080:80

# Forward to specific address
kubectl port-forward <pod-name> 8080:80 --address 0.0.0.0
```

### Copy Files

```bash
# Copy from pod
kubectl cp <pod-name>:/path/to/file /local/path

# Copy to pod
kubectl cp /local/path <pod-name>:/path/to/file

# Specific container
kubectl cp <pod-name>:/path/to/file /local/path -c <container-name>
```

## Working with Deployments

### Create Deployment

```bash
# Create deployment
kubectl create deployment nginx --image=nginx

# With replicas
kubectl create deployment nginx --image=nginx --replicas=3

# Generate YAML
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
```

### Scale Deployment

```bash
# Scale to specific replicas
kubectl scale deployment nginx --replicas=5

# Autoscale
kubectl autoscale deployment nginx --min=3 --max=10 --cpu-percent=80
```

### Update Deployment

```bash
# Update image
kubectl set image deployment/nginx nginx=nginx:1.25

# Update with record
kubectl set image deployment/nginx nginx=nginx:1.25 --record

# Edit deployment
kubectl edit deployment nginx

# Apply changes from file
kubectl apply -f deployment.yaml
```

### Rollout Management

```bash
# Check rollout status
kubectl rollout status deployment/nginx

# View rollout history
kubectl rollout history deployment/nginx

# Rollback to previous version
kubectl rollout undo deployment/nginx

# Rollback to specific revision
kubectl rollout undo deployment/nginx --to-revision=2

# Pause rollout
kubectl rollout pause deployment/nginx

# Resume rollout
kubectl rollout resume deployment/nginx

# Restart deployment
kubectl rollout restart deployment/nginx
```

## Working with Services

### Create Service

```bash
# Expose deployment
kubectl expose deployment nginx --port=80 --type=ClusterIP

# LoadBalancer service
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# NodePort service
kubectl expose deployment nginx --port=80 --type=NodePort

# With target port
kubectl expose deployment nginx --port=80 --target-port=8080
```

### Get Services

```bash
# List services
kubectl get services
kubectl get svc

# Detailed output
kubectl get svc -o wide

# Get endpoints
kubectl get endpoints
kubectl get ep
```

### Test Services

```bash
# Get service URL (for LoadBalancer)
kubectl get svc <service-name> -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Port forward to test
kubectl port-forward svc/<service-name> 8080:80

# Create test pod
kubectl run curl --image=curlimages/curl -it --rm -- sh
# Inside pod: curl http://service-name
```

## Namespaces

### Manage Namespaces

```bash
# List namespaces
kubectl get namespaces
kubectl get ns

# Create namespace
kubectl create namespace dev

# Delete namespace (deletes all resources in it)
kubectl delete namespace dev

# Set default namespace
kubectl config set-context --current --namespace=dev
```

### Work with Namespaces

```bash
# Get resources in specific namespace
kubectl get pods -n kube-system

# Create resource in namespace
kubectl create -f pod.yaml -n dev

# Apply to namespace
kubectl apply -f deployment.yaml -n prod

# Get from all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A
```

## ConfigMaps and Secrets

### ConfigMaps

```bash
# Create from literal
kubectl create configmap app-config --from-literal=ENV=prod

# Create from file
kubectl create configmap app-config --from-file=config.txt

# Create from directory
kubectl create configmap app-config --from-file=configs/

# Get configmaps
kubectl get configmaps
kubectl get cm

# View configmap data
kubectl get configmap app-config -o yaml

# Edit configmap
kubectl edit configmap app-config
```

### Secrets

```bash
# Create from literal
kubectl create secret generic db-secret --from-literal=password=mysecret

# Create from file
kubectl create secret generic tls-secret --from-file=tls.key --from-file=tls.crt

# Create TLS secret
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key

# Create Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com

# Get secrets
kubectl get secrets

# View secret (base64 encoded)
kubectl get secret db-secret -o yaml

# Decode secret
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 -d
```

## Logs and Debugging

### View Logs

```bash
# Pod logs
kubectl logs <pod-name>

# Follow logs (stream)
kubectl logs -f <pod-name>

# Last N lines
kubectl logs --tail=100 <pod-name>

# Since timestamp
kubectl logs --since=1h <pod-name>

# Specific container
kubectl logs <pod-name> -c <container-name>

# Previous container (after restart)
kubectl logs <pod-name> --previous

# All pods with label
kubectl logs -l app=nginx
```

### Debug Pods

```bash
# Describe pod
kubectl describe pod <pod-name>

# Get events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -n <namespace>

# Run debug container
kubectl run debug --image=busybox -it --rm -- sh

# Debug with specific image
kubectl run debug --image=nicolaka/netshoot -it --rm -- bash

# Attach to running pod
kubectl attach <pod-name> -it

# Copy pod for debugging
kubectl debug <pod-name> --image=busybox --share-processes --copy-to=debug-pod
```

### Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods

# Specific namespace
kubectl top pods -n kube-system

# Sort by CPU
kubectl top pods --sort-by=cpu

# Sort by memory
kubectl top pods --sort-by=memory
```

## Advanced Operations

### Labels and Annotations

```bash
# Add label
kubectl label pod <pod-name> env=prod

# Remove label
kubectl label pod <pod-name> env-

# Update label
kubectl label pod <pod-name> env=staging --overwrite

# Add annotation
kubectl annotate pod <pod-name> description="My pod"

# Show labels
kubectl get pods --show-labels

# Filter by labels
kubectl get pods -l env=prod
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l 'env!=dev'
```

### JSONPath Queries

```bash
# Get pod IPs
kubectl get pods -o jsonpath='{.items[*].status.podIP}'

# Get node names
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Complex query
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'

# With custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
```

### Patch Resources

```bash
# Patch with JSON
kubectl patch deployment nginx -p '{"spec":{"replicas":3}}'

# Patch with YAML
kubectl patch service nginx -p '{"spec":{"type":"LoadBalancer"}}'

# Strategic merge patch
kubectl patch deployment nginx --type=strategic -p '{"spec":{"replicas":3}}'

# JSON patch
kubectl patch deployment nginx --type=json -p '[{"op":"replace","path":"/spec/replicas","value":3}]'
```

### Wait for Conditions

```bash
# Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=nginx

# Wait for deployment
kubectl wait --for=condition=available deployment/nginx

# With timeout
kubectl wait --for=condition=ready pod <pod-name> --timeout=60s
```

## Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# General
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'

# Describe
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'

# Logs
alias kl='kubectl logs'
alias klf='kubectl logs -f'

# Apply and delete
alias ka='kubectl apply -f'
alias kdel='kubectl delete'

# Namespaces
alias kgns='kubectl get namespaces'
alias kcn='kubectl config set-context --current --namespace'

# All namespaces
alias kgpa='kubectl get pods --all-namespaces'
alias kgsa='kubectl get services --all-namespaces'

# Execute
alias kex='kubectl exec -it'

# Context
alias kcc='kubectl config current-context'
alias kuc='kubectl config use-context'
```

Enable bash completion:

```bash
# Linux
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl

# macOS
kubectl completion bash > $(brew --prefix)/etc/bash_completion.d/kubectl

# zsh
source <(kubectl completion zsh)
```

## Best Practices

1. **Use Namespaces**: Organize resources by namespace
2. **Label Everything**: Use consistent labeling strategy
3. **Use Declarative Configuration**: Prefer `apply` over `create`
4. **Version Control**: Store manifests in Git
5. **Dry Run**: Test changes with `--dry-run`
6. **Resource Limits**: Always set resource requests/limits
7. **Health Checks**: Configure liveness and readiness probes
8. **Use ConfigMaps/Secrets**: Externalize configuration
9. **Monitor Resources**: Regularly check `kubectl top`
10. **Clean Up**: Delete unused resources

## kubectl Cheat Sheet

Quick reference of common commands:

```bash
# Get resources
kubectl get pods
kubectl get svc
kubectl get deploy

# Describe
kubectl describe pod <name>

# Logs
kubectl logs <pod>
kubectl logs -f <pod>

# Execute
kubectl exec -it <pod> -- bash

# Port forward
kubectl port-forward <pod> 8080:80

# Scale
kubectl scale deploy <name> --replicas=3

# Update image
kubectl set image deploy/<name> <container>=<image>

# Rollback
kubectl rollout undo deploy/<name>

# Delete
kubectl delete pod <name>
kubectl delete -f <file>

# Apply
kubectl apply -f <file>

# Top
kubectl top nodes
kubectl top pods
```

## Additional Resources

- [Official kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [JSONPath Guide](https://kubernetes.io/docs/reference/kubectl/jsonpath/)

## Next Steps

- [K3s Setup Guide](K3S-SETUP.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- Practice with examples in `examples/` directory
