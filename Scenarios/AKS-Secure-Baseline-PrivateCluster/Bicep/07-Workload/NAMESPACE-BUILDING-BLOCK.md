# Namespace Building Block

A reusable Bicep module that provisions fully configured Kubernetes namespaces via GitOps, with ingress, RBAC, and network policy built in.

## Architecture

```text
┌──────────────────────────────────────────────────────────────┐
│                      Bicep Deployment                        │
│                                                              │
│  namespace-building-block.bicep                              │
│    ├── Flux Extension (AVM kubernetes-configuration/ext)     │
│    └── FluxConfiguration (AVM kubernetes-configuration/flux) │
│              │                                               │
│              ▼                                               │
│    ┌─────────────────┐                                       │
│    │  Git Repository  │◄── Platform team manages manifests   │
│    │  /namespaces/    │                                       │
│    │    team-orders/  │                                       │
│    │    team-frontend/│                                       │
│    └────────┬────────┘                                       │
│             │ Flux reconciles                                │
│             ▼                                                │
│    ┌─────────────────────────────────────────┐               │
│    │            AKS Cluster                   │               │
│    │                                          │               │
│    │  ┌─────────────┐  ┌─────────────┐       │               │
│    │  │ team-orders  │  │team-frontend│       │               │
│    │  │  Namespace   │  │  Namespace  │       │               │
│    │  │  RBAC Roles  │  │  RBAC Roles │       │               │
│    │  │  NetworkPol  │  │  NetworkPol │       │               │
│    │  │  Istio GW    │  │  Istio GW   │       │               │
│    │  └─────────────┘  └─────────────┘       │               │
│    └─────────────────────────────────────────┘               │
└──────────────────────────────────────────────────────────────┘
```

## What each namespace gets

| Resource | Purpose |
| -------- | ------- |
| **Namespace** | K8s namespace with Istio sidecar injection label |
| **Role + RoleBinding** | Delegated admin access for the team's Entra ID group |
| **Role + RoleBinding (viewer)** | Read-only access for observers |
| **NetworkPolicy** | Default-deny ingress with exceptions for Istio gateway and same-namespace |
| **Istio Gateway** | Namespace-scoped ingress via the AKS Istio add-on internal gateway |

## How it works

1. **Platform engineer** calls `namespace-building-block.bicep` from Bicep, passing the AKS cluster name, namespace name, and Git repo URL
2. **Bicep** installs the Flux extension (if needed) and creates a `FluxConfiguration` pointing to the Git repo path for that namespace
3. **Flux** continuously reconciles the Kubernetes manifests from the Git repo — creating the Namespace, RBAC, NetworkPolicy, and Istio Gateway
4. **Teams** get self-service access to their namespace, scoped by the RBAC roles

## Usage

### Prerequisites

* AKS cluster deployed (e.g., from the Secure Baseline scenario)
* A Git repository accessible from the cluster (public or with credentials)
* Namespace manifest templates committed to the Git repo (see `namespace-templates/` for examples)

### Step 1: Prepare your Git repository

Copy the `namespace-templates/` directory to your platform config Git repo. For each team namespace, create a directory under `namespaces/`:

```text
platform-config/
  namespaces/
    team-orders/
      kustomization.yaml
      namespace.yaml      # Replace NAMESPACE_NAME → team-orders
      rbac.yaml            # Replace TEAM_GROUP_ID → Entra ID group
      network-policy.yaml  # Replace NAMESPACE_NAME → team-orders
      gateway.yaml         # Replace NAMESPACE_NAME → team-orders
    team-frontend/
      ...
```

Replace the placeholders in each file:

* `NAMESPACE_NAME` → actual namespace name (e.g., `team-orders`)
* `ISTIO_REVISION` → your Istio revision (e.g., `asm-1-27`)
* `TEAM_GROUP_ID` → Entra ID group object ID for namespace admins
* `VIEWER_GROUP_ID` → Entra ID group object ID for read-only access

### Step 2: Deploy the building block

```bash
az deployment sub create \
  -n "namespace-onboarding" \
  -l $REGION \
  -f example-namespace-onboarding.bicep \
  -p rgName=$SPOKERG \
  -p aksClusterName=$AKSCLUSTERNAME \
  -p gitRepositoryUrl=https://github.com/<org>/platform-config
```

Or call the module directly for a single namespace:

```bash
az deployment group create \
  -g $SPOKERG \
  -f namespace-building-block.bicep \
  -p aksClusterName=$AKSCLUSTERNAME \
  -p namespaceName=team-orders \
  -p gitRepositoryUrl=https://github.com/<org>/platform-config
```

### Step 3: Verify

```bash
# Check Flux is running
kubectl get pods -n flux-system

# Check the FluxConfiguration
kubectl get fluxconfigs -A

# Verify the namespace was created with Istio injection
kubectl get ns team-orders --show-labels

# Verify RBAC
kubectl get roles,rolebindings -n team-orders

# Verify NetworkPolicy
kubectl get networkpolicies -n team-orders
```

## Module Parameters

| Parameter | Type | Default | Description |
| --------- | ---- | ------- | ----------- |
| `aksClusterName` | string | (required) | Name of the AKS cluster |
| `namespaceName` | string | (required) | Kubernetes namespace to provision |
| `gitRepositoryUrl` | string | (required) | Git repo URL with namespace manifests |
| `gitBranch` | string | `main` | Git branch to reconcile |
| `gitPath` | string | `./namespaces/{name}` | Path in the repo for this namespace |
| `syncInterval` | string | `PT5M` | GitOps sync interval |
| `installFluxExtension` | bool | `true` | Whether to install Flux (set false if already installed) |
| `enablePrune` | bool | `true` | Prune resources removed from Git |

## Adding a new team namespace

1. Create a new directory in your Git repo: `namespaces/<team-name>/`
2. Copy the templates and replace placeholders
3. Add another entry to the `namespaces` array in `example-namespace-onboarding.bicep` (or call the module directly)
4. Deploy — Flux will automatically reconcile the new namespace

## Private Git repositories

For private repos, add credentials to the Flux configuration. Update the `fluxConfig` module in `namespace-building-block.bicep`:

```bicep
configurationProtectedSettings: {
  username: '<git-username>'
  password: '<git-pat-or-token>'
}
```

Or use SSH keys / Azure DevOps managed identity integration.
