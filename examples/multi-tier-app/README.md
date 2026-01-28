# Multi-Tier Application Example

This example demonstrates a complete three-tier application architecture on Kubernetes, showcasing best practices for building scalable, production-ready applications.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Ingress / LoadBalancer              │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Frontend Tier (Nginx)                   │
│              - 2 replicas                            │
│              - Static content serving                │
│              - Reverse proxy to backend              │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│            Application Tier (Backend API)            │
│            - 3-10 replicas (auto-scaling)            │
│            - RESTful API                             │
│            - Business logic                          │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│              Database Tier (PostgreSQL)              │
│              - StatefulSet                           │
│              - Persistent storage                    │
│              - 5Gi volume                            │
└─────────────────────────────────────────────────────┘
```

## Features

- **Three-tier architecture**: Frontend, Backend, Database
- **Auto-scaling**: HPA for backend tier (3-10 replicas)
- **Persistent storage**: PostgreSQL with PVC
- **Service discovery**: Internal DNS for service communication
- **Health checks**: Liveness and readiness probes
- **Configuration management**: ConfigMaps and Secrets
- **Load balancing**: Automatic load distribution
- **Ingress routing**: HTTP routing to frontend

## Quick Start

Deploy the entire application:

```bash
# Deploy all components
kubectl apply -f examples/multi-tier-app/

# Watch the deployment
kubectl get pods -n multi-tier -w
```

## Step-by-Step Deployment

For a better understanding of the deployment process:

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Deploy database tier
kubectl apply -f database.yaml
kubectl wait --for=condition=ready pod -l app=postgres -n multi-tier --timeout=120s

# 3. Deploy application tier
kubectl apply -f backend.yaml
kubectl wait --for=condition=ready pod -l app=backend -n multi-tier --timeout=60s

# 4. Deploy frontend tier
kubectl apply -f frontend.yaml
```

## Accessing the Application

### Via LoadBalancer

Get the frontend service external IP:

```bash
kubectl get svc frontend -n multi-tier
```

Access at: `http://<EXTERNAL-IP>`

### Via Ingress

Add to `/etc/hosts`:

```bash
echo "$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}') app.local" | sudo tee -a /etc/hosts
```

Access at: `http://app.local`

## Testing the Application

### Test Frontend

```bash
curl http://app.local/
```

### Test Backend API

```bash
curl http://app.local/api/
```

Or click the "Test Backend API" button on the web interface.

### Test Database Connection

```bash
# Access PostgreSQL
kubectl exec -it postgres-0 -n multi-tier -- psql -U appuser -d appdb

# Inside psql:
\dt              # List tables
\l               # List databases
\q               # Quit
```

## Monitoring

### View All Resources

```bash
kubectl get all -n multi-tier
```

### Check Pod Status

```bash
# All pods
kubectl get pods -n multi-tier

# Specific tier
kubectl get pods -n multi-tier -l tier=application
kubectl get pods -n multi-tier -l tier=database
kubectl get pods -n multi-tier -l tier=presentation
```

### View Logs

```bash
# Frontend logs
kubectl logs -l app=frontend -n multi-tier

# Backend logs
kubectl logs -l app=backend -n multi-tier

# Database logs
kubectl logs postgres-0 -n multi-tier
```

### Check HPA Status

```bash
kubectl get hpa -n multi-tier
kubectl describe hpa backend-hpa -n multi-tier
```

## Scaling

### Manual Scaling

```bash
# Scale frontend
kubectl scale deployment frontend --replicas=3 -n multi-tier

# Scale backend (will be adjusted by HPA)
kubectl scale deployment backend --replicas=5 -n multi-tier
```

### Auto-scaling

The backend tier uses Horizontal Pod Autoscaler:
- **Min replicas**: 3
- **Max replicas**: 10
- **CPU target**: 70%
- **Memory target**: 80%

To test auto-scaling, generate load:

```bash
# Install hey (HTTP load generator)
# On macOS: brew install hey
# On Linux: download from https://github.com/rakyll/hey

# Generate load
hey -z 60s -c 50 http://app.local/api/
```

Watch scaling in action:

```bash
kubectl get hpa backend-hpa -n multi-tier -w
```

## Configuration

### Frontend Configuration

