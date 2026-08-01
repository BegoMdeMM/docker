# Aislamiento y DNS en redes Docker

## Objetivo

Esta práctica muestra cómo crear redes bridge definidas por el usuario, utilizar la resolución DNS interna de Docker, comprobar el aislamiento entre segmentos y modificar de forma explícita la conectividad de un contenedor.

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Imagen | `alpine:3.24.1` |
| Driver de red | `bridge` |

Las subredes, gateways, direcciones IP e identificadores son asignados dinámicamente y pueden variar.

---

## 1. Comprobar nombres disponibles

```bash
docker network ls --filter 'name=^red_frontend_practica$'
docker network ls --filter 'name=^red_backend_practica$'
docker ps -a --filter 'name=practica_redes'
```

Los recursos preexistentes deben examinarse antes de reutilizarlos o eliminarlos.

## 2. Crear dos redes independientes

```bash
docker network create \
  --driver bridge \
  --label laboratorio=docker \
  --label practica=redes \
  red_frontend_practica

docker network create \
  --driver bridge \
  --label laboratorio=docker \
  --label practica=redes \
  red_backend_practica
```

Se inspeccionan los parámetros asignados:

```bash
docker network inspect \
  --format 'Nombre={{.Name}} | Driver={{.Driver}} | Subred={{(index .IPAM.Config 0).Subnet}} | Gateway={{(index .IPAM.Config 0).Gateway}} | Interna={{.Internal}}' \
  red_frontend_practica \
  red_backend_practica
```

En la ejecución validada, Docker eligió `172.18.0.0/16` para frontend y `172.19.0.0/16` para backend. No se fijaron subredes manualmente para evitar colisiones con redes existentes.

## 3. Crear los contenedores

El proceso instalado gestiona `SIGTERM` y mantiene cada contenedor activo:

```bash
docker run -d \
  --name front_a_practica_redes \
  --network red_frontend_practica \
  alpine:3.24.1 \
  sh -c 'trap "exit 0" TERM; while :; do sleep 1 & wait $!; done'

docker run -d \
  --name front_b_practica_redes \
  --network red_frontend_practica \
  alpine:3.24.1 \
  sh -c 'trap "exit 0" TERM; while :; do sleep 1 & wait $!; done'

docker run -d \
  --name back_a_practica_redes \
  --network red_backend_practica \
  alpine:3.24.1 \
  sh -c 'trap "exit 0" TERM; while :; do sleep 1 & wait $!; done'
```

```bash
docker ps \
  --filter 'name=practica_redes' \
  --format 'Nombre={{.Names}} | Estado={{.Status}} | Redes={{.Networks}}'
```

## 4. DNS y comunicación dentro de una red

```bash
docker exec front_a_practica_redes cat /etc/resolv.conf

docker exec front_a_practica_redes \
  ping -c 2 front_b_practica_redes

echo "Código dentro de frontend: $?"
```

La ejecución validada mostró el resolver interno `127.0.0.11`. `front_a` resolvió el nombre de `front_b` y lo alcanzó con código `0`.

Docker proporciona resolución por nombre entre contenedores conectados a la misma red definida por el usuario. Las IP no deben tratarse como valores fijos.

## 5. Comprobar el aislamiento

```bash
docker exec front_a_practica_redes \
  ping -c 2 -W 1 back_a_practica_redes

echo "Código entre redes: $?"
```

Resultado validado:

```text
ping: bad address 'back_a_practica_redes'
Código entre redes: 1
```

El contenedor de frontend no recibió el registro DNS ni conectividad directa hacia el contenedor asociado exclusivamente a backend.

## 6. Conectar un contenedor a las dos redes

```bash
docker network connect \
  red_backend_practica \
  front_a_practica_redes
```

Se inspeccionan sus interfaces:

```bash
docker inspect \
  --format '{{range $red, $datos := .NetworkSettings.Networks}}Red={{$red}} | IP={{$datos.IPAddress}}{{println}}{{end}}' \
  front_a_practica_redes
```

Después se prueban ambos destinos:

```bash
docker exec front_a_practica_redes ping -c 1 front_b_practica_redes
docker exec front_a_practica_redes ping -c 1 back_a_practica_redes
```

En la ejecución validada, ambos pings terminaron correctamente. `front_a` tenía una interfaz en cada red.

> Conectar un contenedor a dos redes amplía su conectividad directa, pero no lo convierte automáticamente en router ni habilita por sí solo el reenvío entre los demás miembros de ambas redes.

## 7. Inspeccionar miembros

```bash
docker network inspect \
  --format 'Red={{.Name}} | Miembros={{range .Containers}}{{.Name}} {{end}}' \
  red_frontend_practica \
  red_backend_practica
```

Esta consulta permite auditar qué contenedores comparten cada segmento.

## 8. Retirar la conexión adicional

```bash
docker network disconnect \
  red_backend_practica \
  front_a_practica_redes
```

```bash
docker inspect \
  --format '{{range $red, $datos := .NetworkSettings.Networks}}Red={{$red}} | IP={{$datos.IPAddress}}{{println}}{{end}}' \
  front_a_practica_redes

docker exec front_a_practica_redes \
  ping -c 1 -W 1 back_a_practica_redes

echo "Código después de desconectar: $?"
```

La ejecución validada volvió a producir un error de resolución y código `1`, confirmando la restauración del aislamiento.

## 9. Limpieza

```bash
docker stop --timeout 5 \
  front_a_practica_redes \
  front_b_practica_redes \
  back_a_practica_redes

docker inspect \
  --format 'Nombre={{.Name}} | Estado={{.State.Status}} | Código={{.State.ExitCode}}' \
  front_a_practica_redes \
  front_b_practica_redes \
  back_a_practica_redes
```

Los tres contenedores terminaron con código `0` en la ejecución validada.

```bash
docker rm \
  front_a_practica_redes \
  front_b_practica_redes \
  back_a_practica_redes

docker network rm \
  red_frontend_practica \
  red_backend_practica

docker network ls \
  --filter 'label=practica=redes'
```

## Consideraciones de seguridad

- Aplicar mínimo alcance: conectar cada contenedor solo a las redes necesarias.
- Auditar contenedores multirred, porque pueden ampliar superficies de comunicación.
- No confiar en direcciones IP dinámicas como identidad permanente.
- Utilizar nombres y alias DNS para descubrimiento dentro de cada red.
- No asumir que una red bridge sustituye controles de aplicación, autenticación o filtrado adicional.
- Revisar periódicamente miembros, puertos publicados y redes huérfanas.
- Evitar subredes que colisionen con redes del host, VPN o infraestructura corporativa.

## Resumen

| Comando | Finalidad |
|---|---|
| `docker network create` | Crear una red definida por el usuario. |
| `docker network inspect` | Consultar direccionamiento y miembros. |
| `docker network connect` | Añadir una interfaz de red a un contenedor. |
| `docker network disconnect` | Retirar una interfaz de red. |
| `docker network rm` | Eliminar una red sin contenedores conectados. |

## Conclusiones

Las redes definidas por el usuario proporcionan descubrimiento DNS y separación de conectividad. La práctica demuestra que dos contenedores en la misma red pueden comunicarse por nombre, mientras que los asociados a segmentos distintos permanecen aislados hasta que se amplía explícitamente la pertenencia de red. La segmentación efectiva exige mantener esa pertenencia mínima y verificarla mediante inspección y pruebas reales.
