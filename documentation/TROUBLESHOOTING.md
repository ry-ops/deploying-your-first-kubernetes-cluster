# Troubleshooting Guide

A comprehensive guide to diagnosing and resolving common issues with K3s and Kubernetes.

## Table of Contents

- [General Troubleshooting Workflow](#general-troubleshooting-workflow)
- [K3s Installation Issues](#k3s-installation-issues)
- [Node Issues](#node-issues)
- [Pod Issues](#pod-issues)
- [Service and Networking Issues](#service-and-networking-issues)
- [Storage Issues](#storage-issues)
- [Performance Issues](#performance-issues)
- [Security Issues](#security-issues)
- [Common Error Messages](#common-error-messages)

## General Troubleshooting Workflow

Follow this systematic approach when troubleshooting:

1. **Identify the Problem**
   - What is the expected behavior?
   - What is the actual behavior?
   - When did the issue start?

2. **Check Resource Status**
   ```bash
   kubectl get all -A
   kubectl get nodes
   kubectl get events --sort-by='.lastTimestamp'
   ```

3. **Examine Logs**
   ```bash
   # K3s service logs
   sudo journalctl -u k3s -f

   # Pod logs
   kubectl logs <pod-name>
   kubectl logs <pod-name> --previous
   ```

4. **Describe Resources**
   ```bash
   kubectl describe pod <pod-name>
   kubectl describe node <node-name>
   ```

5. **Check Resource Usage**
   ```bash
   kubectl top nodes
   kubectl top pods
   ```

## K3s Installation Issues

### K3s Service Fails to Start

**Symptoms:**
- K3s service won't start
- `systemctl status k3s` shows failed state

**Diagnosis:**
```bash
# Check service status
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -n 100 --no-pager

# Check for port conflicts
sudo netstat -tulpn | grep :6443
sudo lsof -i :6443
```

**Common Causes:**

1. **Port 6443 Already in Use**
   ```bash
   # Find process using port
   sudo lsof -i :6443

   # Kill the process or change K3s port
   curl -sfL https://get.k3s.io | sh -s - --https-listen-port 6444
   ```

2. **Insufficient Permissions**
   ```bash
   # Ensure you have sudo/root access
   sudo k3s server
   ```

3. **Container Runtime Issues**
   ```bash
   # Check containerd
   sudo k3s crictl ps

   # Restart K3s
   sudo systemctl restart k3s
   ```

4. **Firewall Blocking Ports**
   ```bash
   # Allow required ports
   sudo ufw allow 6443/tcp
   sudo ufw allow 10250/tcp
   ```

### kubectl Not Working After Installation

**Symptoms:**
- `kubectl: command not found`
- `The connection to the server localhost:8080 was refused`

**Solution:**

1. **kubectl not in PATH**
   ```bash
   # Use K3s kubectl
   k3s kubectl get nodes

   # Or create symlink
   sudo ln -s /usr/local/bin/k3s /usr/local/bin/kubectl
   ```

2. **Kubeconfig not configured**
   ```bash
   # Set KUBECONFIG environment variable
   export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

   # Or copy to user directory
   mkdir -p ~/.kube
   sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
   sudo chown $USER:$USER ~/.kube/config
   ```

3. **Permission denied**
   ```bash
   # Fix kubeconfig permissions
   sudo chmod 644 /etc/rancher/k3s/k3s.yaml
   ```

## Node Issues

### Node Not Ready

**Symptoms:**
- `kubectl get nodes` shows node in `NotReady` state

**Diagnosis:**
```bash
# Check node status
kubectl get nodes

# Describe node
kubectl describe node <node-name>

# Check node conditions
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
```

**Common Causes:**

1. **Network Plugin Issues**
   ```bash
   # Check CNI pods
   kubectl get pods -n kube-system -l k8s-app=flannel

   # Check logs
   kubectl logs -n kube-system -l k8s-app=flannel

   # Restart K3s
   sudo systemctl restart k3s
   ```

2. **Disk Pressure**
   ```bash
   # Check disk usage
   df -h

   # Clean up old images
   sudo k3s crictl rmi --prune

   # Clean up unused volumes
   kubectl delete pvc --all
   ```

3. **Memory Pressure**
   ```bash
   # Check memory
   free -h

   # Check pod resource usage
   kubectl top pods -A

   # Reduce replicas or add more nodes
   kubectl scale deployment <name> --replicas=1
   ```

4. **Kubelet Not Running**
   ```bash
   # On worker node, check K3s agent
   sudo systemctl status k3s-agent

   # Restart agent
   sudo systemctl restart k3s-agent
   ```

### Node Cannot Join Cluster

**Symptoms:**
- Worker node fails to join cluster
- `kubectl get nodes` doesn't show new node

**Solution:**

1. **Check Token**
   ```bash
   # On server, get token
   sudo cat /var/lib/rancher/k3s/server/node-token

   # Verify token in agent command
   echo $K3S_TOKEN
   ```

2. **Check Server URL**
   ```bash
   # Ensure correct server IP and port
   curl -k https://<server-ip>:6443
   ```

3. **Network Connectivity**
   ```bash
   # Test connection from worker
   telnet <server-ip> 6443
   nc -zv <server-ip> 6443

   # Check firewall
   sudo ufw status
   ```

4. **Check Agent Logs**
   ```bash
   # On worker node
   sudo journalctl -u k3s-agent -f
   ```

## Pod Issues

### Pod Stuck in Pending

**Symptoms:**
- Pod remains in `Pending` state
- Pod is not being scheduled

**Diagnosis:**
```bash
# Check pod status
kubectl get pod <pod-name> -o wide

# Describe pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Common Causes:**

1. **Insufficient Resources**
   ```bash
   # Check node resources
   kubectl top nodes

   # Check resource requests
   kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].resources}'

   # Solution: Reduce resource requests or add nodes
   kubectl edit deployment <name>
   ```

2. **PVC Not Bound**
   ```bash
   # Check PVC status
   kubectl get pvc

   # Describe PVC
   kubectl describe pvc <pvc-name>

   # Check StorageClass
   kubectl get storageclass

   # Check available PVs
   kubectl get pv
   ```

3. **Node Selector/Affinity Issues**
   ```bash
   # Check node labels
   kubectl get nodes --show-labels

   # Check pod node selector
   kubectl get pod <pod-name> -o jsonpath='{.spec.nodeSelector}'

   # Remove node selector if problematic
   kubectl edit pod <pod-name>
   ```

4. **Image Pull Issues**
   ```bash
   # Check image name
   kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].image}'

   # Try pulling image on node
   sudo k3s crictl pull <image-name>
   ```

### Pod Stuck in CrashLoopBackOff

**Symptoms:**
- Pod repeatedly crashes and restarts
- Status shows `CrashLoopBackOff` or `Error`

**Diagnosis:**
```bash
# Check pod status
kubectl get pod <pod-name>

# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Describe pod
kubectl describe pod <pod-name>
```

**Common Causes:**

1. **Application Error**
   ```bash
   # Check logs for errors
   kubectl logs <pod-name> --previous

   # Debug with shell (if pod stays up long enough)
   kubectl exec -it <pod-name> -- sh
   ```

2. **Missing Dependencies**
   ```bash
   # Check if dependent services are running
   kubectl get pods
   kubectl get services

   # Check environment variables
   kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].env}'
   ```

3. **Liveness Probe Failure**
   ```bash
   # Check probe configuration
   kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].livenessProbe}'

   # Adjust probe timing
   kubectl edit deployment <name>
   ```

4. **Resource Limits**
   ```bash
   # Check if pod is OOMKilled
   kubectl describe pod <pod-name> | grep -A 5 "Last State"

   # Increase memory limits
   kubectl edit deployment <name>
   ```

### Pod Stuck in ImagePullBackOff

**Symptoms:**
- Pod cannot pull container image
- Status shows `ImagePullBackOff` or `ErrImagePull`

**Diagnosis:**
```bash
# Describe pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --field-selector involvedObject.name=<pod-name>
```

**Solutions:**

1. **Incorrect Image Name**
   ```bash
   # Verify image exists
   docker search <image-name>

   # Check image in pod spec
   kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].image}'

   # Update image
   kubectl set image deployment/<name> <container>=<correct-image>
   ```

2. **Private Registry Authentication**
   ```bash
   # Create docker registry secret
   kubectl create secret docker-registry regcred \
     --docker-server=<registry> \
     --docker-username=<user> \
     --docker-password=<password> \
     --docker-email=<email>

   # Add to deployment
   kubectl patch deployment <name> -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"regcred"}]}}}}'
   ```

3. **Network Issues**
   ```bash
   # Test from node
   sudo k3s crictl pull <image-name>

   # Check proxy settings
   echo $HTTP_PROXY
   echo $HTTPS_PROXY
   ```

4. **Rate Limiting (Docker Hub)**
   ```bash
   # Authenticate to increase rate limit
   kubectl create secret docker-registry dockerhub \
     --docker-server=docker.io \
     --docker-username=<user> \
     --docker-password=<password>
   ```

### Pod Stuck in Terminating

**Symptoms:**
- Pod remains in `Terminating` state
- Pod won't delete

**Solutions:**

1. **Wait for Grace Period**
   ```bash
   # Check termination grace period
   kubectl get pod <pod-name> -o jsonpath='{.spec.terminationGracePeriodSeconds}'

   # Wait or reduce grace period
   kubectl delete pod <pod-name> --grace-period=0
   ```

2. **Force Delete**
   ```bash
   # Force delete (use with caution)
   kubectl delete pod <pod-name> --force --grace-period=0
   ```

3. **Finalizers Issue**
   ```bash
   # Check for finalizers
   kubectl get pod <pod-name> -o jsonpath='{.metadata.finalizers}'

   # Remove finalizers (advanced)
   kubectl patch pod <pod-name> -p '{"metadata":{"finalizers":null}}'
   ```

4. **Node Down**
   ```bash
   # If node is down, delete pod forcefully
   kubectl delete pod <pod-name> --force --grace-period=0
   ```

## Service and Networking Issues

### Cannot Access Service

**Symptoms:**
- Service not reachable from outside
- Connection timeouts or refused

**Diagnosis:**
```bash
# Check service
kubectl get svc <service-name>
kubectl describe svc <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Check pods
kubectl get pods -l <label-selector>
```

**Solutions:**

1. **No Endpoints**
   ```bash
   # Verify pod labels match service selector
   kubectl get svc <service-name> -o jsonpath='{.spec.selector}'
   kubectl get pods --show-labels

   # Check if pods are ready
   kubectl get pods -l <label>
   ```

2. **Service Type Issues**
   ```bash
   # Check service type
   kubectl get svc <service-name> -o jsonpath='{.spec.type}'

   # Change to LoadBalancer
   kubectl patch svc <service-name> -p '{"spec":{"type":"LoadBalancer"}}'

   # Or use port-forward for testing
   kubectl port-forward svc/<service-name> 8080:80
   ```

3. **Port Configuration**
   ```bash
   # Verify ports
   kubectl get svc <service-name> -o jsonpath='{.spec.ports[*]}'

   # Check container port
   kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].ports[*]}'
   ```

### DNS Resolution Issues

**Symptoms:**
- Pods cannot resolve service names
- DNS lookups fail

**Diagnosis:**
```bash
# Test DNS from pod
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**Solutions:**

