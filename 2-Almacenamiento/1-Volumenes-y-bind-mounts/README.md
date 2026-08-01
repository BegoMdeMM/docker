# Volúmenes administrados y bind mounts

## Objetivo

Esta práctica compara los dos mecanismos principales para proporcionar almacenamiento persistente a un contenedor:

1. un volumen administrado por Docker;
2. un bind mount asociado a una ruta concreta del host.

Se comprueba la persistencia después de eliminar contenedores, el comportamiento de los montajes de solo lectura, la conservación de permisos y los riesgos de permitir escritura sobre el host.

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Controlador de almacenamiento | `overlay2` |
| Imagen utilizada | `alpine:3.24.1` |
| Driver del volumen | `local` |

Los identificadores, rutas internas y metadatos pueden variar según el sistema y la configuración de Docker.

---

## 1. Diferencias principales

| Característica | Volumen administrado | Bind mount |
|---|---|---|
| Ubicación | Gestionada por Docker. | Ruta elegida explícitamente en el host. |
| Portabilidad | Menor dependencia de la estructura del host. | Depende de que exista la ruta indicada. |
| Acceso desde el host | No debe manipularse directamente. | Los archivos son visibles y editables desde el host. |
| Persistencia | Independiente del contenedor. | Depende de los archivos de la ruta del host. |
| Riesgo principal | Olvidar su ciclo de vida o copia de seguridad. | Permitir al contenedor modificar rutas sensibles del host. |

En los ejemplos se utiliza `--mount` porque expresa de forma explícita el tipo, el origen, el destino y el modo de acceso.

## 2. Comprobación inicial

```bash
docker volume ls \
  --filter 'name=^datos_practica_volumenes$'

test -e /tmp/docker-bind-practica-volumenes \
  && echo "La ruta temporal ya existe" \
  || echo "La ruta temporal está libre"
```

Si alguno de los recursos existe, debe revisarse antes de continuar. No se debe eliminar por el nombre sin comprobar su procedencia.

---

# Parte A — Volumen administrado

## 3. Crear el volumen

```bash
docker volume create datos_practica_volumenes
```

Se inspecciona su configuración:

```bash
docker volume inspect \
  --format 'Nombre={{.Name}} | Driver={{.Driver}} | Punto de montaje={{.Mountpoint}} | Alcance={{.Scope}}' \
  datos_practica_volumenes
```

En la ejecución validada se observó:

- nombre `datos_practica_volumenes`;
- driver `local`;
- alcance `local`;
- almacenamiento interno bajo `/var/lib/docker/volumes/...`.

> La ruta interna pertenece a Docker y no debe editarse manualmente. Debe accederse a los datos mediante contenedores o mecanismos de copia controlados.

## 4. Escribir mediante un contenedor temporal

```bash
docker run --rm \
  --name escritor_practica_volumenes \
  --mount type=volume,source=datos_practica_volumenes,target=/datos \
  alpine:3.24.1 \
  sh -c 'printf "Dato persistente en volumen administrado\n" > /datos/mensaje.txt; ls -l /datos/mensaje.txt'
```

El contenedor se elimina automáticamente al terminar:

```bash
docker ps -a \
  --filter 'name=^/escritor_practica_volumenes$'
```

El volumen continúa existiendo:

```bash
docker volume ls \
  --filter 'name=^datos_practica_volumenes$'
```

Esto demuestra que el ciclo de vida del volumen es independiente del contenedor que escribió en él.

## 5. Leer desde otro contenedor

```bash
docker run --rm \
  --name lector_practica_volumenes \
  --mount type=volume,source=datos_practica_volumenes,target=/datos,readonly \
  alpine:3.24.1 \
  cat /datos/mensaje.txt

echo "Código de lectura: $?"
```

Resultado validado:

```text
Dato persistente en volumen administrado
Código de lectura: 0
```

El segundo contenedor accedió a los datos creados por el primero, aunque ambos se ejecutaron con `--rm`.

## 6. Comprobar el modo de solo lectura

```bash
docker run --rm \
  --name escritura_bloqueada_practica_volumenes \
  --mount type=volume,source=datos_practica_volumenes,target=/datos,readonly \
  alpine:3.24.1 \
  sh -c 'printf "Modificación no permitida\n" >> /datos/mensaje.txt'

echo "Código de escritura: $?"
```

La ejecución validada produjo el error `Read-only file system` y terminó con código `1`.

Después se confirmó que el contenido original seguía intacto:

```bash
docker run --rm \
  --mount type=volume,source=datos_practica_volumenes,target=/datos,readonly \
  alpine:3.24.1 \
  cat /datos/mensaje.txt
```

## 7. Eliminar el volumen

Antes de eliminarlo se comprueba que ningún contenedor lo utiliza:

```bash
docker ps -a \
  --filter 'volume=datos_practica_volumenes'
```

Después se elimina el recurso exacto creado por la práctica:

```bash
docker volume rm datos_practica_volumenes

docker volume ls \
  --filter 'name=^datos_practica_volumenes$'
```

