#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
bash "$REPO_DIR/scripts/check-dependencies.sh"
bash "$REPO_DIR/scripts/zabbix-up.sh"
bash "$REPO_DIR/scripts/central-up.sh"
