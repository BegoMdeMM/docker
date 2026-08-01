# Práctica 1 — Crear y modificar contenedores e imágenes

## Objetivo

Esta práctica muestra cómo:

1. crear un contenedor interactivo a partir de una imagen;
2. modificar su sistema de archivos;
3. consultar las diferencias respecto de la imagen original;
4. crear una imagen mediante `docker commit`;
5. verificar la imagen resultante y comparar sus capas;
6. limpiar los recursos creados.

> **Importante:** `docker commit` se utiliza aquí con fines didácticos. Para construir imágenes reproducibles y auditables debe utilizarse un `Dockerfile`.

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Controlador de almacenamiento | `overlay2` |
| Imagen base | `alpine:3.24.1` |
| Digest observado | `sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b` |

Los identificadores, fechas y tamaños mostrados por Docker pueden variar entre ejecuciones o plataformas.

---

## 1. Comprobar el estado inicial

Antes de comenzar, se verifica que no existan recursos de una ejecución anterior:

```bash
docker ps -a --filter 'name=^/alpine_orig_cont$'
docker image ls alpine_new
```

Si aparecen recursos anteriores, deben revisarse antes de eliminarlos para evitar borrar trabajo ajeno a la práctica.

## 2. Crear el contenedor interactivo

```bash
docker run -it --name alpine_orig_cont alpine:3.24.1 /bin/sh
```

Dentro del contenedor se crea un archivo verificable:

```sh
printf 'Creado en la práctica 1 de Docker\n' > /hello.txt
ls -l /hello.txt
cat /hello.txt
```

Para regresar al host sin detener el contenedor, se pulsa `Ctrl+P` y, a continuación, `Ctrl+Q`.

Desde el host se comprueba que continúa en ejecución:

```bash
docker ps --filter 'name=^/alpine_orig_cont$'
```

## 3. Examinar los cambios

```bash
docker diff alpine_orig_cont
```

La letra `A` identifica una ruta añadida, `C` una ruta modificada y `D` una ruta eliminada.

Una sesión interactiva puede generar cambios no intencionados, como `/root/.ash_history`. Antes de crear la imagen se elimina ese historial y se vuelve a comprobar la diferencia:

```bash
docker exec alpine_orig_cont rm -f /root/.ash_history
docker diff alpine_orig_cont
```

En la ejecución validada quedó únicamente:

```text
A /hello.txt
```

Esta comprobación ilustra uno de los riesgos de `docker commit`: podría incorporar historiales, archivos temporales o información sensible que no formen parte del objetivo de la imagen.

## 4. Crear la imagen modificada

```bash
docker commit \
  --message "Añade hello.txt en la práctica 1" \
  alpine_orig_cont \
  alpine_new:practica1
```

Se comprueba que la imagen existe:

```bash
docker image ls alpine_new
```

## 5. Verificar la imagen

Se crea un contenedor temporal que comprueba el archivo y se elimina automáticamente al terminar:

```bash
docker run --rm alpine_new:practica1 \
  sh -c 'test -f /hello.txt && cat /hello.txt'

echo "Código de salida: $?"
```

La ejecución validada mostró el contenido esperado y terminó con código `0`.

## 6. Comparar las capas

```bash
docker history \
  --format 'ID={{.ID}} | SIZE={{.Size}} | COMMENT={{.Comment}} | CREATED BY={{.CreatedBy}}' \
  alpine_new:practica1

docker history \
  --format 'ID={{.ID}} | SIZE={{.Size}} | COMMENT={{.Comment}} | CREATED BY={{.CreatedBy}}' \
  alpine:3.24.1
```

En la ejecución validada, `alpine_new:practica1` añadió una capa de `35 B`; las capas inferiores coincidían con las de la imagen base.

## 7. Limpieza

Se detiene y elimina el contenedor de trabajo:

```bash
docker stop alpine_orig_cont
docker rm alpine_orig_cont
docker ps -a --filter 'name=^/alpine_orig_cont$'
```

La imagen puede conservarse para compararla posteriormente con una imagen creada mediante `Dockerfile`. Cuando ya no sea necesaria, puede eliminarse explícitamente:

```bash
docker image rm alpine_new:practica1
```

---

## Conclusiones

La práctica demuestra que un contenedor puede modificarse y convertirse en una nueva imagen mediante `docker commit`. También muestra que este procedimiento captura el estado del contenedor, incluidos posibles cambios accidentales, por lo que no ofrece por sí solo una definición reproducible del proceso de construcción.

En una práctica posterior se realizará el mismo cambio mediante un `Dockerfile`, de modo que la construcción pueda revisarse, repetirse y mantenerse bajo control de versiones.
