# AKS Istio Service Mesh Scenario

This scenario deploys an AKS cluster with the **Istio service mesh add-on** enabled, demonstrating secure service-to-service communication, ingress routing, mTLS enforcement, and observability integration.

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│                    Azure Subscription                    │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Resource Group                        │  │
│  │                                                    │  │
│  │  ┌──────────────┐   ┌──────────────────────────┐  │  │
│  │  │   VNet       │   │  Log Analytics Workspace  │  │  │
│  │  │  ┌────────┐  │   └──────────────────────────┘  │  │
│  │  │  │  AKS   │  │                                  │  │
│  │  │  │ Subnet │  │                                  │  │
│  │  │  └────────┘  │                                  │  │
│  │  └──────────────┘                                  │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────────────────────┐  │  │
│  │  │           AKS Cluster                         │  │  │
│  │  │                                               │  │  │
│  │  │  ┌─────────────┐  ┌────────────────────────┐ │  │  │
│  │  │  │ istio-system │  │   istio-ingress        │ │  │  │
│  │  │  │   istiod     │  │  Internal LB Gateway   │ │  │  │
│  │  │  └─────────────┘  └────────────────────────┘ │  │  │
│  │  │                          │                    │  │  │
│  │  │                    ┌─────▼──────┐             │  │  │
│  │  │                    │ sample-app │             │  │  │
│  │  │                    │            │             │  │  │
│  │  │                    │ frontend ◄─► backend    │  │  │
│  │  │                    │   (mTLS between pods)   │  │  │
│  │  │                    └────────────┘             │  │  │
│  │  └──────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## What gets deployed

| Resource | Description |
| -------- | ----------- |
| Resource Group | Container for all resources |
| Virtual Network + NSG | Network with AKS subnet |
| AKS Cluster | With Istio add-on, Azure CNI + Cilium, OIDC, Workload Identity |
| Istio Service Mesh | Managed istiod control plane + internal ingress gateway |
| Log Analytics Workspace | For AKS monitoring and Istio telemetry |

## Prerequisites

* Azure subscription with Contributor access
* Azure CLI 2.60+ with `aks-preview` extension
* `kubectl` and `kubelogin` installed
* An Entra ID security group for AKS admins

## Deployment

### Step 1: Deploy infrastructure

```bash
REGION=eastus
ADMIN_GROUP_ID=<your-entra-id-group-object-id>

az deployment sub create \
  -n "AKS-Istio-Mesh" \
  -l $REGION \
  -f main.bicep \
  -p aksAdminsGroupId=$ADMIN_GROUP_ID
```

### Step 2: Connect to the cluster

```bash
RG=AKS-Istio-Mesh-RG
CLUSTER=aks-istio-mesh

az aks get-credentials --name $CLUSTER --resource-group $RG
```

### Step 3: Verify Istio is running

```bash
# Check istiod pods
kubectl get pods -n aks-istio-system

# Check the internal ingress gateway
kubectl get svc -n aks-istio-ingress

# Verify the Istio revision
kubectl get mutatingwebhookconfigurations -l app=sidecar-injector
```

### Step 4: Enable strict mTLS mesh-wide

```bash
kubectl apply -f manifests/peer-authentication.yaml
```

This enforces mutual TLS for all service-to-service communication in the mesh.

### Step 5: Deploy the Istio ingress gateway

```bash
kubectl apply -f manifests/gateway.yaml
```

### Step 6: Deploy the sample application

```bash
kubectl apply -f manifests/sample-app.yaml
```

This creates:

* A `sample-app` namespace with Istio sidecar injection enabled
* A `frontend` and `backend` service with Envoy sidecar proxies
* A `VirtualService` routing ingress traffic to the frontend
* A `DestinationRule` enforcing ISTIO_MUTUAL TLS to the backend

### Step 7: Verify mTLS is working

```bash
# Check pods have sidecar injected (2/2 containers)
kubectl get pods -n sample-app

# Verify mTLS between services
kubectl exec -n sample-app deploy/frontend -c frontend -- \
  curl -s http://backend.sample-app.svc.cluster.local

# Check the Istio proxy config
kubectl exec -n sample-app deploy/frontend -c istio-proxy -- \
  pilot-agent request GET /clusters | grep backend
```

### Step 8: Enable Istio metrics collection (optional)

If using Azure Managed Prometheus, Istio metrics are auto-collected. For custom scraping:

```bash
kubectl apply -f manifests/prometheus-config.yaml
```

## Observability

### Azure Monitor integration

The cluster is deployed with the OMS agent enabled, sending logs and metrics to Log Analytics. Key Istio metrics available:

* **istio_requests_total** — Request count by source/destination
* **istio_request_duration_milliseconds** — Latency distribution
* **istio_tcp_connections_opened_total** — TCP connection metrics

### Grafana dashboards

Import the [Istio Mesh Dashboard](https://grafana.com/grafana/dashboards/7639-istio-mesh-dashboard/) (ID: 7639) and [Istio Service Dashboard](https://grafana.com/grafana/dashboards/7636-istio-service-dashboard/) (ID: 7636) into your Grafana instance.

## North-South Ingress Options

| Option | Pros | Cons |
| ------ | ---- | ---- |
| **Istio Internal Gateway + App Gateway** | WAF protection, SSL offload, familiar Azure pattern | Extra hop, two ingress layers |
| **Istio Internal Gateway + Azure Front Door** | Global load balancing, edge caching, DDoS protection | More complex DNS, higher cost |
| **Istio External Gateway (direct)** | Simplest setup, no extra components | No WAF, limited DDoS protection |

This scenario uses the **Internal Istio Gateway** pattern. To expose externally, place an Application Gateway or Azure Front Door in front and route to the internal gateway's private IP.

## Multi-Cluster Istio Mesh

The AKS Istio add-on supports multi-cluster mesh with shared trust domain. To set up:

1. **Deploy a second AKS cluster** with the same Istio revision and a shared root CA (using Key Vault certificate authority plugin — see the `certificateAuthority` parameter in the AVM module)
2. **Peer the VNets** between clusters
3. **Enable multi-cluster discovery** using Istio's remote secret mechanism:

   ```bash
   # On cluster 1, create a remote secret for cluster 2
   istioctl create-remote-secret --name=cluster2 | kubectl apply -f - --context=cluster1

   # On cluster 2, create a remote secret for cluster 1
   istioctl create-remote-secret --name=cluster1 | kubectl apply -f - --context=cluster2
   ```

4. Services with the same name/namespace across clusters will automatically load-balance

For a full multi-cluster setup with shared CA via Key Vault, refer to the [AKS Istio add-on multi-cluster documentation](https://learn.microsoft.com/azure/aks/istio-multicluster).

## Clean up

```bash
az group delete --name AKS-Istio-Mesh-RG --yes --no-wait
```
