# Hardening básico de contenedores

## Objetivo

Esta práctica compara un contenedor ejecutado con valores predeterminados y otro con controles explícitos de endurecimiento. Se verifican usuario, capacidades, elevación de privilegios, escritura, red y límites de recursos.

## Entorno validado

| Elemento | Valor |
|---|---|
| Equipo | `WDkali-h61` |
| Sistema | Kali GNU/Linux Rolling |
| Docker Engine | `28.5.2+dfsg4` |
| Imagen | `alpine:3.24.1` |

Los PID y valores instantáneos de consumo varían entre ejecuciones.

---

## 1. Comprobar nombres disponibles

```bash
docker ps -a --filter 'name=^/inseguro_practica_seguridad$'
docker ps -a --filter 'name=^/endurecido_practica_seguridad$'
```

## 2. Configuración predeterminada

```bash
docker run -d \
  --name inseguro_practica_seguridad \
  alpine:3.24.1 \
  sh -c 'trap "exit 0" TERM; while :; do sleep 1 & wait $!; done'
```

Se inspeccionan sus controles:

```bash
docker inspect \
  --format 'Usuario={{json .Config.User}} | Red={{.HostConfig.NetworkMode}} | Rootfs solo lectura={{.HostConfig.ReadonlyRootfs}} | Privileged={{.HostConfig.Privileged}} | Memoria={{.HostConfig.Memory}} | NanoCPUs={{.HostConfig.NanoCpus}} | Límite PIDs={{.HostConfig.PidsLimit}} | CapDrop={{json .HostConfig.CapDrop}} | SecurityOpt={{json .HostConfig.SecurityOpt}}' \
  inseguro_practica_seguridad
```

Resultado validado:

- usuario no definido, por lo que se utilizó `root` de la imagen;
- red `bridge`;
- raíz escribible;
- sin límites explícitos de memoria, CPU o PID;
- sin `CapDrop` ni `SecurityOpt` configurados;
- `Privileged=false`.

`Privileged=false` es necesario, pero no equivale a ejecutar con mínimo privilegio.

## 3. Privilegios efectivos predeterminados

```bash
docker exec inseguro_practica_seguridad \
  sh -c 'id; grep -E "^(CapEff|NoNewPrivs):" /proc/1/status'
```

La ejecución validada mostró UID 0, capacidades efectivas distintas de cero y `NoNewPrivs=0`.

También pudo escribir en la raíz:

```bash
docker exec inseguro_practica_seguridad \
  sh -c 'touch /prueba_escritura && ls -l /prueba_escritura && rm /prueba_escritura'

echo "Código de escritura predeterminada: $?"
```

El código observado fue `0`.

## 4. Crear la variante endurecida

```bash
docker run -d \
  --name endurecido_practica_seguridad \
  --user 65534:65534 \
  --network none \
  --read-only \
  --tmpfs /tmp:rw,noexec,nosuid,size=16m \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --memory 64m \
  --cpus 0.5 \
  --pids-limit 64 \
  alpine:3.24.1 \
  sh -c 'trap "exit 0" TERM; while :; do sleep 1 & wait $!; done'
```

Estos valores son adecuados para este proceso mínimo, no una plantilla universal. Un servicio real debe recibir los recursos, red, rutas escribibles y capacidades que necesite, pero no más.

## 5. Verificar la configuración endurecida

```bash
docker inspect \
  --format 'Usuario={{json .Config.User}} | Red={{.HostConfig.NetworkMode}} | Rootfs solo lectura={{.HostConfig.ReadonlyRootfs}} | Privileged={{.HostConfig.Privileged}} | Memoria={{.HostConfig.Memory}} | NanoCPUs={{.HostConfig.NanoCpus}} | Límite PIDs={{.HostConfig.PidsLimit}} | CapDrop={{json .HostConfig.CapDrop}} | SecurityOpt={{json .HostConfig.SecurityOpt}}' \
  endurecido_practica_seguridad
```

Resultado validado:

