set shell := ["bash", "-euo", "pipefail", "-c"]

# Mostrar las tareas disponibles
default:
    @just --list

# Comprobar herramientas y acceso a Docker
check:
    bash scripts/check-dependencies.sh

# Mostrar las versiones configuradas
versions:
    bash scripts/show-versions.sh

# Levantar Zabbix y el clúster principal con Argo CD
up:
    bash scripts/up.sh

# Levantar Zabbix, PostgreSQL y la interfaz web con Compose
zabbix-up:
    bash scripts/zabbix-up.sh

# Levantar el clúster k3d principal e instalar Argo CD
central-up:
    bash scripts/central-up.sh

# Consultar el estado de Zabbix y del clúster principal
status:
    bash scripts/status.sh

# Acceso web a Argo CD; mantener la terminal abierta
ui:
    bash scripts/ui.sh

# Apagar conservando datos
stop:
    bash scripts/stop.sh

# Eliminar el laboratorio y sus datos
destroy:
    bash scripts/destroy.sh
