#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/common.sh"
require_state
require_cluster central
printf 'Argo CD: https://127.0.0.1:%s (certificado autofirmado). Usuario: admin\n' "$ARGOCD_UI_PORT"
if secret="$(k central -n argocd get secret argocd-initial-admin-secret --ignore-not-found -o json)" && [[ -n "$secret" ]]; then
    printf 'Contraseña inicial de Argo CD: '
    jq -r '.data.password | @base64d' <<<"$secret"
else
    printf 'No está disponible el secreto inicial. Utiliza tu contraseña actual de Argo CD.\n'
fi
printf 'Mantén esta terminal abierta; Ctrl+C cierra el acceso local.\n'
k central -n argocd port-forward --address 127.0.0.1 service/argocd-server "$ARGOCD_UI_PORT:443"
