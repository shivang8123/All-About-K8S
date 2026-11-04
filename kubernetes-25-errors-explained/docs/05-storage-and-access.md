# Storage & Access

Volumes will not bind or mount, and API access is denied.

[Back to README](../README.md)

---

## 21. PVC Pending

**In plain English:** No volume or StorageClass can satisfy the claim.

**Common causes**

- StorageClass name does not exist
- No default StorageClass
- No PV matches size/access mode
- Provisioner or CSI driver not working
- `WaitForFirstConsumer` mode: normal until a pod uses the claim

**How to diagnose**

```bash
kubectl describe pvc <pvc> -n <namespace>
kubectl get storageclass
kubectl get pv
```

**How to fix**

1. Use an existing `storageClassName` or set a default StorageClass
2. Check CSI driver pods and provisioner logs
3. Match requested size and accessModes to available PVs
4. With `WaitForFirstConsumer`, schedule the pod first

**Reproduce it:** [`examples/pvc-pending.yaml`](../examples/pvc-pending.yaml)

---

## 22. FailedMount / FailedAttachVolume

**In plain English:** The volume is stuck or attached elsewhere.

**Common causes**

- ReadWriteOnce volume still attached to another node (Multi-Attach error)
- CSI driver or cloud API issue
- Missing Secret/ConfigMap used as a volume
- Node cannot reach the storage backend

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # Events: FailedMount / FailedAttachVolume
kubectl get volumeattachments
```

**How to fix**

1. Wait for or delete the old pod so the volume detaches
2. Use `ReadWriteMany` storage if multiple nodes need access
3. Check CSI node/controller pods and logs
4. Create the missing Secret/ConfigMap

---

## 23. Forbidden (RBAC)

**In plain English:** The service account lacks permission.

**Common causes**

- Missing Role/ClusterRole or binding
- Binding in the wrong namespace
- Pod uses the `default` ServiceAccount with no rights

**How to diagnose**

```bash
kubectl auth can-i list pods -n <namespace> --as=system:serviceaccount:<namespace>:<sa-name>
kubectl get rolebinding,clusterrolebinding -A | grep <sa-name>
```

**How to fix**

1. Grant only what is needed:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata: {name: pod-reader, namespace: <namespace>}
   rules:
   - apiGroups: [""]
     resources: ["pods"]
     verbs: ["get", "list", "watch"]
   ```
2. Bind it with a RoleBinding to the ServiceAccount
3. Avoid `cluster-admin` for workloads

---

## 24. Unauthorized (401)

**In plain English:** The token or kubeconfig is invalid or expired.

**Common causes**

- Expired token or client certificate
- Wrong kubeconfig or context
- Cloud auth plugin not logged in
- ServiceAccount token deleted or rotated

**How to diagnose**

```bash
kubectl config current-context
kubectl config view --minify
kubectl auth whoami   # v1.28+
```

**How to fix**

1. Refresh credentials, e.g. `aws eks update-kubeconfig`, `gcloud container clusters get-credentials`, `az aks get-credentials`
2. Switch to the right context: `kubectl config use-context <ctx>`
3. Renew expired client certificates
4. Re-login to your SSO or OIDC provider

---

## 25. Stuck in Terminating

**In plain English:** A finalizer is waiting on something that never ends.

**Common causes**

- A finalizer is never removed by its controller
- Volume cannot detach
- Node is unreachable (NotReady)
- Namespace has resources that cannot be deleted

**How to diagnose**

```bash
kubectl get pod <pod> -n <namespace> -o jsonpath='{.metadata.finalizers}'
kubectl describe pod <pod> -n <namespace>
kubectl get nodes
```

**How to fix**

1. Find out what the finalizer or controller is waiting on and fix that first
2. If the node is gone, delete the Node object
3. Last resort only, as it can leave orphaned resources:
   ```bash
   kubectl patch pod <pod> -n <namespace> -p '{"metadata":{"finalizers":null}}' --type=merge
   kubectl delete pod <pod> -n <namespace> --grace-period=0 --force
   ```

---