| Control | Valor observado |
|---|---|
| Usuario | `65534:65534` |
| Red | `none` |
| Raíz | solo lectura |
| Memoria | `67108864` bytes (`64 MiB`) |
| NanoCPUs | `500000000` (`0.5` CPU) |
| PID | `64` |
| CapDrop | `ALL` |
| SecurityOpt | `no-new-privileges:true` |

## 6. Verificar privilegios efectivos

```bash
docker exec endurecido_practica_seguridad \
  sh -c 'id; grep -E "^(CapEff|NoNewPrivs):" /proc/1/status'
```

Resultado validado:

```text
uid=65534(nobody) gid=65534(nobody)
CapEff: 0000000000000000
NoNewPrivs: 1
```

## 7. Raíz inmutable y temporal escribible

```bash
docker exec endurecido_practica_seguridad \
  sh -c 'touch /prueba_escritura'

echo "Código de escritura en raíz: $?"
```

La raíz rechazó la escritura con `Read-only file system` y código `1`.

El directorio temporal sí permite escritura:

```bash
docker exec endurecido_practica_seguridad \
  sh -c 'touch /tmp/prueba_temporal && ls -l /tmp/prueba_temporal && rm /tmp/prueba_temporal'

echo "Código de escritura en tmpfs: $?"
```

La prueba terminó con código `0` y el archivo pertenecía a `nobody`.

Las opciones `noexec` y `nosuid` del `tmpfs` reducen el uso de ejecutables y bits setuid en esa ruta.

## 8. Aislamiento de red

```bash
docker exec endurecido_practica_seguridad \
  sh -c 'cat /proc/net/dev; ping -c 1 -W 1 192.0.2.1'

echo "Código de conectividad: $?"
```

La dirección `192.0.2.1` pertenece al bloque reservado para documentación. La ejecución mostró únicamente `lo`, produjo `Network unreachable` y terminó con código `1`.

## 9. Comparar recursos

```bash
docker stats --no-stream \
  --format 'Nombre={{.Name}} | CPU={{.CPUPerc}} | Memoria={{.MemUsage}} | Memoria %={{.MemPerc}} | PIDs={{.PIDs}}' \
  inseguro_practica_seguridad \
  endurecido_practica_seguridad
```

En la muestra validada, el contenedor predeterminado mostró como límite la memoria disponible del host, mientras que el endurecido mostró `64 MiB`. Ambos tenían dos procesos.

Se intentó inicialmente usar el campo `.MemLimit`, pero Docker `28.5.2` lo rechazó porque no existe en la plantilla de `docker stats`. El límite ya forma parte de `.MemUsage` con el formato `uso / límite`.

No se provocó agotamiento de memoria ni de PID: `docker inspect` demuestra la configuración y forzar los límites podría afectar innecesariamente al host.

## 10. Limpieza

```bash
docker stop --timeout 5 \
  inseguro_practica_seguridad \
  endurecido_practica_seguridad

docker inspect \
  --format 'Nombre={{.Name}} | Estado={{.State.Status}} | Código={{.State.ExitCode}}' \
  inseguro_practica_seguridad \
  endurecido_practica_seguridad

docker rm \
  inseguro_practica_seguridad \
  endurecido_practica_seguridad

docker ps -a --filter 'name=practica_seguridad'
```

Los dos contenedores terminaron con código `0` y fueron eliminados en la ejecución validada.

## Comparación final

| Área | Predeterminado | Endurecido |
|---|---|---|
| Identidad | `root` | `nobody` |
| Capacidades | conjunto predeterminado | ninguna |
| Elevación | permitida según binarios y permisos | `no-new-privileges` |
| Raíz | escribible | solo lectura |
| Temporales | raíz del contenedor | `tmpfs` limitado |
| Red | bridge | ninguna |
| Memoria/CPU/PID | sin límites explícitos | límites definidos |

## Conclusiones

El hardening debe ajustarse a la función del contenedor. Esta práctica demuestra que usuario no root, eliminación de capacidades, `no-new-privileges`, raíz de solo lectura, temporales controlados, aislamiento de red y límites de recursos reducen superficie e impacto potencial. Estos controles complementan, pero no sustituyen, imágenes mantenidas, gestión de vulnerabilidades, secretos, segmentación, monitorización y actualización continua.
