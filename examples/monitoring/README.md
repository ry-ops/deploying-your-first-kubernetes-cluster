# Monitoring Stack with Prometheus and Grafana

This example deploys a complete monitoring solution using Prometheus for metrics collection and Grafana for visualization.

## Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Persistent Storage**: Data retention across pod restarts

## Quick Start

Deploy the entire monitoring stack:

```bash
kubectl apply -f examples/monitoring/
```

## Access the Dashboards

### Grafana

#### Via LoadBalancer

Get the external IP:
```bash
kubectl get svc grafana -n monitoring
```

Access at: `http://<EXTERNAL-IP>:3000`

#### Via Ingress

Add to `/etc/hosts`:
```bash
echo "$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}') grafana.local" | sudo tee -a /etc/hosts
```

Access at: `http://grafana.local`

**Default Credentials:**
- Username: `admin`
- Password: `admin`

Change the password on first login.

### Prometheus

Port-forward to access Prometheus UI:
```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Access at: `http://localhost:9090`

## Using Grafana

### First Login

1. Navigate to Grafana URL
2. Login with default credentials
3. Change the admin password when prompted

### Import Dashboards

Grafana includes many pre-built dashboards for Kubernetes:

1. Click **+** (Create) → **Import**
2. Enter dashboard ID from [Grafana Dashboard Library](https://grafana.com/grafana/dashboards/)

**Recommended Dashboards:**
- **315**: Kubernetes cluster monitoring
- **8588**: Kubernetes Deployment Statefulset DaemonSet metrics
- **6417**: Kubernetes Cluster (Prometheus)
- **7249**: Kubernetes Cluster
- **3662**: Prometheus 2.0 Stats

### Create Custom Dashboards

1. Click **+** (Create) → **Dashboard**
2. Add panels with PromQL queries
3. Save the dashboard

**Example PromQL Queries:**

CPU usage:
```promql
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)
```

Memory usage:
```promql
sum(container_memory_usage_bytes) by (pod)
```

Pod count:
```promql
count(kube_pod_info)
```

## Monitoring Your Applications

To make your applications visible to Prometheus, add annotations to your pods:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
spec:
  containers:
  - name: my-app
    image: my-app:latest
```

## Configuration

### Prometheus

Prometheus configuration is stored in the `prometheus-config` ConfigMap. To modify:

1. Edit `prometheus-config.yaml`
2. Apply changes:
   ```bash
   kubectl apply -f prometheus-config.yaml
   ```
3. Reload Prometheus:
   ```bash
   kubectl exec -n monitoring $(kubectl get pod -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}') -- kill -HUP 1
   ```

### Grafana

Grafana datasources are configured automatically via the `grafana-datasources` ConfigMap.

## Storage

Both Prometheus and Grafana use persistent volumes:

- **Prometheus**: 10Gi (30 days retention)
- **Grafana**: 5Gi (dashboards and settings)

View PVCs:
```bash
kubectl get pvc -n monitoring
```

## Scaling Considerations

### Prometheus

For larger clusters, consider:
- Increasing storage size
- Adjusting retention time
- Using remote storage (e.g., Thanos, Cortex)
- Implementing Prometheus federation

### Grafana

Grafana can be scaled horizontally:
```bash
kubectl scale deployment grafana --replicas=2 -n monitoring
```

## Troubleshooting

### Prometheus not scraping targets

Check targets in Prometheus UI:
```
http://localhost:9090/targets
```

### Grafana can't connect to Prometheus

Verify Prometheus service:
```bash
kubectl get svc prometheus -n monitoring
```

Test connectivity from Grafana pod:
```bash
kubectl exec -n monitoring $(kubectl get pod -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}') -- wget -O- http://prometheus:9090/-/healthy
```

### Storage issues

Check PVC status:
```bash
kubectl describe pvc prometheus-pvc -n monitoring
kubectl describe pvc grafana-pvc -n monitoring
```

## Security Considerations

**Production Recommendations:**

1. Change default Grafana credentials
2. Enable HTTPS with TLS certificates
3. Configure authentication (LDAP, OAuth, etc.)
4. Implement RBAC for Grafana users
5. Use secrets for sensitive configuration
6. Enable Prometheus authentication
7. Configure network policies

## Backup

### Backup Grafana Dashboards

Export dashboards via UI or use the API:
```bash
curl -u admin:admin http://grafana-url/api/search?query=& | \
  jq -r '.[] | .uid' | \
  xargs -I{} curl -u admin:admin http://grafana-url/api/dashboards/uid/{} > {}.json
```

### Backup Prometheus Data

Prometheus data is in the PVC. Create a backup of the PV:
```bash
kubectl exec -n monitoring $(kubectl get pod -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}') -- tar czf /tmp/prometheus-backup.tar.gz /prometheus
kubectl cp monitoring/$(kubectl get pod -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}'):/tmp/prometheus-backup.tar.gz ./prometheus-backup.tar.gz
```

## Cleanup

Remove the monitoring stack:
```bash
kubectl delete namespace monitoring
```

## Advanced Configuration

### Adding Node Exporter

For detailed node metrics, deploy node-exporter as a DaemonSet:

```bash
# Create a node-exporter.yaml file and apply
kubectl apply -f node-exporter.yaml
```

### Alert Manager

To add alerting capabilities, deploy AlertManager alongside Prometheus.

### Service Monitors

For more advanced Prometheus configuration, consider using the Prometheus Operator with ServiceMonitor CRDs.

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Kubernetes Monitoring Guide](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
