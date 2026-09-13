#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../versions.env
source "$REPO_DIR/versions.env"

for name in K3D_VERSION K3S_IMAGE ARGOCD_VERSION  \
    ZABBIX_VERSION ZABBIX_SERVER_IMAGE ZABBIX_WEB_IMAGE POSTGRES_IMAGE; do
    printf '%-24s %s\n' "$name" "${!name}"
done