1. **CoreDNS Not Running**
   ```bash
   # Restart CoreDNS
   kubectl rollout restart deployment coredns -n kube-system

   # Check for errors
   kubectl describe pod -n kube-system -l k8s-app=kube-dns
   ```

2. **DNS Configuration**
   ```bash
   # Check DNS policy
   kubectl get pod <pod-name> -o jsonpath='{.spec.dnsPolicy}'

   # Check resolv.conf
   kubectl exec <pod-name> -- cat /etc/resolv.conf
   ```

3. **Network Policy Blocking**
   ```bash
   # Check network policies
   kubectl get networkpolicies

   # Temporarily disable for testing
   kubectl delete networkpolicy <policy-name>
   ```

### Ingress Not Working

**Symptoms:**
- Cannot access application via ingress
- 404 or 503 errors

**Diagnosis:**
```bash
# Check ingress
kubectl get ingress
kubectl describe ingress <ingress-name>

# Check ingress controller
kubectl get pods -n kube-system -l app=traefik

# Check logs
kubectl logs -n kube-system -l app=traefik
```

**Solutions:**

1. **Ingress Controller Not Running**
   ```bash
   # Check Traefik (K3s default)
   kubectl get pods -n kube-system -l app=traefik

   # If disabled, reinstall K3s or install nginx-ingress
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
   ```

