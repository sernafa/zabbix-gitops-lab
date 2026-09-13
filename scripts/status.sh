#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/common.sh"
require_state
if [[ -f "$KUBECONFIG" ]]; then
    log 'Clúster principal'
    k central --request-timeout=10s get pods -A || true
else
    printf 'El clúster principal todavía no se ha creado.\n'
fi
compose ps -a
