apiVersion: v1
kind: ServiceAccount
metadata:
  name: serversa
  namespace: default
  annotations:
    azure.workload.identity/client-id: <identity clientID>
    azure.workload.identity/tenant-id: <tenant ID>
  labels:
    azure.workload.identity/use: "true"
