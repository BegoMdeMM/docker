# Ejemplo 1
## Crear y modificar contenedores e imágenes en Docker

Este ejemplo muestra cómo:

1. Ejecutar un contenedor a partir de una imagen (`docker run`).
2. Crear una imagen a partir de un contenedor (`docker commit`).

Además, aprenderemos a realizar operaciones básicas como listar imágenes, ver el historial de capas, y gestionar contenedores (detenerlos y eliminarlos).

---

## Pasos del ejemplo:

1. Ejecutar un contenedor basado en la imagen `alpine` y asignarle el nombre `alpine_orig_cont`:
```
docker run -it --name=alpine_orig_cont alpine /bin/sh
```
El contenedor ejecutará un shell interactivo (/bin/sh).
- `docker run`: Crea y ejecuta un contenedor basado en la imagen especificada (en este caso, alpine).
- `-it`:
    - `-i`: Mantiene la entrada estándar abierta.
    - `-t`: Crea una terminal interactiva.
- `--name=alpine_orig_cont`: Asigna un nombre al contenedor (`alpine_orig_cont`).
- `alpine /bin/sh`: Usa la imagen alpine y ejecuta el shell /bin/sh.

En este punto, tenemos un contenedor interactivo corriendo. Podemos ejecutar comandos dentro del contenedor.
2. Dentro del contenedor, realizar algún cambio (por ejemplo, crear un archivo):
```
/ # touch hello
```
Salimos del contenedor sin detenerlo usando `Ctrl-P + Ctrl-Q`.
3. Comprobar los contenedores en ejecución:
```
docker ps
```
Muestra una lista de contenedores que están corriendo. Podemos verificar que `alpine_orig_cont` sigue en ejecución.
4. Crear una nueva imagen llamada `alpine_new` a partir del contenedor `alpine_orig_cont`:
```
docker commit alpine_orig_cont alpine_new
```
- `docker commit`: Crea una nueva imagen basada en el estado actual del contenedor.
- `alpine_orig_cont`: El contenedor del que se crea la imagen.
- `alpine_new`: Nombre de la nueva imagen.
5. Ver las imágenes disponibles:
```
docker image ls
```
6. Comparar las capas de la nueva imagen (`alpine_new`) con la imagen original (`alpine`):
```
docker history alpine_new
docker history alpine
```
7. Detener y eliminar el contenedor original:
```
docker stop alpine_orig_cont
docker rm alpine_orig_cont
```
8. Crear un nuevo contenedor basado en la imagen `alpine_new`:
```
docker run -it alpine_new /bin/sh
```
Dentro del nuevo contenedor, verificamos los cambios:
```
/ # ls
```
Deberíamos ver el archivo hello creado en el paso 2.
9. Salir del contenedor y verificar los contenedores detenidos:
```
docker ps -a
```
10. Eliminar el contenedor creado:
```
docker rm [nombre_del_contenedor]
```

---
## Resumen de los comandos de docker utilizados:
| Comando | Descripción |
| ------ | ------ |
| docker run | Ejecuta un nuevo contenedor basado en una imagen. |
| docker commit | Crea una imagen desde un contenedor en ejecución. |
| docker ps / docker ps -a | Lista contenedores activos / todos los contenedores. |
| docker image ls | Muestra las imágenes disponibles en el sistema. |
| docker history | Muestra las capas de una imagen. |
| docker stop / docker rm | Detiene / elimina un contenedor. |

Con este ejemplo hemos conseguido aprender a manejar los conceptos básicos de contenedores e imágenes en Docker. 🚀