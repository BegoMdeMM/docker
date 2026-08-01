# Aplicación web y cliente con Docker Compose

## Objetivo

Esta práctica despliega un pequeño sistema multicontenedor formado por:

- `inicializador`: escribe una variable de entorno en un volumen;
- `web`: sirve una página HTTP y se ejecuta como usuario sin privilegios;
- `cliente`: valida DNS, HTTP y persistencia desde la red interna.

También se comprueban dependencias condicionadas, healthchecks, volúmenes, configuración mediante `.env`, red interna y controles básicos de seguridad.

## Estructura

```text
1-Web-y-cliente/
├── .env.example
├── .gitignore
├── compose.yaml
├── README.md
└── web/
    ├── Dockerfile
    ├── index.html
    └── server.sh
```

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Docker Compose | `2.40.3-3` |
| Imagen base | `alpine:3.24.1` fijada por digest |
| Proyecto | `compose_practica` |

---

## 1. Configuración local

`.env.example` documenta la variable:

```dotenv
APP_MESSAGE=Persistencia inicializada mediante Docker Compose
```

Se crea la configuración local:

```bash
cp --no-clobber .env.example .env
```

`.gitignore` excluye `.env` para evitar publicar configuraciones locales. Esto no convierte las variables de entorno en un almacén seguro de secretos.

## 2. Validar el modelo Compose

```bash
docker compose config --quiet
echo "Código de validación: $?"

docker compose config --services
docker compose config --volumes
docker compose config --images
```

La ejecución validada mostró tres servicios, el volumen `datos_web` y código `0`.

## 3. Diseño de servicios

### Inicializador

Escribe `APP_MESSAGE` en `/datos/mensaje.txt` y termina. Tiene el sistema raíz en solo lectura, `/tmp` temporal, capacidades eliminadas y `no-new-privileges`.

### Web

Se construye desde `web/Dockerfile`, espera a que el inicializador termine correctamente, monta el volumen como solo lectura y pertenece a `app_net`. Se ejecuta como `app`, con raíz de solo lectura, sin capacidades y con healthcheck HTTP.

### Cliente

Espera a que web esté saludable. Comparte la red y monta el volumen como solo lectura. Se ejecuta como UID/GID `65534:65534`, sin capacidades y con raíz de solo lectura.

### Red y volumen

- `app_net` está marcada como `internal: true`.
- `datos_web` persiste independientemente de los contenedores.

## 4. Primer despliegue fallido y diagnóstico

El primer `Dockerfile` intentó ejecutar `httpd`. La construcción terminó, pero el contenedor web no pudo arrancar:

```text
exec: "httpd": executable file not found in $PATH
```

El estado observado fue:

- inicializador: `Exited (0)`;
- web: `Created` sin poder arrancar;
- cliente: `Created`, porque dependía del healthcheck;
- despliegue: código `1`.

Se verificaron las utilidades disponibles:

```bash
docker run --rm alpine:3.24.1 \
  sh -c 'printf "httpd: "; command -v httpd || echo "no disponible"; busybox --list | grep -E "^(httpd|nc|wget)$" || true'
```

Resultado:

```text
httpd: no disponible
nc
wget
```

La corrección sustituyó `httpd` por `server.sh`, un servidor HTTP mínimo basado en `nc`. No se instalaron paquetes adicionales.

Antes de repetir se limpiaron los recursos fallidos:

```bash
docker compose down --volumes --remove-orphans
```

## 5. Construcción del servidor

`web/Dockerfile`:

```dockerfile
# syntax=docker/dockerfile:1

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

RUN addgroup -S app \
    && adduser -S -G app app

WORKDIR /site

COPY --chown=app:app --chmod=0444 index.html ./index.html
COPY --chown=app:app --chmod=0555 server.sh ./server.sh

USER app
EXPOSE 8080
CMD ["/site/server.sh"]
```

El script responde con HTTP 200, tipo HTML, longitud calculada y cierre explícito de conexión.

## 6. Desplegar y esperar estados

```bash
docker compose up \
  --build \
  --detach \
  --wait \
  --wait-timeout 60

echo "Código de despliegue: $?"

docker compose ps --all
```

