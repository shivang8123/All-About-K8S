# Examples

Deliberately broken manifests you can use to practice debugging on a **test cluster**
(kind, minikube, k3d, or a lab cluster). Never apply them in production.

```bash
kubectl create namespace k8s-errors-lab
kubectl apply -n k8s-errors-lab -f examples/crashloopbackoff.yaml
kubectl get pods -n k8s-errors-lab -w
kubectl describe pod crashloop-demo -n k8s-errors-lab
```

Clean up everything when you are done:

```bash
kubectl delete namespace k8s-errors-lab
```

| File | Error it reproduces |
|------|---------------------|
| `crashloopbackoff.yaml` | 01 CrashLoopBackOff |
| `oomkilled.yaml` | 02 OOMKilled (137) |
| `liveness-fail.yaml` | 05 Liveness probe failed |
| `imagepullbackoff.yaml` | 06 ErrImagePull / 07 ImagePullBackOff |
| `invalid-image-name.yaml` | 08 InvalidImageName |
| `missing-configmap.yaml` | 09 CreateContainerConfigError |
| `pending-insufficient-resources.yaml` | 11 Pending / 12 Insufficient cpu/memory |
| `readiness-fail.yaml` | 16 Readiness probe failed |
| `no-endpoints-service.yaml` | 17 Service has no endpoints |
| `pvc-pending.yaml` | 21 PVC Pending |
