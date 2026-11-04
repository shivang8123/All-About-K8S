# Networking

The pod is running but traffic does not reach it.

[Back to README](../README.md)

---

## 16. Readiness probe failed

**In plain English:** Alive, but not ready. Gets no traffic.

**Common causes**

- Wrong probe path or port
- App still warming up
- Dependency check failing
- Probe timeout too short

**How to diagnose**

```bash
kubectl get pods -n <namespace>   # READY shows 0/1
kubectl describe pod <pod> -n <namespace>   # Events: Readiness probe failed
```

**How to fix**

1. Fix the probe path, port and scheme
2. Increase `initialDelaySeconds` or use a `startupProbe`
3. A not-ready pod is removed from Service endpoints (see error 17)

**Reproduce it:** [`examples/readiness-fail.yaml`](../examples/readiness-fail.yaml)

---

## 17. Service has no endpoints

**In plain English:** The selector doesn't match any pod labels.

**Common causes**

- Service selector does not match pod labels
- Pods are not Ready
- Pods are in a different namespace
- Wrong targetPort

**How to diagnose**

```bash
kubectl get endpoints <svc> -n <namespace>
kubectl get svc <svc> -n <namespace> -o yaml | grep -A3 selector
kubectl get pods -n <namespace> --show-labels
```

**How to fix**

1. Make `spec.selector` match the pod template labels exactly
2. Make sure the pods are Ready
3. Ensure the Service and pods are in the same namespace
4. Verify `port` vs `targetPort`

**Reproduce it:** [`examples/no-endpoints-service.yaml`](../examples/no-endpoints-service.yaml)

---

## 18. Connection refused

**In plain English:** Nothing is listening on that port.

**Common causes**

- App listens on 127.0.0.1 instead of 0.0.0.0
- Wrong containerPort or targetPort
- App has not started or has crashed
- NetworkPolicy blocking traffic (often shows as timeout)

**How to diagnose**

```bash
kubectl exec -it <pod> -n <namespace> -- sh -c 'ss -lntp || netstat -lntp'
kubectl port-forward pod/<pod> 8080:<port> -n <namespace>
```

**How to fix**

1. Bind the app to `0.0.0.0`
2. Align the app port, containerPort, and Service targetPort
3. Check the pod is Running and Ready
4. Review NetworkPolicies in the namespace

---

## 19. no such host (DNS)

**In plain English:** Can't resolve the service name. Check CoreDNS.

**Common causes**

- CoreDNS pods down or crash looping
- Wrong service name or namespace in the URL
- Custom DNS or network plugin issue
- Pod `dnsPolicy` overridden

**How to diagnose**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
kubectl run dns-test -it --rm --restart=Never --image=busybox:1.36 -- nslookup kubernetes.default
```

**How to fix**

1. Restore CoreDNS pods and check their logs and ConfigMap
2. Use the full name: `<svc>.<namespace>.svc.cluster.local`
3. Check node-to-node networking (CNI) and kube-dns Service
4. Check the pod's `/etc/resolv.conf`

---

## 20. 502 / 503 from Ingress

**In plain English:** The ingress found no healthy backend.

**Common causes**

- Service has no endpoints (503)
- Backend pods not Ready
- Wrong Service port in the Ingress rule
- Backend crashed or closed the connection (502)
- Ingress controller cannot reach the pod network

**How to diagnose**

```bash
kubectl describe ingress <ingress> -n <namespace>
kubectl get endpoints <svc> -n <namespace>
kubectl logs -n ingress-nginx deploy/ingress-nginx-controller
```

**How to fix**

1. Confirm the Service has endpoints and Ready pods
2. Match the Ingress backend `service.port` to the Service
3. Check backend app logs for crashes
4. Check the ingress controller logs for upstream errors

---
