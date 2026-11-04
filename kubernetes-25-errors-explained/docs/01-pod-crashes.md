# Pod Crashes

Containers that start and then die, restart in a loop, or never start.

[Back to README](../README.md)

---

## 01. CrashLoopBackOff

**In plain English:** App keeps crashing. K8s keeps retrying, slower each time.

**Common causes**

- The app exits on startup (bug, missing env var, bad config)
- A required dependency (DB, API) is unreachable
- Wrong command or entrypoint
- Liveness probe killing a healthy-but-slow app
- OOMKilled on every start

**How to diagnose**

```bash
kubectl get pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl describe pod <pod> -n <namespace>   # check Last State, Exit Code and Events
```

**How to fix**

1. Read `--previous` logs: they show why the last run died
2. Check the exit code: 1 = app error, 137 = killed (OOM/SIGKILL), 139 = segfault, 143 = SIGTERM
3. Fix config, secrets, env vars or dependencies, then redeploy
4. If it is probe-related, see errors 05 and 16

**Reproduce it:** [`examples/crashloopbackoff.yaml`](../examples/crashloopbackoff.yaml)

---

## 02. OOMKilled (137)

**In plain English:** Used more memory than its limit. Killed.

**Common causes**

- `resources.limits.memory` is too low
- Memory leak in the application
- JVM/Node heap larger than the container limit
- Short traffic spike or large payloads

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # Last State: Terminated, Reason: OOMKilled, Exit Code: 137
kubectl top pod <pod> -n <namespace> --containers
```

**How to fix**

1. Raise `resources.limits.memory` (and `requests.memory`) based on real usage
2. Fix the leak: profile the app
3. For JVM use `-XX:MaxRAMPercentage=75` instead of a fixed `-Xmx`
4. Add HPA or more replicas if the load is spiky

**Reproduce it:** [`examples/oomkilled.yaml`](../examples/oomkilled.yaml)

---

## 03. Init:Error

**In plain English:** A setup container failed, so your app never starts.

**Common causes**

- Init script exits non-zero
- The service it waits for is not reachable
- Missing permissions or wrong volume path
- Wrong image or command in the init container

**How to diagnose**

```bash
kubectl get pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace> -c <init-container-name>
kubectl describe pod <pod> -n <namespace>
```

**How to fix**

1. Read the init container logs (`-c <init-container-name>`)
2. Make sure what the init container waits for actually exists
3. Fix the script or command; init containers run in order and must all succeed
4. `Init:CrashLoopBackOff` means it keeps failing and retrying

---

## 04. RunContainerError

**In plain English:** Container couldn't start. Bad command or mount.

**Common causes**

- Command or args not found in the image
- Entrypoint file is missing or not executable
- Volume mount path conflicts or is invalid
- Runtime error when starting the process

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # read the Events section
kubectl logs <pod> -n <namespace>
```

**How to fix**

1. Verify `command` / `args` match what the image really contains
2. Test locally: `docker run --rm -it <image> sh`
3. Check `volumeMounts` paths and `subPath` values
4. Check the file permissions of the entrypoint

---

## 05. Liveness probe failed

**In plain English:** Health check failed, so it got restarted.

**Common causes**

- Wrong probe path or port
- App takes longer to start than `initialDelaySeconds`
- `timeoutSeconds` too short under load
- The health endpoint depends on an external system

**How to diagnose**

```bash
kubectl describe pod <pod> -n <namespace>   # Events: Liveness probe failed: ...
kubectl get pod <pod> -n <namespace> -o yaml | grep -A10 livenessProbe
```

**How to fix**

1. Fix the probe path, port and scheme
2. Add a `startupProbe` for slow-starting apps
3. Increase `timeoutSeconds`, `periodSeconds` and `failureThreshold`
4. Keep liveness checks local: do not check databases or other services

**Reproduce it:** [`examples/liveness-fail.yaml`](../examples/liveness-fail.yaml)

---
