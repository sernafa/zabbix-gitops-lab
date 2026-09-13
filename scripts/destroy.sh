#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/common.sh"
require_state
require_network
# Validar todos antes de eliminar cualquiera. Nunca se ejecuta docker system prune.
for cluster in "${CLUSTERS[@]}"; do
    name="$(cluster_name "$cluster")"
    if docker inspect "k3d-$name-server-0" >/dev/null 2>&1; then require_cluster "$cluster"; fi
done
compose down --volumes
for cluster in "${CLUSTERS[@]}"; do
    name="$(cluster_name "$cluster")"
    if docker inspect "k3d-$name-server-0" >/dev/null 2>&1; then k3d cluster delete "$name"; fi
done
docker network rm "$NETWORK"
rm -rf -- "$STATE_DIR"
printf 'Laboratorio y datos eliminados. Las imágenes descargadas se conservan en caché.\n'
