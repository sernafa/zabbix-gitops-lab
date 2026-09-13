#!/usr/bin/env bash
# Funciones compartidas; los scripts que cargan este fichero usan set -euo pipefail.
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_DIR/versions.env"
source "$REPO_DIR/config.env"
STATE_DIR="$REPO_DIR/.state"
export KUBECONFIG="$STATE_DIR/kubeconfig"
export PATH="$REPO_DIR/.tools:$PATH"
export ZABBIX_SERVER_IMAGE ZABBIX_WEB_IMAGE POSTGRES_IMAGE ZABBIX_WEB_PORT
NETWORK='sernafa-gitops-lab'
COMPOSE_PROJECT='sernafa-gitops-zabbix'
CLUSTERS=(central)

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '\n%s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || fail "Falta $1. Consulta README.md."; }

cluster_name() {
    case "$1" in central) printf 'sernafa-%s' "$1" ;; *) fail 'Cliente desconocido.' ;; esac
}
k() {
    local cluster="$1"; shift
    kubectl --context "k3d-$(cluster_name "$cluster")" "$@"
}
compose() {
    local id owner
    while IFS= read -r id; do
        [[ -n "$id" ]] || continue
        owner="$(docker inspect "$id" --format '{{index .Config.Labels "sernafa.gitops-lab.owner"}}')"
        [[ "$owner" == "$LAB_ID" ]] || fail 'Hay contenedores Compose de otro laboratorio.'
    done < <(docker ps -aq --filter "label=com.docker.compose.project=$COMPOSE_PROJECT")
    if docker volume inspect "${COMPOSE_PROJECT}_postgres" >/dev/null 2>&1; then
        owner="$(docker volume inspect "${COMPOSE_PROJECT}_postgres" --format '{{index .Labels "sernafa.gitops-lab.owner"}}')"
        [[ "$owner" == "$LAB_ID" ]] || fail 'El volumen PostgreSQL pertenece a otro laboratorio.'
    fi
    docker compose --project-name "$COMPOSE_PROJECT" --file "$REPO_DIR/compose.yaml" "$@"
}

require_state() {
    [[ -f "$STATE_DIR/owner" ]] || fail 'Primero ejecuta just zabbix-up o just central-up.'
    LAB_ID="$(cat "$STATE_DIR/owner")"
    export LAB_ID
    [[ "$LAB_ID" =~ ^[0-9a-f]{32}$ ]] || fail 'Identificador del laboratorio inválido.'
}
require_network() {
    local owner
    owner="$(docker network inspect "$NETWORK" --format '{{index .Labels "sernafa.gitops-lab.owner"}}')"
    [[ "$owner" == "$LAB_ID" ]] || fail 'La red pertenece a otro laboratorio.'
}
require_cluster() {
    local name owner
    name="$(cluster_name "$1")"
    [[ -f "$STATE_DIR/$name.owned" ]] || fail "No hay registro de propiedad de $name."
    owner="$(docker inspect "k3d-$name-server-0" --format '{{index .Config.Labels "sernafa.gitops-lab.owner"}}')"
    [[ "$owner" == "$LAB_ID" ]] || fail "El clúster $name no pertenece a este laboratorio."
}
ensure_network() {
    local recovered_owner endpoint endpoint_owner
    umask 077
    mkdir -p "$STATE_DIR"
    if [[ ! -f "$STATE_DIR/owner" ]]; then
        if docker network inspect "$NETWORK" >/dev/null 2>&1; then
            recovered_owner="$(docker network inspect "$NETWORK" --format '{{index .Labels "sernafa.gitops-lab.owner"}}')"
            [[ "$recovered_owner" =~ ^[0-9a-f]{32}$ ]] || fail "La red $NETWORK no tiene una etiqueta válida del laboratorio. No se reutilizará."
            # Recuperar solo redes cuyos contenedores pertenecen al mismo laboratorio.
            for endpoint in $(docker network inspect "$NETWORK" --format '{{range $id, $container := .Containers}}{{$id}} {{end}}'); do
                endpoint_owner="$(docker inspect "$endpoint" --format '{{index .Config.Labels "sernafa.gitops-lab.owner"}}')"
                [[ "$endpoint_owner" == "$recovered_owner" ]] || fail 'La red contiene recursos ajenos; no se recuperará automáticamente.'
            done
            printf '%s\n' "$recovered_owner" > "$STATE_DIR/owner"
            printf 'Registro local recuperado desde la etiqueta de la red existente.\n'
        else
            openssl rand -hex 16 > "$STATE_DIR/owner"
        fi
    fi
    require_state
    if docker network inspect "$NETWORK" >/dev/null 2>&1; then
        require_network
    else
        docker network create --label "sernafa.gitops-lab.owner=$LAB_ID" "$NETWORK"
    fi
}
