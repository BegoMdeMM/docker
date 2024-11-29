# Docker Intro
## Configuración de Docker desde cero

Este documento describe cómo preparar un entorno Linux basado en Ubuntu dentro de una máquina virtual utilizando VirtualBox y configurar Docker desde cero.

---

## Preparación del entorno

1.- **Sistema base:**
   Usaremos una máquina virtual con Ubuntu como sistema operativo, ejecutándose en VirtualBox. 
   
   Asegúrate de que tu sistema esté actualizado y que tengas acceso como usuario con privilegios `sudo`.

2.- **Verificar la versión de Ubuntu:**
   Antes de instalar Docker, es importante saber qué versión (codename) de Ubuntu estás utilizando. Esto es útil para agregar los repositorios correctos más adelante.
   ```sh
   lsb_release -cs
   ```
   
   ## Instalación de Docker
1. **Configurar los repositorios de Docker**

Primero, nos aseguramos de que los paquetes esenciales para la instalación estén disponibles en el sistema.

```sh
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
```

Ahora, hay que descargar la clave GPG oficial de Docker para validar los paquetes firmados:

```sh
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

2. **Modificar el repositorio de APT**

Hay que modificar el archivo del repositorio de Docker:

```sh
sudo nano /etc/apt/sources.list.d/docker.list
```

Tenemos que agregar el siguiente contenido al archivo, reemplazando jammy con el codename de nuestra versión de Ubuntu (obtenido anteriormente con lsb_release -cs):

```sh
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable
```

> **Nota:** Hemos comentado las líneas existentes en el archivo, las cuales apuntaban a otros repositorios de Docker, para evitar conflictos.

3. **Instalar Docker**

Lo primero que hemos hechi ha sido actualizar la lista de paquetes y realizar una actualización del sistema para garantizar la compatibilidad.

```sh
sudo apt-get update
sudo apt-get upgrade -y
```

Instalamos Docker y sus componentes adicionales:

```sh
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Verificar la instalación
Para asegurarnos de que Docker está correctamente instalado, ejecutamos el siguiente comando:

```sh
sudo docker run hello-world
```

> **Nota:** Este comando descarga una imagen de prueba de Docker y ejecuta un contenedor simple. Deberemos ver un mensaje indicando que Docker está funcionando correctamente. Si este es el caso, ¡la instalación fue exitosa!

¡Nuestro entorno Docker ahora está listo para usarse! 🚀

---