Edit nginx config in `frontend.yaml`:
- Modify `nginx.conf` in ConfigMap
- Apply changes: `kubectl apply -f frontend.yaml`
- Restart pods: `kubectl rollout restart deployment frontend -n multi-tier`

### Backend Configuration

Edit environment variables in `backend.yaml`:
- Update ConfigMap or Secret values
- Apply changes
- Pods will automatically reload configuration

### Database Configuration

PostgreSQL configuration via environment variables in `database.yaml`.

## Security Considerations

**Production Recommendations:**

1. **Secrets Management**
   - Use external secret managers (Vault, AWS Secrets Manager)
   - Rotate passwords regularly
   - Don't commit secrets to version control

2. **Network Policies**
   ```bash
   # Create network policies to restrict traffic
   # Frontend -> Backend only
   # Backend -> Database only
   ```

3. **Resource Limits**
   - All components have CPU/memory limits
   - Prevents resource exhaustion

4. **RBAC**
   - Create service accounts with minimal permissions
   - Use Pod Security Standards

5. **TLS/HTTPS**
   - Enable TLS for ingress
   - Use cert-manager for certificate management

6. **Database Security**
   - Use strong passwords
   - Enable SSL connections
   - Regular backups
   - Implement backup strategy

## Backup and Disaster Recovery

### Backup Database

```bash
# Create backup
kubectl exec postgres-0 -n multi-tier -- pg_dump -U appuser appdb > backup.sql

# Or use pg_dumpall for all databases
kubectl exec postgres-0 -n multi-tier -- pg_dumpall -U appuser > backup-all.sql
```

### Restore Database

```bash
# Restore from backup
kubectl exec -i postgres-0 -n multi-tier -- psql -U appuser appdb < backup.sql
```

### Backup Persistent Volumes

```bash
# Get PVC details
kubectl get pvc -n multi-tier

# Create volume snapshot (if supported by storage class)
kubectl create volumesnapshot postgres-snapshot --volumesnapshotclass=<class-name> --source=postgres-pvc -n multi-tier
```

## Troubleshooting

### Frontend can't reach backend

Check service discovery:
```bash
kubectl exec -it $(kubectl get pod -n multi-tier -l app=frontend -o jsonpath='{.items[0].metadata.name}') -n multi-tier -- nslookup backend
```

### Backend can't connect to database

Verify database is running:
```bash
kubectl get pods -n multi-tier -l app=postgres
kubectl logs postgres-0 -n multi-tier
```

Test connection:
```bash
kubectl exec -it $(kubectl get pod -n multi-tier -l app=backend -o jsonpath='{.items[0].metadata.name}') -n multi-tier -- nc -zv postgres 5432
```

### Pods not starting

Check events:
```bash
kubectl describe pod <pod-name> -n multi-tier
kubectl get events -n multi-tier --sort-by='.lastTimestamp'
```

### Storage issues

Check PVC status:
```bash
kubectl get pvc -n multi-tier
kubectl describe pvc postgres-pvc -n multi-tier
```

## Performance Optimization

1. **Enable connection pooling** in backend
2. **Use Redis** for caching (add as additional tier)
3. **Optimize database queries** and add indexes
4. **Enable CDN** for static assets
5. **Configure resource requests/limits** appropriately
6. **Use Pod Disruption Budgets** for high availability

## Advanced Topics

### Adding Redis Cache Tier

Create a `redis.yaml` file and deploy between frontend and backend for caching.

### Adding Message Queue

Deploy RabbitMQ or Kafka for asynchronous processing.

### Implementing CI/CD

Use GitHub Actions, GitLab CI, or Jenkins to automate deployments.

### Service Mesh

Consider Istio or Linkerd for advanced traffic management.

## Cleanup

Remove the entire application:

```bash
kubectl delete namespace multi-tier
```

This will delete all resources including persistent volumes.

## Next Steps

1. Customize the application with your own code
2. Add monitoring (integrate with Prometheus/Grafana)
3. Implement logging aggregation (ELK stack)
4. Add distributed tracing (Jaeger, Zipkin)
5. Set up CI/CD pipeline
6. Implement GitOps with ArgoCD or Flux

## Resources

- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [12-Factor App Methodology](https://12factor.net/)
- [Cloud Native Patterns](https://www.manning.com/books/cloud-native-patterns)
