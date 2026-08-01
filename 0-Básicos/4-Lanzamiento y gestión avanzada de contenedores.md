# Práctica 4 — Ciclo de vida e interacción avanzada con contenedores

## Objetivo

Esta práctica muestra cómo:

1. eliminar automáticamente contenedores mediante `--rm`;
2. diferenciar ejecuciones interactivas, no interactivas y en segundo plano;
3. distinguir `docker attach` de `docker exec`;
4. observar los estados `created`, `running`, `paused` y `exited`;
5. utilizar `create`, `start`, `pause`, `unpause`, `restart` y `wait`;
6. diferenciar una detención ordenada de una finalización forzada;
7. limpiar de forma controlada los recursos creados.

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Controlador de almacenamiento | `overlay2` |
| Imagen principal | `alpine:3.24.1` |
| Imagen auxiliar | `hello-world:latest` |

Los identificadores, procesos, fechas y tiempos pueden variar entre ejecuciones.

---

## 1. Comprobar el estado inicial

```bash
docker ps -a --filter 'name=practica4'
```

Si aparecen recursos anteriores, deben revisarse antes de eliminarlos.

## 2. Eliminación automática con `--rm`

```bash
docker run --rm \
  --name autolimpieza_practica4 \
  hello-world

echo "Código de salida: $?"

docker ps -a \
  --filter 'name=^/autolimpieza_practica4$'
```

En la ejecución validada, el contenedor terminó con código `0` y dejó de aparecer incluso con `docker ps -a`, porque `--rm` solicitó su eliminación automática.

## 3. Ejecución no interactiva

```bash
docker run \
  --name no_interactivo_practica4 \
  alpine:3.24.1

echo "Código de salida: $?"

docker inspect \
  --format 'Estado={{.State.Status}} | Código={{.State.ExitCode}} | TTY={{.Config.Tty}} | Stdin={{.Config.OpenStdin}}' \
  no_interactivo_practica4
```

La ejecución validada mostró:

```text
Estado=exited | Código=0 | TTY=false | Stdin=false
```

El shell predeterminado de Alpine no recibió una terminal ni mantuvo abierta su entrada, por lo que terminó inmediatamente.

Se elimina el contenedor detenido:

```bash
docker rm no_interactivo_practica4
```

## 4. Ejecución interactiva y desechable

```bash
docker run --rm -it \
  --name interactivo_practica4 \
  alpine:3.24.1 \
  /bin/sh
```

Dentro del contenedor:

```sh
printf 'Sesión interactiva activa\n'
ps
exit
```

En la ejecución validada, `/bin/sh` era el proceso PID 1 y `ps` se ejecutó como un proceso adicional. `exit` terminó el proceso principal y `--rm` eliminó el contenedor:

```bash
docker ps -a --filter 'name=^/interactivo_practica4$'
```

## 5. Contenedor interactivo en segundo plano

```bash
docker run -dit \
  --name segundo_plano_practica4 \
  alpine:3.24.1 \
  /bin/sh
```

Se comprueba su configuración:

```bash
docker inspect \
  --format 'Estado={{.State.Status}} | PID={{.State.Pid}} | TTY={{.Config.Tty}} | Stdin={{.Config.OpenStdin}}' \
  segundo_plano_practica4
```

La combinación `-dit` inicia el contenedor en segundo plano, asigna una terminal y mantiene abierta la entrada estándar.

## 6. Conexión mediante `docker attach`

```bash
docker attach segundo_plano_practica4
```

Dentro del contenedor:

```sh
printf 'Conectado al proceso principal mediante attach\n'
```

Para volver al host sin terminar el contenedor se pulsa `Ctrl+P` y, a continuación, `Ctrl+Q`. La terminal muestra `read escape sequence` al desconectarse.

> No debe escribirse `exit` durante esta prueba, porque `docker attach` está conectado al shell que actúa como PID 1. Si este proceso termina, también lo hace el contenedor.

Se verifica que sigue activo:

```bash
docker ps --filter 'name=^/segundo_plano_practica4$'
```

## 7. Procesos adicionales mediante `docker exec`

Se ejecuta un comando puntual:

```bash
docker exec segundo_plano_practica4 \
  sh -c 'printf "Proceso adicional mediante exec\n"; ps'
```

Después se abre un segundo shell:

```bash
docker exec -it segundo_plano_practica4 /bin/sh
```

Dentro del nuevo shell:

```sh
printf 'Shell adicional abierto mediante exec\n'
exit
```

`exit` termina únicamente el proceso creado por `docker exec`. El PID 1 original continúa activo:

```bash
docker ps --filter 'name=^/segundo_plano_practica4$'
```

### Diferencia entre `attach` y `exec`

| Operación | Comportamiento |
|---|---|
| `docker attach` | Conecta con la entrada y salida del proceso principal existente. |
| `docker exec` | Crea un proceso adicional dentro de un contenedor activo. |
| `exit` después de `attach` | Puede terminar el PID 1 y detener el contenedor. |
| `exit` después de `exec` | Termina el proceso adicional, pero no el PID 1. |

