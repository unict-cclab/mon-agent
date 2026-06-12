# mon-agent

`mon-agent` is a small Kubernetes agent that combines Prometheus metric
collection and Kubernetes annotation updates in one process.

It does not define CRDs and does not run a controller-runtime operator. It loops
on a fixed period, queries Prometheus directly, and patches annotations on:

- all cluster nodes
- deployments in namespaces selected by `NAMESPACE_LABEL_SELECTOR`

The selected application namespaces must be labeled so the agent knows where to
look for deployments. For the default manifests, label each application namespace
with:

```bash
kubectl label namespace default mon-agent/enabled=true
```

The deployments in those namespaces should use the standard `group` and `app`
labels. The agent uses those labels, exposed in Prometheus as `label_group` and
`label_app`, to aggregate CPU and memory usage per deployment.

## Configuration

| Environment variable | Default | Description |
| --- | --- | --- |
| `PROMETHEUS_URL` | `http://prometheus-stack-kube-prom-prometheus.observability:9090` | Prometheus HTTP API base URL |
| `SCRAPE_PERIOD_SECONDS` | `30` | Loop period in seconds |
| `PROMQL_RANGE` | `5m` | Range window used in `rate(...)` queries |
| `NAMESPACE_LABEL_SELECTOR` | empty | Kubernetes label selector for namespaces that contain deployments to annotate |
| `KUBECONFIG` | in-cluster config, then `~/.kube/config` | Optional local kubeconfig for development |

## Annotations

Nodes:

- `cpu-usage`: CPU cores
- `memory-usage`: MiB
- `network-latency.<destination-node>`: milliseconds

Deployments:

- `cpu-usage`: CPU cores
- `memory-usage`: MiB
- `rps.<peer-workload>`: requests per second
- `traffic.<peer-workload>`: bytes per second

Deployment CPU and memory are grouped by the current Kubernetes `group` and
`app` labels. In Prometheus those labels are exposed by kube-state-metrics as
`label_group` and `label_app`.

Istio traffic annotations use standard Istio workload labels such as
`source_workload`, `destination_workload`, and their namespaces.

## Build

```bash
go build -buildvcs=false
```

Build and push a container image:

```bash
make build-image IMG=ghcr.io/<owner>/mon-agent:v0.1.0
make push-image IMG=ghcr.io/<owner>/mon-agent:v0.1.0
```

## Run Locally

```bash
export PROMETHEUS_URL=http://localhost:9090
export NAMESPACE_LABEL_SELECTOR='mon-agent/enabled=true'
export SCRAPE_PERIOD_SECONDS=30
go run .
```

## Kubernetes

Install the service account, RBAC, and deployment:

```bash
kubectl apply -f config/kubernetes/rbac.yaml
kubectl apply -f config/kubernetes/deployment.yaml
```

Then label every namespace that contains application deployments to annotate:

```bash
kubectl label namespace <application-namespace> mon-agent/enabled=true
```

If your Prometheus service or namespace selector differs from the defaults, edit
`config/kubernetes/deployment.yaml` before applying it.

## Release

The GitHub Actions release pipeline builds and pushes an image to GHCR whenever
a tag matching `v*` is pushed:

```bash
git tag v0.1.0
git push origin v0.1.0
```
