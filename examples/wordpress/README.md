# WordPress on Kubernetes

This example demonstrates how to deploy a complete WordPress application with MySQL database on your K3s cluster.

## Architecture

- **WordPress**: 2 replicas for high availability
- **MySQL**: Single instance with persistent storage
- **Persistent Storage**: Uses K3s local-path provisioner
- **Ingress**: Traefik ingress controller for HTTP routing

## Deployment

### Quick Start

Deploy the entire WordPress stack:

```bash
kubectl apply -f examples/wordpress/
```

This will create:
- `wordpress` namespace
- MySQL deployment with persistent storage
- WordPress deployment with persistent storage
- Services for both MySQL and WordPress
- Ingress for external access

### Step-by-Step Deployment

If you prefer to deploy components individually:

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Deploy MySQL
kubectl apply -f mysql-secret.yaml
kubectl apply -f mysql-pvc.yaml
kubectl apply -f mysql-deployment.yaml

# Wait for MySQL to be ready
kubectl wait --for=condition=ready pod -l app=mysql -n wordpress --timeout=120s

# Deploy WordPress
kubectl apply -f wordpress-pvc.yaml
kubectl apply -f wordpress-deployment.yaml
```

## Accessing WordPress

### Via LoadBalancer

Get the external IP:

```bash
kubectl get svc wordpress -n wordpress
```

Access WordPress at `http://<EXTERNAL-IP>`

### Via Ingress

Add to your `/etc/hosts` file:

```bash
echo "$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}') wordpress.local" | sudo tee -a /etc/hosts
```

Access WordPress at `http://wordpress.local`

## Monitoring

Check deployment status:

```bash
# View all resources
kubectl get all -n wordpress

# Check pod logs
kubectl logs -l app=wordpress -n wordpress
kubectl logs -l app=mysql -n wordpress

# Describe pods for troubleshooting
kubectl describe pod -l app=wordpress -n wordpress
```

## Scaling WordPress

Scale the WordPress deployment:

```bash
kubectl scale deployment wordpress --replicas=3 -n wordpress
```

Note: MySQL should remain as a single instance for this simple setup.

## Persistent Data

Data is stored in Persistent Volume Claims:
- MySQL data: `/var/lib/mysql`
- WordPress files: `/var/www/html`

View PVCs:

```bash
kubectl get pvc -n wordpress
```

## Security Notes

**WARNING**: This is a demo setup. For production use:

1. Change the default passwords in `mysql-secret.yaml`
2. Use a proper secret management solution (e.g., Sealed Secrets, External Secrets Operator)
3. Enable TLS/HTTPS with cert-manager
4. Configure database backups
5. Use a StatefulSet for MySQL with replication
6. Implement network policies
7. Enable resource quotas and limits

## Backup and Restore

### Backup MySQL Data

```bash
kubectl exec -n wordpress $(kubectl get pod -n wordpress -l app=mysql -o jsonpath='{.items[0].metadata.name}') -- \
  mysqldump -u wordpress -pwordpress123 wordpress > wordpress-backup.sql
```

### Restore MySQL Data

```bash
kubectl exec -i -n wordpress $(kubectl get pod -n wordpress -l app=mysql -o jsonpath='{.items[0].metadata.name}') -- \
  mysql -u wordpress -pwordpress123 wordpress < wordpress-backup.sql
```

## Cleanup

Remove all WordPress resources:

```bash
kubectl delete namespace wordpress
```

Note: This will delete all data including the persistent volumes.

## Troubleshooting

### WordPress pods not starting

Check MySQL is ready:
```bash
kubectl get pods -n wordpress -l app=mysql
```

### Database connection errors

Verify the secret:
```bash
kubectl get secret mysql-secret -n wordpress -o yaml
```

### Storage issues

Check PVC status:
```bash
kubectl get pvc -n wordpress
kubectl describe pvc mysql-pvc -n wordpress
```

For more troubleshooting tips, see [documentation/TROUBLESHOOTING.md](../../documentation/TROUBLESHOOTING.md)
