# Ejemplo 2
## Gestionar contenedores con Docker

Este ejemplo muestra cómo:

1. Cómo consultar el estado de los contenedores.
2. Listar imágenes disponibles localmente.
3. Cambiar el nombre de un contenedor y detenerlo.
4. Visualizar contenedores en estado `Exited`.

---

## Pasos del ejemplo:

1. **Crear y ejecutar un contenedor:**
```
docker run hello-world
```
Este comando hace lo siguiente:
- Descarga y ejecuta la imagen `hello-world` si no está disponible localmente.
- Este contenedor imprime un mensaje y se detiene automáticamente.

2. **Ver los contenedores activos:**
```
docker ps
```
Este comando lista los contenedores en ejecución, pero no muestra aquellos contenedores que fueron detenidos.

Si queremos ver todos los contenedores usaremos el comando:
```
docker ps -a
```
De esta forma se listan todos los contenedores, incluidos los que están en estado `Exited`.

3. Listar las imágenes locales:**
```
docker image ls
```
Sirve para mostrar todas las imágenes descargadas en nuestra máquina, indicando su tamaño, ID y fecha de creación.

4. **Cambiar el nombre de un contenedor:**
```
docker rename [contenedor] [nuevo_nombre]
```
Asigna un nuevo nombre a un contenedor ya existente.

5. **Detener un contenedor:**
```
docker stop [contenedor]
```
Detiene un contenedor que está en ejecución.

---
## Resumen de los comandos de docker utilizados:
| Comando | Descripción |
| ------ | ------ |
| docker rename | Cambia el nombre de un contenedor. |
| docker stop | Detiene un contenedor que está en ejecución. |

Con este ejemplo hemos asentado los conceptos básicos de cómo Docker maneja contenedores e imágenes, así como sus estados. 🚀
