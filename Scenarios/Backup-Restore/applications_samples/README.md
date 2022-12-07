## Samples for Nginx application with persistent volumes. 

Each sample uses a different storage class configuration to configure persistent volumes.

* provisioner: disk.csi.azure.com
  - azuredisk_csi_LRS.yaml  
  - azuredisk_csi_ZRS.yaml  

* provisioner: file.csi.azure.com
  - azurefile_csi_ZRS.yaml  

* provisioner: kubernetes.io/azure-file
  - azurefile_LRS.yaml  

* provisioner: kubernetes.io/azure-disk
  - statefulset-disk.yaml (statefulset)

In theses samples, a POD annotation is used to explicitly enable filesystem backup with Velero/Restic, for a disk mounted to the application / POD. 
```
kind: Pod
apiVersion: v1
metadata:
  namespace: file-lrs
  name: nginx-file-lrs
  annotations:
    backup.velero.io/backup-volumes: <volume-name>
```
- See https://velero.io/docs/v1.8/restic/#how-backup-and-restore-work-with-restic
- Use [Backup Hooks](https://velero.io/docs/v1.8/backup-hooks/) for freezing a file system, to ensure that all pending disk I/O operations have completed prior to taking a snapshot, 
