# Scheduling

The scheduler cannot place the pod, or the node removed it.

[Back to README](../README.md)

---

## 11. Pending (0/N nodes available)

**In plain English:** No node can fit this pod.

**Common causes**

- Not enough CPU/memory
- Taints without matching tolerations
- nodeSelector or affinity matches nothing
- Unbound PVC
- Cluster has no schedulable nodes

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # Events: FailedScheduling, 0/3 nodes are available: ...
kubectl get nodes
```

**How to fix**

1. Read the FailedScheduling message: it lists the reason per node
2. Fix the specific cause (resources, taints, affinity, PVC)
3. Add nodes or enable the cluster autoscaler

**Reproduce it:** [`examples/pending-insufficient-resources.yaml`](../examples/pending-insufficient-resources.yaml)

---

## 12. Insufficient cpu/memory

**In plain English:** Your requests exceed the free capacity.

**Common causes**

- Pod requests are higher than any node's free allocatable
- Over-requested workloads on the cluster
- Node pool too small

**How to diagnose**

```bash
kubectl describe node <node> | grep -A8 'Allocated resources'
kubectl top nodes
```

**How to fix**

1. Lower `resources.requests` to realistic values
2. Scale the node pool or add nodes
3. Remove or downsize unused workloads
4. Remember: scheduling uses requests, not actual usage

---

## 13. Untolerated taint

**In plain English:** The node says "keep out". Your pod has no pass.

**Common causes**

- Nodes tainted (control-plane, GPU, dedicated pools) and pod has no toleration
- Node tainted automatically (e.g. `not-ready`, `disk-pressure`)

**How to diagnose**

```bash
kubectl describe node <node> | grep Taints
kubectl get pod <pod> -n <namespace> -o yaml | grep -A5 tolerations
```

**How to fix**

1. Add a matching toleration:
   ```yaml
   tolerations:
   - key: "dedicated"
     operator: "Equal"
     value: "gpu"
     effect: "NoSchedule"
   ```
2. Or remove the taint: `kubectl taint nodes <node> dedicated=gpu:NoSchedule-`

---

## 14. Node affinity mismatch

**In plain English:** The pod wants labels no node has.

**Common causes**

- `nodeSelector` / `nodeAffinity` label does not exist on any node
- Typo in label key or value

**How to diagnose**

```bash
kubectl get nodes --show-labels
kubectl get pod <pod> -n <namespace> -o yaml | grep -A10 -E 'nodeSelector|affinity'
```

**How to fix**

1. Label a node: `kubectl label node <node> disktype=ssd`
2. Or correct the selector/affinity in the pod spec
3. Prefer `preferredDuringScheduling...` if the rule is a soft preference

---

## 15. Evicted

**In plain English:** The node ran low on resources and kicked it out.

**Common causes**

- Node memory, disk or PID pressure
- Pod using more ephemeral storage than allowed
- Low or missing requests/limits making the pod a first target

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # Status: Failed, Reason: Evicted, Message
kubectl describe node <node> | grep -A8 Conditions
```

**How to fix**

1. Read the eviction message (which resource, which threshold)
2. Set realistic requests/limits (Guaranteed or Burstable QoS)
3. Clean disk space, rotate logs, add capacity
4. Clean up evicted pods:
   ```bash
   kubectl get pods -A --field-selector=status.phase=Failed
   kubectl delete pod <pod> -n <namespace>
   ```

---
