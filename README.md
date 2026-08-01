# Docker Labs

Laboratorio práctico y progresivo para aprender Docker mediante ejercicios ejecutados, verificados y documentados sobre imágenes, contenedores, almacenamiento, redes, Docker Compose y hardening básico.

El repositorio conserva los resultados que se comprobaron realmente en el entorno de laboratorio. Los identificadores, direcciones IP, PID, tiempos y consumos son evidencias de una ejecución concreta, no valores universales.

## Entorno validado

| Componente | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Docker Compose | `2.40.3-3` |
| Almacenamiento | `overlay2` |
| Imagen base principal | `alpine:3.24.1` fijada por digest en las construcciones |

## Contenidos

### 0. Fundamentos

1. [Crear y modificar contenedores e imágenes](0-B%C3%A1sicos/1-Crear%20y%20modificar%20contenedores.md): `docker run`, cambios del sistema de archivos y comparación entre `docker commit` y una construcción declarativa.
2. [Gestionar contenedores y estados](0-B%C3%A1sicos/2-Gestionar%20contenedores.md): estados, códigos de salida, renombrado y detención.
3. [Inspección, logs y diagnóstico](0-B%C3%A1sicos/3-Inspecci%C3%B3n,%20logs%20y%20diagn%C3%B3stico%20de%20contenedores.md): logs, `inspect`, `top`, `stats` y metadatos.
4. [Ciclo de vida e interacción avanzada](0-B%C3%A1sicos/4-Lanzamiento%20y%20gesti%C3%B3n%20avanzada%20de%20contenedores.md): `attach`, `exec`, `create`, pausa, reinicio, espera y señales.

### 1. Imágenes reproducibles

- [Dockerfile básico](1-Im%C3%A1genes/1-Dockerfile-basico/README.md): base fijada por digest, etiquetas OCI, contexto reducido, usuario sin privilegios, permisos, caché y capas.

### 2. Almacenamiento

- [Volúmenes y bind mounts](2-Almacenamiento/1-Volumenes-y-bind-mounts/README.md): persistencia, solo lectura, permisos, ciclo de vida y riesgos sobre rutas del host.

### 3. Redes

- [Aislamiento y DNS](3-Redes/1-Aislamiento-y-DNS/README.md): redes bridge, DNS interno, aislamiento y contenedores multirred.

### 4. Docker Compose

- [Aplicación web y cliente](4-Compose/1-Web-y-cliente/README.md): construcción local, tres servicios, dependencias, healthcheck, red interna, volumen, `.env` y endurecimiento.

### 5. Seguridad

- [Hardening básico](5-Seguridad/1-Hardening-basico/README.md): usuario no root, capacidades eliminadas, `no-new-privileges`, raíz de solo lectura, `tmpfs`, red y límites.

## Progresión

```text
contenedor manual
    ↓
Dockerfile versionado
    ↓
persistencia de datos
    ↓
redes y DNS
    ↓
orquestación con Compose
    ↓
hardening y verificación
```

## Inicio rápido

Requisitos:

- Docker Engine en ejecución;
- Docker Compose v2 mediante `docker compose`;
- permisos para comunicarse con el daemon;
- utilidades estándar indicadas en cada práctica.

```bash
git clone https://github.com/BegoMdeMM/docker.git
cd docker

docker version
docker compose version
```

Cada práctica incluye objetivo, entorno validado, comandos, resultados observados, errores encontrados, verificaciones y limpieza explícita.

Para instalar Docker en otro equipo, consulta [la guía de referencia](docs/instalacion-docker.md) y las instrucciones oficiales enlazadas en ella.

## Ejemplo con Docker Compose

```bash
cd 4-Compose/1-Web-y-cliente
cp .env.example .env
docker compose config --quiet
docker compose up --build --detach --wait --wait-timeout 60
docker compose ps --all
```

Limpieza completa:

```bash
docker compose down --volumes --remove-orphans
docker image rm compose-web:1.0
```

Revisa siempre los objetivos antes de ejecutar operaciones de eliminación.

## Decisiones técnicas

- Se utiliza `--mount` para expresar origen, destino, tipo y modo.
- Las imágenes construidas fijan versión y digest de la base.
- Los procesos se ejecutan sin privilegios cuando su función lo permite.
- Compose aplica `read_only`, `tmpfs`, `cap_drop` y `no-new-privileges`.
- Las redes evitan subredes fijas cuando no son necesarias.
- Los errores reales se conservan. El ejercicio Compose registra el fallo inicial al asumir que Alpine incluía `httpd` y su corrección.
- No se provocan agotamientos de recursos ni se inventan resultados.

## Alcance

Este es un laboratorio educativo. Los controles mostrados no sustituyen análisis de vulnerabilidades, gestión de secretos, parcheado, autorización de aplicación, observabilidad centralizada, backups ni controles de producción.

## Autoría

Prácticas desarrolladas y verificadas por `BMdMM` como parte de un itinerario de aprendizaje en Docker, Linux, redes, DevSecOps y seguridad de contenedores.
