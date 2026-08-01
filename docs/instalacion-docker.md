# Instalación de Docker: guía de referencia

## Estado de esta guía

El README original describía una instalación manual en una máquina virtual Ubuntu. Las prácticas actuales no reejecutaron esa instalación: se validaron sobre Kali GNU/Linux Rolling con Docker y Compose ya instalados.

Esta página sirve como orientación y remite a documentación mantenida. No constituye evidencia de una instalación ejecutada durante el laboratorio.

## Documentación oficial

- [Docker Engine en Ubuntu](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Engine en Debian](https://docs.docker.com/engine/install/debian/)
- [Plugin Docker Compose en Linux](https://docs.docker.com/compose/install/linux/)
- [Instalación de Docker Engine](https://docs.docker.com/engine/install/)

## Correcciones respecto de la guía inicial

- No se fija `arch=amd64`: debe utilizarse `dpkg --print-architecture`.
- No se fija `jammy`: debe utilizarse una versión compatible con el sistema real.
- La documentación oficial actual utiliza `docker.sources` y la clave bajo `/etc/apt/keyrings/docker.asc`.
- No se incluye `apt upgrade` completo como requisito.
- Deben revisarse paquetes en conflicto, versiones soportadas y firewall.
- Kali deriva de Debian; puede requerir el codename de la versión Debian correspondiente.
- Compose se verifica mediante `docker compose version`, no el comando legado `docker-compose`.

## Verificación utilizada

```bash
docker version --format 'Cliente: {{.Client.Version}} | Servidor: {{.Server.Version}}'
docker compose version
docker info --format 'Driver: {{.Driver}} | Sistema: {{.OperatingSystem}}'
```

Resultado observado:

```text
Cliente: 28.5.2+dfsg4 | Servidor: 28.5.2+dfsg4
Docker Compose version 2.40.3-3
Driver: overlay2 | Sistema: Kali GNU/Linux Rolling
```

## Seguridad

- El acceso al daemon Docker concede privilegios elevados sobre el host.
- La publicación de puertos puede interactuar con el firewall; deben revisarse las advertencias oficiales sobre iptables, nftables, ufw y `DOCKER-USER`.
- Los scripts de conveniencia se orientan principalmente a desarrollo o pruebas.
- No deben reutilizarse comandos antiguos sin comprobar distribución, versión, arquitectura y documentación vigente.