La ejecución corregida terminó con código `0`:

- inicializador: `Exited (0)`;
- web: `healthy`;
- cliente: `Up`.

## 7. Validar DNS, HTTP y volumen

```bash
docker compose exec cliente \
  wget -q -O - http://web:8080/

echo "Código HTTP desde cliente: $?"

docker compose exec cliente cat /datos/mensaje.txt
echo "Código de lectura del volumen: $?"
```

Resultados validados:

- el nombre de servicio `web` resolvió dentro de la red Compose;
- la página HTML se recibió con código `0`;
- el volumen contenía `Persistencia inicializada mediante Docker Compose`;
- la lectura terminó con código `0`.

## 8. Verificar identidades

```bash
docker compose exec web id
docker compose exec cliente id
```

Resultado validado:

```text
web: uid=100(app) gid=101(app)
cliente: uid=65534(nobody) gid=65534(nobody)
```

La primera versión dejó al cliente como UID 0. La comprobación permitió corregir `compose.yaml` añadiendo `user: "65534:65534"`.

## 9. Verificar controles del proceso

```bash
docker compose exec web \
  sh -c 'grep -E "^(CapEff|NoNewPrivs):" /proc/1/status; touch /prueba'

docker compose exec cliente \
  sh -c 'grep -E "^(CapEff|NoNewPrivs):" /proc/1/status; touch /prueba'
```

En ambos servicios se obtuvo:

```text
CapEff: 0000000000000000
NoNewPrivs: 1
touch: /prueba: Read-only file system
```

Los intentos de escritura terminaron con código `1`, como estaba previsto.

## 10. Inspeccionar red y volumen

```bash
docker network inspect \
  --format 'Nombre={{.Name}} | Interna={{.Internal}} | Miembros={{range .Containers}}{{.Name}} {{end}}' \
  compose_practica_app_net

docker volume inspect \
  --format 'Nombre={{.Name}} | Driver={{.Driver}} | Proyecto={{index .Labels "com.docker.compose.project"}}' \
  compose_practica_datos_web
```

La red apareció como interna y contenía únicamente web y cliente. El volumen utilizó el driver local y la etiqueta de proyecto `compose_practica`.

## 11. Demostrar persistencia después de `down`

```bash
docker compose down --remove-orphans

docker compose ps --all

docker volume ls \
  --filter 'name=^compose_practica_datos_web$'
```

Los contenedores y redes se eliminaron, pero el volumen permaneció. Se leyó desde un contenedor independiente:

```bash
docker run --rm \
  --mount type=volume,source=compose_practica_datos_web,target=/datos,readonly \
  alpine:3.24.1 \
  cat /datos/mensaje.txt
```

La lectura conservó el mensaje y terminó con código `0`.

## 12. Limpieza final

```bash
docker volume rm compose_practica_datos_web
docker image rm compose-web:1.0

docker volume ls \
  --filter 'name=^compose_practica_datos_web$'

docker image ls compose-web
```

La ejecución validada terminó sin contenedores, redes, volumen ni imagen construida residuales.

## Consideraciones de seguridad

- Fijar las imágenes por versión y digest.
- Ejecutar como usuario sin privilegios siempre que sea posible.
- Eliminar capacidades y activar `no-new-privileges`.
- Utilizar sistemas raíz de solo lectura y `tmpfs` para temporales.
- Montar volúmenes como solo lectura en consumidores.
- No publicar puertos si la comunicación solo debe ocurrir dentro del proyecto.
- Utilizar redes internas cuando los servicios no necesiten salida externa.
- No guardar secretos reales en `.env`; emplear mecanismos específicos de secretos.
- Validar healthchecks y condiciones de dependencia, sin asumir que “contenedor iniciado” significa “servicio disponible”.

## Conclusiones

Docker Compose permite declarar y coordinar construcción, dependencias, redes, almacenamiento, configuración y controles de ejecución. La práctica demuestra además que una construcción correcta no garantiza que el proceso exista en la imagen: los estados, logs y herramientas disponibles deben verificarse. El fallo inicial y su corrección forman parte del resultado reproducible del laboratorio.