> Eliminar un volumen borra sus datos. Persistencia no significa copia de seguridad: los volúmenes requieren una política explícita de backup y restauración.

---

# Parte B — Bind mount

## 8. Preparar la ruta del host

```bash
mkdir --mode=0755 \
  /tmp/docker-bind-practica-volumenes

printf 'Archivo creado en el host\n' \
  > /tmp/docker-bind-practica-volumenes/origen.txt
```

Se inspeccionan los metadatos:

```bash
stat -c 'Propietario=%U:%G | Permisos=%a | Ruta=%n' \
  /tmp/docker-bind-practica-volumenes/origen.txt

cat /tmp/docker-bind-practica-volumenes/origen.txt
```

En el entorno validado, el archivo pertenecía a `kali:kali`, con UID/GID `1000:1000` y permisos `664`. Los permisos concretos dependen de la `umask` y configuración del host.

## 9. Montar la ruta como solo lectura

```bash
docker run --rm \
  --name lector_bind_practica_volumenes \
  --mount type=bind,source=/tmp/docker-bind-practica-volumenes,target=/datos,readonly \
  alpine:3.24.1 \
  sh -c 'cat /datos/origen.txt; stat -c "UID=%u | GID=%g | Permisos=%a | Ruta=%n" /datos/origen.txt'
```

La ejecución validada mostró el contenido del host y conservó UID `1000`, GID `1000` y permisos `664` dentro del contenedor.

Se comprueba el bloqueo de escritura:

```bash
docker run --rm \
  --name escritura_bloqueada_bind_practica \
  --mount type=bind,source=/tmp/docker-bind-practica-volumenes,target=/datos,readonly \
  alpine:3.24.1 \
  sh -c 'printf "Cambio bloqueado\n" >> /datos/origen.txt'

echo "Código de escritura: $?"
```

La ejecución validada produjo `Read-only file system` y código `1`.

## 10. Permitir escritura desde el contenedor

```bash
docker run --rm \
  --name escritor_bind_practica_volumenes \
  --mount type=bind,source=/tmp/docker-bind-practica-volumenes,target=/datos \
  alpine:3.24.1 \
  sh -c 'printf "Línea añadida desde el contenedor\n" >> /datos/origen.txt'

echo "Código de escritura: $?"
```

Se comprueba directamente desde el host:

```bash
cat /tmp/docker-bind-practica-volumenes/origen.txt

stat -c 'Propietario=%U:%G | Permisos=%a | Ruta=%n' \
  /tmp/docker-bind-practica-volumenes/origen.txt
```

Resultado validado:

```text
Archivo creado en el host
Línea añadida desde el contenedor
```

El archivo conservó propietario `kali:kali` y permisos `664`. La modificación demuestra que un bind mount de lectura y escritura concede al contenedor capacidad directa para alterar esa ruta del host.

## 11. Limpieza del bind mount

Primero se comprueba que no quedan contenedores asociados a la práctica:

```bash
docker ps -a \
  --filter 'name=practica_volumenes'
```

Después se eliminan únicamente el archivo y directorio temporales creados:

```bash
rm -- /tmp/docker-bind-practica-volumenes/origen.txt
rmdir -- /tmp/docker-bind-practica-volumenes

test -e /tmp/docker-bind-practica-volumenes \
  && echo "La ruta todavía existe" \
  || echo "La ruta temporal fue eliminada"
```

---

## 12. Consideraciones de seguridad

- Utilizar `readonly` cuando el contenedor no necesite escribir.
- No montar rutas amplias como `/`, `/etc` o `/var` sin una necesidad justificada.
- No montar `/var/run/docker.sock` en contenedores no confiables: proporciona un nivel de control equivalente al del daemon Docker.
- Revisar UID, GID y permisos para evitar archivos inaccesibles o modificables por usuarios no previstos.
- No almacenar secretos en archivos versionados ni confiar en el aislamiento del volumen como sustituto del cifrado y control de acceso.
- Definir copias de seguridad y pruebas de restauración para datos importantes.
- Comprobar qué contenedores utilizan un volumen antes de eliminarlo.

## Resumen de comandos

| Comando | Finalidad |
|---|---|
| `docker volume create` | Crear un volumen administrado. |
| `docker volume inspect` | Consultar driver, alcance y metadatos. |
| `docker volume ls` | Enumerar o filtrar volúmenes. |
| `docker volume rm` | Eliminar un volumen no utilizado. |
| `--mount type=volume` | Montar un volumen administrado. |
| `--mount type=bind` | Montar una ruta concreta del host. |
| `readonly` | Impedir escrituras desde el contenedor. |

## Conclusiones

Los volúmenes administrados desacoplan los datos del ciclo de vida del contenedor y evitan depender de una ruta concreta del host. Los bind mounts ofrecen acceso directo y transparente a archivos del host, pero amplían el impacto potencial del contenedor. La elección debe basarse en el propósito de los datos, su portabilidad, permisos, necesidad de acceso desde el host y requisitos de seguridad y recuperación.
