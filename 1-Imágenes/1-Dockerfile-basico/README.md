# Construcción de una imagen básica mediante Dockerfile

## Objetivo

Esta práctica reproduce mediante un `Dockerfile` un cambio que en la práctica 1 se realizó manualmente con `docker commit`. El objetivo es que las instrucciones necesarias para construir la imagen queden declaradas, revisables y bajo control de versiones.

También se aplican medidas básicas de reducción de privilegios y del contexto de construcción.

## Estructura

```text
1-Dockerfile-basico/
├── .dockerignore
├── Dockerfile
├── mensaje.txt
└── README.md
```

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Controlador de almacenamiento | `overlay2` |
| BuildKit | Constructor predeterminado con driver `docker` |
| Imagen base | `alpine:3.24.1` |
| Digest de la base | `sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b` |

Los identificadores de imagen, tiempos y tamaños pueden variar entre versiones, plataformas o configuraciones de construcción.

---

## 1. Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

LABEL org.opencontainers.image.title="Dockerfile básico"
LABEL org.opencontainers.image.description="Imagen mínima para demostrar una construcción reproducible"
LABEL org.opencontainers.image.source="https://github.com/BegoMdeMM/docker"
LABEL org.opencontainers.image.authors="BMdMM"

RUN addgroup -S app \
    && adduser -S -G app app

WORKDIR /app

COPY --chown=app:app --chmod=0444 mensaje.txt ./mensaje.txt

USER app

CMD ["cat", "/app/mensaje.txt"]
```

### Decisiones adoptadas

| Instrucción | Finalidad |
|---|---|
| `FROM ...:3.24.1@sha256:...` | Fijar versión y contenido de la imagen base. |
| `LABEL` | Incorporar metadatos OCI sobre título, descripción, origen y autoría. |
| `RUN addgroup ... adduser` | Crear una identidad específica sin privilegios. |
| `WORKDIR /app` | Establecer un directorio de trabajo explícito. |
| `COPY --chown --chmod` | Definir propietario y permisos durante la construcción. |
| `USER app` | Evitar que el proceso predeterminado se ejecute como `root`. |
| `CMD [...]` | Utilizar la forma exec, sin shell intermedio. |

## 2. Contexto limitado con `.dockerignore`

```dockerignore
*
!Dockerfile
!.dockerignore
!mensaje.txt
```

Primero se excluye todo y después se admiten solamente los archivos necesarios. Esto reduce transferencias innecesarias al constructor y disminuye el riesgo de incorporar por accidente documentos, credenciales, repositorios Git u otros archivos locales.

> `.dockerignore` reduce el contexto enviado, pero no sustituye la gestión segura de secretos.

## 3. Contenido incorporado

`mensaje.txt` contiene:

```text
Creado de forma reproducible con Dockerfile.
```

## 4. Construcción

Desde este directorio:

```bash
docker build \
  --pull \
  --progress=plain \
  --tag dockerfile-basico:1.0 \
  .

echo "Código de construcción: $?"
```

En la ejecución validada:

- se resolvió la imagen base mediante el digest fijado;
- se ejecutó la creación del usuario;
- se estableció `/app`;
- se copió `mensaje.txt` con propietario y permisos explícitos;
- la construcción terminó con código `0`;
- la imagen resultante ocupó aproximadamente `8.42 MB`.

## 5. Inspección de la configuración

```bash
docker image ls dockerfile-basico

docker image inspect \
  --format 'ID={{.Id}} | Usuario={{.Config.User}} | Directorio={{.Config.WorkingDir}} | CMD={{json .Config.Cmd}}' \
  dockerfile-basico:1.0
```

La ejecución validada confirmó:

```text
Usuario=app | Directorio=/app | CMD=["cat","/app/mensaje.txt"]
```

Las etiquetas OCI pueden comprobarse con:

```bash
docker image inspect \
  --format 'Título={{index .Config.Labels "org.opencontainers.image.title"}} | Autor={{index .Config.Labels "org.opencontainers.image.authors"}} | Origen={{index .Config.Labels "org.opencontainers.image.source"}}' \
  dockerfile-basico:1.0
```

## 6. Verificación funcional

```bash
docker run --rm \
  --name ejecucion_dockerfile_basico \
  dockerfile-basico:1.0

echo "Código del comando predeterminado: $?"
```

Resultado validado:

```text
Creado de forma reproducible con Dockerfile.
Código del comando predeterminado: 0
```

Se comprueba la identidad efectiva:

```bash
docker run --rm dockerfile-basico:1.0 id
```

La ejecución validada utilizó el usuario `app` con UID `100`, en lugar de `root`.

Se comprueban propietario y permisos:

```bash
docker run --rm dockerfile-basico:1.0 \
  stat -c 'Propietario=%U:%G | Permisos=%a | Ruta=%n' \
  /app/mensaje.txt
```

Resultado validado:

```text
Propietario=app:app | Permisos=444 | Ruta=/app/mensaje.txt
```

Finalmente se verifica que `--rm` no dejó un contenedor residual:

```bash
docker ps -a \
  --filter 'name=^/ejecucion_dockerfile_basico$'
```

## 7. Reconstrucción y caché

Sin modificar los archivos:

```bash
docker build \
  --progress=plain \
  --tag dockerfile-basico:1.0 \
  .
```

En la reconstrucción validada, las instrucciones `RUN`, `WORKDIR` y `COPY` aparecieron como `CACHED`, y Docker reutilizó la imagen ya construida.

La existencia de un procedimiento reproducible significa que otra persona puede revisar y repetir las mismas instrucciones. No implica por sí sola que cualquier construcción, en cualquier momento y plataforma, vaya a producir necesariamente una imagen idéntica bit a bit.

## 8. Historial de capas

```bash
docker history \
  --format 'ID={{.ID}} | SIZE={{.Size}} | CREATED BY={{.CreatedBy}}' \
  dockerfile-basico:1.0
```

En la ejecución validada se observaron, entre otras:

- una capa para crear el grupo y el usuario;
- una capa para copiar `mensaje.txt`;
- metadatos para `WORKDIR`, `USER`, `CMD` y las etiquetas;
- las capas procedentes de la imagen Alpine fijada.

## 9. Comparación con `docker commit`

| `docker commit` | `Dockerfile` |
|---|---|
| Captura el estado de un contenedor. | Declara los pasos de construcción. |
| Puede incorporar cambios accidentales. | Permite revisar cada instrucción. |
| No explica por sí solo cómo repetir el cambio. | Puede versionarse y ejecutarse de nuevo. |
| Puede incluir historiales o temporales. | `.dockerignore` limita el contexto y `COPY` explicita los archivos. |

`docker commit` sigue siendo útil con fines didácticos o de diagnóstico puntual, pero no es el mecanismo recomendado para mantener imágenes de un proyecto.

## 10. Limpieza opcional

La imagen puede conservarse para prácticas posteriores. Cuando ya no sea necesaria:

```bash
docker image rm dockerfile-basico:1.0
```

## Conclusiones

El `Dockerfile` convierte una modificación manual en una definición revisable y repetible. La imagen construida utiliza una base fijada por digest, limita su contexto, declara metadatos, ejecuta el proceso como usuario sin privilegios y establece permisos de solo lectura sobre el archivo incorporado.