2. **Incorrect Host Configuration**
   ```bash
   # Check ingress host
   kubectl get ingress <ingress-name> -o jsonpath='{.spec.rules[*].host}'

   # Add to /etc/hosts
   echo "<node-ip> <hostname>" | sudo tee -a /etc/hosts
   ```

3. **Backend Service Issues**
   ```bash
   # Verify backend service exists
   kubectl get svc <backend-service>

   # Test service directly
   kubectl port-forward svc/<backend-service> 8080:80
   ```

## Storage Issues

### PVC Stuck in Pending

**Symptoms:**
- PVC remains in `Pending` state
- Pod cannot start due to volume issues

**Diagnosis:**
```bash
# Check PVC
kubectl get pvc
kubectl describe pvc <pvc-name>

# Check PV
kubectl get pv

# Check StorageClass
kubectl get storageclass
```

**Solutions:**

1. **No Storage Class**
   ```bash
   # Check default storage class
   kubectl get storageclass

   # K3s uses local-path by default
   # Manually specify storage class
   kubectl patch pvc <pvc-name> -p '{"spec":{"storageClassName":"local-path"}}'
   ```

2. **No Available PV**
   ```bash
   # For dynamic provisioning, check provisioner
   kubectl get storageclass <class-name> -o yaml

   # For static provisioning, create PV
   kubectl apply -f pv.yaml
   ```

