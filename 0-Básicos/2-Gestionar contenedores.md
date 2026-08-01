# Práctica 2 — Gestionar contenedores y sus estados

## Objetivo

Esta práctica muestra cómo:

1. diferenciar los contenedores activos de los detenidos;
2. consultar el estado y el código de salida de un contenedor;
3. listar las imágenes disponibles localmente;
4. cambiar el nombre de contenedores activos o detenidos;
5. detener correctamente un contenedor en ejecución;
6. limpiar de forma controlada los recursos creados.

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Controlador de almacenamiento | `overlay2` |
| Imagen de proceso corto | `hello-world:latest` |
| Imagen de proceso persistente | `alpine:3.24.1` |

Los identificadores y tiempos mostrados por Docker pueden variar en cada ejecución.

---

## 1. Comprobar el estado inicial

```bash
docker ps -a --filter 'name=practica2'
```

Si aparecen recursos anteriores, deben revisarse antes de eliminarlos.

## 2. Ejecutar un contenedor de proceso corto

```bash
docker run --name hello_practica2 hello-world
echo "Código devuelto por docker run: $?"
```

La imagen `hello-world` ejecuta el programa `/hello`, muestra un mensaje y finaliza. En la ejecución validada, `docker run` devolvió el código `0`.

Se compara la consulta de contenedores activos con la de todos los contenedores:

```bash
docker ps --filter 'name=^/hello_practica2$'
docker ps -a --filter 'name=^/hello_practica2$'
```

`docker ps` no muestra el contenedor porque ya ha terminado. `docker ps -a` permite verlo en estado `Exited (0)`.

El estado puede consultarse directamente:

```bash
docker inspect \
  --format 'Estado={{.State.Status}} | Código={{.State.ExitCode}} | Error={{json .State.Error}}' \
  hello_practica2
```

En la ejecución validada se obtuvo:

```text
Estado=exited | Código=0 | Error=""
```

## 3. Renombrar un contenedor detenido

```bash
docker rename hello_practica2 hello_renombrado_practica2
docker ps -a --filter 'name=^/hello_renombrado_practica2$'
```

Un contenedor no necesita estar activo para poder cambiar su nombre.

## 4. Listar las imágenes locales

```bash
docker image ls hello-world
docker image ls alpine
```

La lista de imágenes es independiente de la lista de contenedores. Una imagen puede utilizarse para crear múltiples contenedores.

## 5. Crear un contenedor persistente

`hello-world` no es adecuado para demostrar `docker stop` porque termina automáticamente. Para esta operación se crea un segundo contenedor cuyo proceso permanece activo y gestiona `SIGTERM`:

```bash
docker run -d \
  --name servicio_practica2 \
  alpine:3.24.1 \
  sh -c 'trap "exit 0" TERM; while :; do sleep 1 & wait $!; done'
```

Se comprueba que está activo:

```bash
docker ps --filter 'name=^/servicio_practica2$'
```

## 6. Renombrar y detener el contenedor activo

```bash
docker rename \
  servicio_practica2 \
  servicio_renombrado_practica2

docker ps --filter 'name=^/servicio_renombrado_practica2$'
```

Se solicita una terminación ordenada y se establece un tiempo máximo de cinco segundos:

```bash
docker stop --timeout 5 servicio_renombrado_practica2
```

> En Docker `28.5.2`, la opción anterior `--time` muestra una advertencia de obsolescencia. La opción vigente es `--timeout`.

Se consulta el resultado:

```bash
docker inspect \
  --format 'Estado={{.State.Status}} | Código={{.State.ExitCode}} | Finalizó={{.State.FinishedAt}}' \
  servicio_renombrado_practica2
```

El proceso utilizado instala un manejador de `SIGTERM` mediante `trap`, por lo que la ejecución validada finalizó ordenadamente con código `0`.

### Diferencia entre detención ordenada y forzada

En una prueba adicional se ejecutó un bucle de shell que no gestionaba correctamente `SIGTERM` como proceso principal. Tras agotarse el tiempo de espera, Docker envió `SIGKILL` y el contenedor terminó con código `137` (`128 + 9`).

Por tanto, `docker stop` no debe describirse únicamente como “enviar `SIGTERM`”. Docker solicita primero la terminación y, si el proceso no responde dentro del plazo, fuerza su finalización.

## 7. Limpieza

Se eliminan exclusivamente los dos contenedores creados en la práctica:

```bash
docker rm \
  hello_renombrado_practica2 \
  servicio_renombrado_practica2

docker ps -a --filter 'name=practica2'
```

Las imágenes descargadas se conservan para prácticas posteriores.

---

## Resumen de comandos

| Comando | Finalidad |
|---|---|
| `docker run` | Crear y ejecutar un contenedor. |
| `docker ps` | Mostrar los contenedores activos. |
| `docker ps -a` | Mostrar todos los contenedores. |
| `docker inspect` | Consultar el estado detallado de un contenedor. |
| `docker image ls` | Mostrar las imágenes locales. |
| `docker rename` | Cambiar el nombre de un contenedor. |
| `docker stop --timeout` | Solicitar la detención y limitar el tiempo de espera. |
| `docker rm` | Eliminar un contenedor detenido. |

## Conclusiones

La práctica diferencia una imagen de un contenedor y muestra que los contenedores pueden encontrarse en estados distintos según el comportamiento de su proceso principal. También demuestra que `docker ps` no permite observar por sí solo los contenedores finalizados y que una detención correcta depende de cómo el proceso PID 1 gestione las señales.
