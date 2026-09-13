# Zabbix GitOps Lab

Base del laboratorio con dos componentes:

- **Zabbix con Docker Compose**: servidor, PostgreSQL y frontend web, con imágenes Alpine.
- **Un clúster k3d principal**, `zabbix-proxy-central`, con Argo CD para gestionar las aplicaciones y los clústeres que se incorporen después.

Argo CD se instala con sus componentes estándar, incluido su controlador de
aplicaciones. Esta etapa deja preparada la plataforma central; el registro de
otros clústeres y el despliegue de proxies se realizarán en los siguientes repositorios.

## Herramientas necesarias

Entorno Linux con Docker Engine activo y el plugin Docker Compose disponible.
Herramientas que hay que instalar con Brew:

```bash
brew install bash just k3d kubernetes-cli jq curl openssl@3
```

Comprueba los requisitos desde la raíz del repositorio:

```bash
just check
```

La comprobación informa de lo que falta y no instala nada automáticamente.

## Configuración

- `versions.env`: versiones de k3d, K3s, Argo CD y las imágenes de Zabbix y PostgreSQL, en formato de variables Bash.
- `config.env`: puertos locales de las interfaces web.
- `compose.yaml`: servicios Zabbix y almacenamiento persistente de PostgreSQL.
- `scripts/`: scripts Bash invocados desde `Justfile`.

Los scripts utilizan el contexto Docker actual y guardan su kubeconfig en
`.state/kubeconfig`, sin modificar `~/.kube/config`. Necesitas acceso a Internet
para descargar imágenes y los manifiestos oficiales de Argo CD.

## Levantar Zabbix

```bash
just zabbix-up
```

Arranca PostgreSQL, el servidor Zabbix y la interfaz web. La base de datos se
conserva en un volumen Docker. Puedes ejecutar esta parte sin crear el clúster k3d.

Abre **http://127.0.0.1:18080** e inicia sesión con las credenciales iniciales:

- Usuario: `Admin`
- Contraseña: `zabbix`

## Levantar el clúster principal y Argo CD

```bash
just central-up
```

Crea un único clúster k3d con un nodo servidor e instala Argo CD en el namespace
`argocd`. Espera a que sus componentes principales estén preparados.
La API Kubernetes se publica en `127.0.0.1:16443`.

Para levantar ambas partes en orden con una sola tarea:

```bash
just up
```

## Acceder a Argo CD desde el navegador

```bash
just ui
```

Esta tarea muestra la contraseña inicial del usuario **`admin`** y abre un
port-forward local. Mantén esa terminal abierta y entra en:

**https://127.0.0.1:18081**

El navegador mostrará un aviso porque Argo CD utiliza un certificado autofirmado.
Para este laboratorio local, acepta la excepción y accede con `admin` y la
contraseña que aparece en la terminal. Si ya cambiaste la contraseña, utiliza la
nueva; el secreto inicial no refleja ese cambio.

Pulsa `Ctrl+C` para cerrar el acceso web local. Argo CD sigue funcionando dentro
del clúster. Puedes volver a abrir el acceso ejecutando `just ui` otra vez.

## Estado, apagado y eliminación

```bash
just status     # Estado de Zabbix y los pods del clúster principal
just stop       # Apagar conservando los datos
just up         # Volver a arrancar
just destroy    # Eliminar el clúster, los datos de Zabbix y el estado local
```

Las acciones se limitan a los recursos identificados como propios del laboratorio.
`destroy` conserva las imágenes en caché y los archivos del repositorio.
No borres `.state/` mientras existan recursos: contiene el registro de propiedad y
el kubeconfig. Esta carpeta está excluida de Git.

Las interfaces web se publican únicamente en localhost. Las contraseñas incluidas
son para este laboratorio, no para un entorno de producción.