3. **Insufficient Space**
   ```bash
   # Check node disk space
   df -h

   # Reduce PVC size or free up space
   kubectl edit pvc <pvc-name>
   ```

### Volume Mount Errors

**Symptoms:**
- Pod fails to start with volume mount errors
- `MountVolume.SetUp failed` in events

**Solutions:**

1. **Check Volume Definition**
   ```bash
   # Verify volume exists
   kubectl get pvc <pvc-name>

   # Check pod volume mounts
   kubectl get pod <pod-name> -o jsonpath='{.spec.volumes}'
   ```

2. **Permission Issues**
   ```bash
   # Check security context
   kubectl get pod <pod-name> -o jsonpath='{.spec.securityContext}'

   # Add fsGroup
   kubectl patch deployment <name> -p '{"spec":{"template":{"spec":{"securityContext":{"fsGroup":1000}}}}}'
   ```

## Performance Issues

### High CPU Usage

**Diagnosis:**
```bash
# Check node CPU
kubectl top nodes

# Check pod CPU
kubectl top pods --all-namespaces --sort-by=cpu

# Describe high-usage pods
kubectl describe pod <pod-name>
```

**Solutions:**

1. **Resource Limits**
   ```bash
   # Set CPU limits
   kubectl set resources deployment <name> -c=<container> --limits=cpu=500m
   ```

2. **Horizontal Scaling**
   ```bash
   # Scale up
   kubectl scale deployment <name> --replicas=3

   # Enable autoscaling
   kubectl autoscale deployment <name> --min=2 --max=10 --cpu-percent=70
   ```

### High Memory Usage

**Diagnosis:**
```bash
# Check memory
kubectl top nodes
kubectl top pods --all-namespaces --sort-by=memory

# Check for OOMKilled
kubectl get pods | grep OOMKilled
```

**Solutions:**

1. **Increase Memory Limits**
   ```bash
   kubectl set resources deployment <name> -c=<container> --limits=memory=512Mi
   ```

2. **Check for Memory Leaks**
   ```bash
   # Monitor over time
   kubectl top pod <pod-name>

   # Check application logs
   kubectl logs <pod-name>
   ```

## Security Issues

### RBAC Permission Denied

**Symptoms:**
- `Error from server (Forbidden): ...`
- Permission denied errors

**Solutions:**

```bash
# Check current permissions
kubectl auth can-i list pods
kubectl auth can-i create deployments

# Check service account
kubectl get serviceaccount
kubectl describe serviceaccount <sa-name>

# Check role bindings
kubectl get rolebindings
kubectl describe rolebinding <binding-name>

# Create role and binding
kubectl create role pod-reader --verb=get,list --resource=pods
kubectl create rolebinding pod-reader-binding --role=pod-reader --user=<user>
```

## Common Error Messages

### "error: You must be logged in to the server (Unauthorized)"

**Solution:**
```bash
# Check kubeconfig
echo $KUBECONFIG
cat ~/.kube/config

# Re-copy kubeconfig
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
```

### "Unable to connect to the server: dial tcp: lookup ... no such host"

**Solution:**
```bash
# Check server address in kubeconfig
kubectl config view

# Update server address
kubectl config set-cluster default --server=https://<correct-ip>:6443
```

### "error: error validating data: ValidationError"

**Solution:**
```bash
# Check YAML syntax
kubectl apply -f file.yaml --dry-run=client

# Validate with kubeval
kubeval file.yaml
```

## Getting Help

When seeking help, provide:

1. **Cluster Information**
   ```bash
   kubectl version
   kubectl cluster-info
   kubectl get nodes -o wide
   ```

2. **Problem Description**
   ```bash
   kubectl get all -A
   kubectl get events --sort-by='.lastTimestamp' | tail -20
   ```

3. **Relevant Logs**
   ```bash
   sudo journalctl -u k3s -n 100
   kubectl logs <pod-name>
   ```

4. **Resource Definitions**
   ```bash
   kubectl get <resource> <name> -o yaml
   ```

## Additional Resources

- [Kubernetes Debugging Guide](https://kubernetes.io/docs/tasks/debug/)
- [K3s GitHub Issues](https://github.com/k3s-io/k3s/issues)
- [Kubernetes Slack](https://slack.k8s.io/)
- [Stack Overflow Kubernetes](https://stackoverflow.com/questions/tagged/kubernetes)

## Next Steps

- [K3s Setup Guide](K3S-SETUP.md)
- [kubectl Guide](KUBECTL-GUIDE.md)
- Review examples in `examples/` directory
