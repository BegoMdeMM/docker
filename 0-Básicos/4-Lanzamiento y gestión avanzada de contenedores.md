# Ejemplo 4
## Lanzamiento y gestión avanzada de contenedores en Docker

El objetivo de este ejemplo es aprender a interactuar con contenedores en distintos estados (`Created`, `Exited`, `Up`, y `Paused`) y cómo gestionar su comportamiento mediante las diversas opciones de Docker.

Este ejemplo muestra cómo:

1. Eliminar automáticamente contenedores usando la opción `--rm`.
2. Crear y manejar contenedores interactivos y no interactivos.
3. Diferenciar entre comandos como `docker attach` y `docker exec`.
4. Operaciones adicionales para gestionar el ciclo de vida de los contenedores.

---

## Pasos del ejemplo:

1. **Lanzar un contenedor y eliminarlo automáticamente:**
```
docker run --rm hello-world
docker ps -a
```
- Ejecuta la imagen hello-world. Tras imprimir el mensaje, el contenedor se elimina automáticamente debido a la opción --rm.
- Verifica que el contenedor no está listado porque fue eliminado automáticamente.

2. **Crear contenedores con comportamientos interactivos o no**
Empezamos con el NO interactivo
```
docker run --name=a1 alpine
docker rm a1
```
- Crea un contenedor llamado a1 basado en Alpine. Al no asociarlo a un terminal interactivo, el contenedor termina inmediatamente y queda en estado Exited. Lo eliminamos manualmente tras su ejecución.

En el caso de un contenedor interactivo...:
```
docker run --rm --name a2 -it alpine
/ # Ctrl-D
docker ps -a
```
- Lanza un contenedor interactivo a2 con un terminal. Permite ejecutar comandos dentro del contenedor. Al salir del shell con Ctrl-D, el contenedor termina y se elimina automáticamente por la opción --rm que le hemos pasado por parámetro en el propio comando.

3. **Contenedores en segundo plano (demonios)**
```
docker run --rm --name a3 -itd alpine
docker attach a3
/ # Ctrl-PQ
```
- Lanza el contenedor a3 en segundo plano (`-d`) con un terminal interactivo (`-it`). El contenedor sigue activo incluso después de desconectar el terminal.
- Con el comando `attach` se asocia el terminal del host al contenedor a3. Permite interactuar con él. Al presionar la combinación de teclas, vuelve a desconectar la terminal del contenedor, pero sigue activo en segundo plano.

4. **Diferencia entre docker attach y docker exec**
La diferencia entre `docker attach` y `docker exec` puede parecer sutil a primera vista, pero es fundamental para entender cómo interactuar con contenedores Docker.

Los comandos `docker attach` y `docker exec` se diferencian en cómo interactúan con los procesos dentro de un contenedor Docker, aunque en ciertas situaciones pueden parecer similares. Ambos comandos permiten acceder al interior de un contenedor, pero lo hacen de formas distintas y con propósitos específicos.

Por un lado, `docker attach` conecta el terminal del host directamente al proceso principal que se está ejecutando en el contenedor. Este proceso principal es el que se especificó al iniciar el contenedor, como un shell interactivo (`/bin/sh`). Todo lo que el proceso principal produzca (`stdout/stderr`) se envía al terminal del host, permitiendo monitorear o interactuar con ese proceso. Sin embargo, si el proceso principal del contenedor finaliza, ya sea porque escribes exit o porque el proceso termina por sí mismo, el contenedor también se detiene. Por esta razón, `docker attac`h está limitado al proceso principal y no puede lanzar nuevos procesos dentro del contenedor. Si necesitas desconectar tu terminal sin detener el contenedor, puedes usar la secuencia de escape `Ctrl-PQ`.

Por otro lado, `docker exec` permite lanzar un nuevo proceso dentro de un contenedor ya activo. Este nuevo proceso puede ser otro shell interactivo (`/bin/sh`) o cualquier comando puntual (`ls -l`, por ejemplo). Lo importante es que el proceso lanzado con `docker exec` es completamente independiente del proceso principal del contenedor. Esto significa que si terminas el proceso iniciado con exec (por ejemplo, escribiendo exit en el nuevo shell), el contenedor sigue activo mientras su proceso principal no haya finalizado. Esto hace que `docker exec` sea una herramienta más flexible, ya que puedes usarla para ejecutar múltiples tareas en un contenedor sin interferir con el proceso principal.

Ambos comandos pueden parecer similares cuando docker attach conecta al proceso principal de un contenedor que está ejecutando un shell interactivo, ya que en esta situación también puedes interactuar con el shell como lo harías al abrir uno nuevo con `docker exec -it`. Sin embargo, la diferencia clave está en que `docker attach` se conecta exclusivamente al proceso principal, mientras que `docker exec` crea procesos adicionales que no afectan el estado del contenedor original.

Vamos a ver un caso en el que `docker exec` se comporté de forma similar a docker attach:
```
docker exec -it a3 /bin/sh
```
- Abre un nuevo shell en el contenedor a3 activo. Al salir de este shell, el contenedor sigue ejecutándose.
```
docker exec a3 ls -l
```
- Ejecuta un comando no interactivo (`ls -l`) dentro del contenedor a3. El contenedor permanece activo.

5. **Operaciones adicionales sobre contenedores** 
- `docker create imagen`:
    - Crea un contenedor pero no lo ejecuta (no se ve con "`docker ps`" pero sí con "`docker ps -a`"). Queda en estado `Created`.

- `docker start contenedor`:
    - Arranca un contenedor previamente creado o detenido.

- `docker stop contenedor`:
    -  Detiene un contenedor en ejecución (señal `SIGTERM`). Cambia al estado `Exited`.

- `docker restart contenedor`:
    - Reinicia un contenedor.

- `docker pause contenedor`  / `docker unpause contenedor`:
    - Pausa o reanuda un contenedor en ejecución.

- `docker wait contenedor`:
    - Bloquea el terminal del host hasta que el contenedor indicado se detenga.

- `docker kill contenedor`:
    - Termina inmediatamente un contenedor enviando la señal `SIGKILL`. Suele pasar a estado `Exited`con un código de error. En condiciones normales, un contenedor que termina devolvería un código 0.
Nótese que "docker stop" es similar, pero la señal enviada es `SIGTERM`.

- docker attach contenedor:
    - Asocia el terminal del host al contenedor en ejecución, siempre que no esté parado y esté ejecutando un comando que permita interacción (por ejemplo, "`/bin/sh`" o "`/bin/bash`"). Para desligar el terminal del contenedor está la secuencia ya mencionada: `Ctrl-PQ`.

---

## Resumen de los comandos de docker utilizados:
| Comando | Descripción |
| ------ | ------ |
| docker attach | Asocia el terminal del host al contenedor activo. |
| docker exec | Abre un nuevo shell o ejecuta un comando en el contenedor. |
| docker create imagen | Crea un contenedor sin ejecutarlo. |
| docker restart | Reinicia un contenedor. |
| docker pause / unpause | Pausa o reanuda un contenedor en ejecución. |
| docker wait | Bloquea el terminal hasta que el contenedor indicado se detenga. |
| docker stop | Termina un contenedor enviando SIGTERM. |
| docker kill | Termina un contenedor enviando SIGKILL. |
