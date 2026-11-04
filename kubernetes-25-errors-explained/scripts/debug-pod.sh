#!/usr/bin/env bash
# Collect the most useful debugging info for a pod into one folder.
# Usage: ./scripts/debug-pod.sh <pod> [namespace]
set -euo pipefail

POD="${1:?Usage: $0 <pod> [namespace]}"
NS="${2:-default}"
OUT="debug-${POD}-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo "Collecting data for pod/$POD in namespace $NS -> $OUT/"

kubectl get pod "$POD" -n "$NS" -o wide        > "$OUT/01-status.txt"
kubectl get pod "$POD" -n "$NS" -o yaml        > "$OUT/02-manifest.yaml"
kubectl describe pod "$POD" -n "$NS"           > "$OUT/03-describe.txt"
kubectl get events -n "$NS" \
  --field-selector "involvedObject.name=$POD" \
  --sort-by=.lastTimestamp                     > "$OUT/04-events.txt"

# Logs for every container (current + previous run), including init containers
for C in $(kubectl get pod "$POD" -n "$NS" \
  -o jsonpath='{.spec.initContainers[*].name} {.spec.containers[*].name}'); do
  kubectl logs "$POD" -n "$NS" -c "$C"              > "$OUT/logs-${C}.txt"          2>&1 || true
  kubectl logs "$POD" -n "$NS" -c "$C" --previous   > "$OUT/logs-${C}-previous.txt" 2>&1 || true
done

NODE=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.nodeName}')
if [ -n "$NODE" ]; then
  kubectl describe node "$NODE" > "$OUT/05-node-${NODE}.txt"
fi

echo "Done. Start with $OUT/03-describe.txt (Events section at the bottom)."
