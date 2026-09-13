#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/common.sh"
require_state
require_network
if docker inspect k3d-sernafa-central-server-0 >/dev/null 2>&1; then
    require_cluster central
    k3d cluster stop sernafa-central
fi
compose stop
