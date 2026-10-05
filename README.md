<p align="center">
  <img src="hero.svg" width="100%" alt="Running install-k3s.sh brings up a K3s cluster — a control-plane node and two agents — then kubectl apply turns the pods green.">
</p>

<h1 align="center">Deploying Your First Kubernetes Cluster</h1>

<p align="center"><b>A production-ready Kubernetes cluster with K3s — in minutes.</b> Install scripts, core manifests, and three runnable example stacks to learn from. K3s is a lightweight, certified Kubernetes in a single binary.</p>

<p align="center">
  <img src="https://img.shields.io/badge/K3s-lightweight%20K8s-ffc61c" alt="K3s">
  <img src="https://img.shields.io/badge/kubectl-ready-326ce5" alt="kubectl">
  <img src="https://img.shields.io/badge/examples-3%20stacks-3ddc84" alt="3 example stacks">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-8b96ad" alt="MIT"></a>
</p>

---

## Quick start

```bash
git clone https://github.com/ry-ops/deploying-your-first-kubernetes-cluster.git
cd deploying-your-first-kubernetes-cluster

./scripts/install-k3s.sh      # install K3s (single binary, ~512MB RAM)
./scripts/setup-kubectl.sh    # point kubectl at the new cluster
kubectl apply -f manifests/   # deploy the sample app
```

```bash
kubectl get nodes      # control-plane + agents, Ready
kubectl get pods -A    # system + your pods
```

Add agents by running the installer in worker mode, and skip Traefik if you'd rather bring your own ingress — see [K3S-SETUP.md](documentation/K3S-SETUP.md).

## What you can deploy

<p align="center">
  <img src="docs/examples.svg" width="100%" alt="Core manifests (deployment, service, ingress, configmap) plus three example stacks: monitoring (Prometheus + Grafana), a multi-tier app (frontend, backend, database), and WordPress with MySQL and a PVC.">
</p>

- **Core manifests** (`manifests/`) — `deployment`, `service`, `ingress`, `configmap` to learn the basics.
- **Monitoring** (`examples/monitoring/`) — Prometheus + Grafana.
- **Multi-tier app** (`examples/multi-tier-app/`) — frontend, backend, database.
- **WordPress** (`examples/wordpress/`) — a stateful app with MySQL and a persistent volume.

Each example has its own README and applies with `kubectl apply -f examples/<name>/`.

## Learn more

- [K3S-SETUP.md](documentation/K3S-SETUP.md) — installation options, HA, workers
- [KUBECTL-GUIDE.md](documentation/KUBECTL-GUIDE.md) — the commands you'll use daily
- [TROUBLESHOOTING.md](documentation/TROUBLESHOOTING.md) — when things don't come up

## License

MIT. See [LICENSE](LICENSE).

<!-- org-footer -->
---

<p align="center"><sub>Part of <a href="https://github.com/ry-ops">ry-ops</a> · building the pipes between infrastructure, automation, and observability · built by <a href="https://github.com/ry-ops">ry-ops</a></sub></p>
