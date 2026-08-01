# Práctica 3 — Inspección, logs y diagnóstico de contenedores

## Objetivo

Esta práctica muestra cómo:

1. generar y consultar registros de un contenedor;
2. limitar los logs por cantidad y por intervalo temporal;
3. seguir registros en tiempo real sin bloquear indefinidamente la terminal;
4. consultar estado, PID, etiquetas, variables y controlador de logs;
5. observar procesos y consumo de recursos;
6. verificar una detención ordenada mediante el estado y los logs;
7. limpiar de forma controlada los recursos creados.

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Controlador de almacenamiento | `overlay2` |
| Imagen | `alpine:3.24.1` |
| Controlador de logs observado | `json-file` |

Los identificadores de contenedor, PID, timestamps y valores de consumo varían entre ejecuciones.

---

## 1. Comprobar el estado inicial

```bash
docker ps -a \
  --filter 'name=^/observabilidad_practica3$'
```

Si aparece un recurso anterior, debe revisarse antes de eliminarlo.

## 2. Crear un contenedor que genere registros

```bash
docker run -d \
  --name observabilidad_practica3 \
  --label laboratorio=docker-basico \
  --label practica=3 \
  --env ENTORNO=practica3 \
  --env INTERVALO=2 \
  alpine:3.24.1 \
  sh -c 'trap "echo nivel=info evento=detencion; exit 0" TERM; i=1; while :; do echo "nivel=info evento=latido contador=$i entorno=$ENTORNO"; i=$((i + 1)); sleep "$INTERVALO" & wait $!; done'
```

El proceso genera un registro cada dos segundos. También instala un manejador de `SIGTERM` mediante `trap`, que registra el evento de detención y termina con código `0`.

Se comprueba que está activo:

```bash
docker ps \
  --filter 'name=^/observabilidad_practica3$'
```

## 3. Consultar los últimos registros

```bash
docker logs \
  --tail 5 \
  --timestamps \
  observabilidad_practica3
```

`--tail 5` limita la salida a cinco registros y `--timestamps` añade la marca temporal capturada por Docker. En la ejecución validada, estas marcas aparecieron en UTC, identificadas por el sufijo `Z`.

Los registros producidos por la aplicación incluyen nivel, evento, contador y entorno:

```text
nivel=info evento=latido contador=N entorno=practica3
```

El valor `N` depende del tiempo que lleve activo el contenedor.

## 4. Filtrar registros por tiempo

```bash
docker logs \
  --since 6s \
  observabilidad_practica3
```

`--since 6s` muestra solamente los registros correspondientes al intervalo reciente solicitado. La cantidad exacta puede variar según el momento en que se ejecute el comando.

## 5. Inspeccionar estado y configuración

```bash
docker inspect \
  --format 'Imagen={{.Config.Image}} | Estado={{.State.Status}} | PID={{.State.Pid}} | Driver de logs={{.HostConfig.LogConfig.Type}}' \
  observabilidad_practica3
```

En la ejecución validada se confirmó:

- imagen `alpine:3.24.1`;
- estado `running`;
- PID asignado en el host;
- controlador de logs `json-file`.

El controlador puede variar según la configuración del daemon Docker.

## 6. Consultar etiquetas

```bash
docker inspect \
  --format 'Laboratorio={{index .Config.Labels "laboratorio"}} | Práctica={{index .Config.Labels "practica"}}' \
  observabilidad_practica3
```

Resultado validado:

```text
Laboratorio=docker-basico | Práctica=3
```

Las etiquetas permiten clasificar y localizar recursos, pero son metadatos visibles y no deben contener información sensible.

## 7. Consultar variables de entorno

```bash
docker inspect \
  --format '{{range .Config.Env}}{{println .}}{{end}}' \
  observabilidad_practica3 \
  | grep -E '^(ENTORNO|INTERVALO)='
```

Resultado validado:

```text
ENTORNO=practica3
INTERVALO=2
```

> **Seguridad:** las variables configuradas de esta forma son visibles mediante `docker inspect`. No deben utilizarse para almacenar contraseñas, tokens o claves privadas en un repositorio o laboratorio público.

## 8. Observar los procesos

```bash
docker top observabilidad_practica3
```

En la ejecución validada se observaron:

- el shell principal encargado del bucle y del tratamiento de `SIGTERM`;
- un proceso temporal `sleep 2`.

Los PID de `docker top` corresponden a la vista de procesos del host y cambian en cada ejecución.

## 9. Obtener una muestra de recursos

```bash
docker stats --no-stream \
  --format 'Nombre={{.Name}} | CPU={{.CPUPerc}} | Memoria={{.MemUsage}} | Memoria %={{.MemPerc}} | PIDs={{.PIDs}}' \
  observabilidad_practica3
```

`--no-stream` obtiene una única muestra y devuelve el control a la terminal. CPU, memoria y cantidad de procesos son medidas puntuales y no deben documentarse como límites o resultados constantes.

## 10. Seguir registros en tiempo real

La ejecución de `docker logs --follow` sin límite muestra primero todo el historial disponible y después espera nuevos registros. En un contenedor que lleva varios minutos activo puede producir una salida innecesariamente extensa.

Se limita el historial inicial a dos entradas y el seguimiento a cinco segundos:

```bash
timeout 5s docker logs \
  --follow \
  --tail 2 \
  observabilidad_practica3

echo "Código de timeout: $?"
```

En la ejecución validada, `timeout` terminó con código `124` al alcanzar los cinco segundos. Este código corresponde al comando del host `timeout`; no es el código del contenedor.

Se verifica que el contenedor sigue activo:

```bash
docker ps \
  --filter 'name=^/observabilidad_practica3$'
```

## 11. Detener y verificar mediante logs

```bash
docker stop --timeout 5 observabilidad_practica3
```

Se consulta el estado final:

```bash
docker inspect \
  --format 'Estado={{.State.Status}} | Código={{.State.ExitCode}} | Finalizó={{.State.FinishedAt}}' \
  observabilidad_practica3
```

Después se consultan los últimos registros:

```bash
docker logs \
  --tail 3 \
  --timestamps \
  observabilidad_practica3
```

La ejecución validada mostró:

- estado `exited`;
- código de salida `0`;
- un último registro `nivel=info evento=detencion`;
- el evento de detención registrado antes de `FinishedAt`.

La combinación de estado, código y logs proporciona más evidencia que comprobar únicamente si el contenedor aparece detenido.

## 12. Limpieza

```bash
docker rm observabilidad_practica3

docker ps -a \
  --filter 'name=^/observabilidad_practica3$'
```

La imagen `alpine:3.24.1` se conserva para las demás prácticas.

---

## Resumen de comandos

| Comando | Finalidad |
|---|---|
| `docker logs --tail` | Limitar la salida a los últimos registros. |
| `docker logs --since` | Filtrar registros por intervalo temporal. |
| `docker logs --follow` | Seguir nuevos registros en tiempo real. |
| `docker inspect` | Consultar estado, configuración y metadatos. |
| `docker top` | Mostrar los procesos del contenedor. |
| `docker stats --no-stream` | Obtener una muestra puntual de recursos. |
| `docker stop --timeout` | Solicitar una detención con tiempo máximo de espera. |
| `docker rm` | Eliminar un contenedor detenido. |

## Conclusiones

La observabilidad básica de un contenedor combina registros, metadatos, procesos, consumo de recursos y estado final. Ninguna de estas fuentes debe interpretarse aisladamente. Las etiquetas y variables facilitan la configuración, pero también son visibles durante la inspección y no constituyen un mecanismo seguro para almacenar secretos.
