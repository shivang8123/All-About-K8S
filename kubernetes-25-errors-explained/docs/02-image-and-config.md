# Image & Config

The container image or the config it needs cannot be fetched or built.

[Back to README](../README.md)

---

## 06. ErrImagePull

**In plain English:** Couldn't download the image. Wrong tag or no access.

**Common causes**

- Typo in image name or tag
- Tag does not exist
- Private registry and no credentials
- Registry unreachable or Docker Hub rate limit

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # Events: Failed to pull image ...
# on the node (containerd):
crictl pull <image>
```

**How to fix**

1. Check the image name and tag in the registry
2. Create and reference an `imagePullSecret` for private registries
3. Check node network, DNS and proxy access to the registry
4. Use a mirror or authenticated pulls to avoid rate limits

---

## 07. ImagePullBackOff

**In plain English:** Still can't download it. Retrying slower.

**Common causes**

- Same causes as ErrImagePull: this is the back-off state after repeated failures

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>
kubectl get secret -n <namespace>
```

**How to fix**

1. Create a registry secret:
   ```bash
   kubectl create secret docker-registry regcred \
     --docker-server=<registry> \
     --docker-username=<user> \
     --docker-password=<password> \
     -n <namespace>
   ```
2. Reference it with `imagePullSecrets: [{name: regcred}]` in the pod spec or ServiceAccount
3. Fix the image tag, then delete the pod so it is recreated

**Reproduce it:** [`examples/imagepullbackoff.yaml`](../examples/imagepullbackoff.yaml)

---

## 08. InvalidImageName

**In plain English:** The image name itself is malformed.

**Common causes**

- Uppercase letters in the repository name
- Spaces or illegal characters
- Malformed tag or digest

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>
kubectl get pod <pod> -n <namespace> -o jsonpath='{.spec.containers[*].image}'
```

**How to fix**

1. Repository names must be lowercase
2. Format: `registry/repo/name:tag` or `name@sha256:<digest>`
3. Fix the manifest or Helm values and re-apply

**Reproduce it:** [`examples/invalid-image-name.yaml`](../examples/invalid-image-name.yaml)

---

## 09. CreateContainerConfigError

**In plain English:** A ConfigMap or Secret it needs is missing.

**Common causes**

- Referenced ConfigMap or Secret does not exist
- Key name is wrong inside the ConfigMap/Secret
- `runAsNonRoot: true` but the image runs as root
- Object exists in a different namespace

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # Events: configmap "x" not found
kubectl get configmap,secret -n <namespace>
```

**How to fix**

1. Create the missing ConfigMap/Secret in the same namespace
2. Check key names with `kubectl describe configmap <name>`
3. Mark non-critical refs `optional: true`
4. Set a numeric `runAsUser` if using `runAsNonRoot`

**Reproduce it:** [`examples/missing-configmap.yaml`](../examples/missing-configmap.yaml)

---

## 10. CreateContainerError

**In plain English:** The runtime failed to build the container.

**Common causes**

- Invalid command or args
- Container name conflict on the node
- Runtime or storage problem on the node (disk full)
- Bad security context or mount options

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>
# on the node:
journalctl -u kubelet --since '10 min ago'
crictl ps -a
```

**How to fix**

1. Read the exact message in Events
2. Check node disk space and runtime health
3. Validate command, args, mounts and securityContext
4. If one node is bad, cordon and drain it

---