## 8. Pausar y reanudar

```bash
docker pause segundo_plano_practica4

docker inspect \
  --format 'Estado={{.State.Status}} | Pausado={{.State.Paused}} | PID={{.State.Pid}}' \
  segundo_plano_practica4

docker unpause segundo_plano_practica4

docker inspect \
  --format 'Estado={{.State.Status}} | Pausado={{.State.Paused}} | PID={{.State.Pid}}' \
  segundo_plano_practica4
```

En la ejecución validada, el PID permaneció igual al pausar y reanudar. Los procesos quedaron suspendidos temporalmente, pero no fueron reiniciados.

## 9. Reiniciar el contenedor

```bash
docker restart --timeout 5 segundo_plano_practica4

docker inspect \
  --format 'Estado={{.State.Status}} | Pausado={{.State.Paused}} | PID={{.State.Pid}} | Inicio={{.State.StartedAt}}' \
  segundo_plano_practica4
```

En la ejecución validada, el PID cambió tras `restart`. Esto diferencia el reinicio de `pause` y `unpause`, que conservaron el proceso principal.

## 10. Crear sin ejecutar y arrancar después

```bash
docker create \
  --name creado_practica4 \
  alpine:3.24.1 \
  sh -c 'printf "Contenedor iniciado después de create\n"'
```

Antes de iniciarlo:

```bash
docker inspect \
  --format 'Estado={{.State.Status}} | PID={{.State.Pid}} | Inicio={{.State.StartedAt}}' \
  creado_practica4
```

La ejecución validada mostró el estado `created`, PID `0` y ninguna fecha real de inicio.

Se inicia adjuntando su salida:

```bash
docker start -a creado_practica4

docker inspect \
  --format 'Estado={{.State.Status}} | Código={{.State.ExitCode}} | PID={{.State.Pid}}' \
  creado_practica4
```

El contenedor mostró su mensaje y terminó con código `0`.

## 11. Esperar la finalización con `docker wait`

```bash
docker run -d \
  --name espera_practica4 \
  alpine:3.24.1 \
  sh -c 'sleep 3; exit 7'

date '+Antes de wait: %H:%M:%S'
docker wait espera_practica4
date '+Después de wait: %H:%M:%S'

docker inspect \
  --format 'Estado={{.State.Status}} | Código={{.State.ExitCode}}' \
  espera_practica4
```

En la ejecución validada, `docker wait` bloqueó la terminal durante tres segundos y mostró `7`, que era el código de salida del contenedor.

## 12. Detención ordenada y finalización forzada

`docker stop --timeout N` solicita primero la terminación del proceso y espera como máximo `N` segundos. Si el proceso no termina, Docker fuerza su finalización.

`docker kill`, en cambio, envía inmediatamente la señal indicada. Para validar `SIGKILL`:

```bash
docker kill --signal SIGKILL segundo_plano_practica4

docker inspect \
  --format 'Estado={{.State.Status}} | Código={{.State.ExitCode}} | Señal OOM={{.State.OOMKilled}} | Finalizó={{.State.FinishedAt}}' \
  segundo_plano_practica4
```

La ejecución validada terminó con código `137` (`128 + 9`) y `OOMKilled=false`. Por tanto, la causa fue el `SIGKILL` solicitado y no una finalización del kernel por falta de memoria.

> En Docker `28.5.2`, debe utilizarse `--timeout`; la opción anterior `--time` está obsoleta.

## 13. Limpieza

```bash
docker rm \
  segundo_plano_practica4 \
  creado_practica4 \
  espera_practica4

docker ps -a --filter 'name=practica4'
```

Los contenedores de las secciones 2 y 4 se eliminaron automáticamente mediante `--rm`, y el contenedor no interactivo se eliminó al terminar su sección.

---

## Resumen de comandos

| Comando | Finalidad |
|---|---|
| `docker run --rm` | Ejecutar y eliminar automáticamente al finalizar. |
| `docker attach` | Conectar con el proceso principal existente. |
| `docker exec` | Crear un proceso adicional en un contenedor activo. |
| `docker create` | Crear un contenedor sin iniciarlo. |
| `docker start -a` | Iniciar un contenedor y adjuntar su salida. |
| `docker pause` / `unpause` | Suspender o reanudar sus procesos. |
| `docker restart` | Detener e iniciar de nuevo el contenedor. |
| `docker wait` | Esperar su finalización y mostrar su código de salida. |
| `docker stop --timeout` | Solicitar la terminación y limitar el tiempo de espera. |
| `docker kill --signal` | Enviar inmediatamente una señal al proceso principal. |
| `docker inspect` | Consultar configuración y estado detallado. |

## Conclusiones

El estado de un contenedor depende directamente de su proceso principal. `attach`, `exec`, `pause`, `restart`, `stop` y `kill` actúan de formas distintas y no deben considerarse operaciones equivalentes. La inspección del PID, del estado y del código de salida permite verificar qué ocurrió realmente en cada transición.
