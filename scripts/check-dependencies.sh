#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../versions.env
source "$REPO_DIR/versions.env"
export PATH="$REPO_DIR/.tools:$PATH"

missing=0
for tool in bash just docker k3d kubectl jq curl openssl; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf 'OK     %s\n' "$tool"
    else
        printf 'FALTA  %s\n' "$tool" >&2
        missing=1
    fi
done

if command -v docker >/dev/null 2>&1; then
    if docker compose version >/dev/null 2>&1; then
        printf 'OK     Docker Compose\n'
    else
        printf 'FALTA  plugin Docker Compose (docker compose)\n' >&2
        missing=1
    fi
    if docker info >/dev/null 2>&1; then
        printf 'OK     acceso al motor Docker\n'
    else
        printf 'ERROR  Docker no responde o tu usuario no tiene acceso.\n' >&2
        missing=1
    fi
fi

if command -v k3d >/dev/null 2>&1; then
    installed="$(k3d version 2>/dev/null || true)"
    if [[ "$installed" != *"k3d version ${K3D_VERSION}"* ]]; then
        printf 'AVISO  K3d difiere de la versión de referencia %s.\n' "$K3D_VERSION" >&2
    fi
fi

if (( missing )); then
    printf '\nRevisa la sección de requisitos del README antes de continuar.\n' >&2
    exit 1
fi
printf '\nDependencias disponibles.\n'
