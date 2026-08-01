# syntax=docker/dockerfile:1

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

LABEL org.opencontainers.image.title="Dockerfile básico"
LABEL org.opencontainers.image.description="Imagen mínima para demostrar una construcción reproducible"
LABEL org.opencontainers.image.source="https://github.com/BegoMdeMM/docker"
LABEL org.opencontainers.image.authors="BMdMM"

RUN addgroup -S app \
    && adduser -S -G app app

WORKDIR /app

COPY --chown=app:app --chmod=0444 mensaje.txt ./mensaje.txt

USER app

CMD ["cat", "/app/mensaje.txt"]
