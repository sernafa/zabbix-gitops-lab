#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/lib/common.sh"
for tool in docker openssl curl jq; do need "$tool"; done
ensure_network
compose up -d --wait --wait-timeout 300
for ((attempt=0; attempt<60; attempt++)); do
    if curl --fail --silent --max-time 5 -H 'Content-Type: application/json-rpc' \
        --data '{"jsonrpc":"2.0","method":"apiinfo.version","params":{},"id":1}' \
        "http://127.0.0.1:$ZABBIX_WEB_PORT/api_jsonrpc.php" | jq -e '.result | type == "string"' >/dev/null; then
        printf '\nZabbix disponible: http://127.0.0.1:%s\n' "$ZABBIX_WEB_PORT"
        exit 0
    fi
    sleep 5
done
fail 'La API de Zabbix no está preparada. Consulta just status y los logs de Compose.'
