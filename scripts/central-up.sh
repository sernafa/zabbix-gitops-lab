#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/common.sh"
bash "$REPO_DIR/scripts/check-dependencies.sh"
ensure_network
name="$(cluster_name central)"
if k3d cluster list -o json | jq -e --arg name "$name" '.[] | select(.name == $name)' >/dev/null; then
    require_cluster central
    k3d cluster start "$name" --wait
else
    k3d cluster create "$name" --servers 1 --agents 0 --no-lb --network "$NETWORK" \
        --image "$K3S_IMAGE" --api-port 127.0.0.1:16443 \
        --runtime-label "zabbix.gitops-lab.owner=$LAB_ID@server:*" \
        --kubeconfig-update-default=false --kubeconfig-switch-context=false \
        --k3s-arg '--disable=traefik,servicelb,metrics-server@server:*' --wait
    touch "$STATE_DIR/$name.owned"
fi
k3d kubeconfig get "$name" > "$KUBECONFIG.tmp"
mv "$KUBECONFIG.tmp" "$KUBECONFIG"
manifest="$STATE_DIR/argocd-$ARGOCD_VERSION.yaml"
if [[ ! -s "$manifest" ]]; then
    curl --fail --location --retry 3 \
        "https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml" \
        -o "$manifest.tmp"
    mv "$manifest.tmp" "$manifest"
fi
k central create namespace argocd --dry-run=client -o yaml | k central apply -f -
k central -n argocd apply --server-side --force-conflicts --field-manager=zabbix-lab -f "$manifest"
for deployment in argocd-redis argocd-repo-server argocd-server; do
    k central -n argocd rollout status "deployment/$deployment" --timeout=300s
done
k central -n argocd rollout status statefulset/argocd-application-controller --timeout=300s
printf '\nArgo CD preparado. Ejecuta just ui para acceder por navegador.\n'
