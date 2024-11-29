# Docker Intro
## Set up docker from zero

## Preparación del entrono

Usamos una maquina virtual de Ubuntu bajo Virtual Box.

Necesito saber qué distribución de Ubuntu (codename) estoy usando.
```sh
lsb_release -cs
```
> **Note:** En mi caso, estoy en la versión --jammy.

```sh
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

Tengo que modificar el fichero del repositorio:
```sh
sudo nano /etc/apt/sources.list.d/docker.list
```
Agrego el siguiente valor y comento lo que había antes:
```sh
deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu jammy stable
```

Actualizo la lista de repositorios. Actualizo el sistema. Instalo las dependencias de Docker:
```sh
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### TEST!
```sh
sudo docker run hello-world
```

## Creando usuarios para docker
```sh
sudo usermod -aG docker $USER
```
