apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: openaiapikey
  namespace: default
spec:
  parameters:
    clientID: <identity clientID>
    keyvaultName: <kv name>
    objects: |
      array:
        - |
          objectName: openaiapikey
          objectType: secret
        - |
          objectName: formrecognizerkey
          objectType: secret
        - |
          objectName: translatekey
          objectType: secret
        - |
          objectName: blobaccountkey
          objectType: secret
    tenantId: <tenant ID>
  provider: azure
  secretObjects:
  - data:
    - key: openaiapikey
      objectName: openaiapikey
    - key: formrecognizerkey
      objectName: formrecognizerkey
    - key: translatekey
      objectName: translatekey
    - key: blobaccountkey
      objectName: blobaccountkey
    secretName: openaiapikey
    type: Opaque