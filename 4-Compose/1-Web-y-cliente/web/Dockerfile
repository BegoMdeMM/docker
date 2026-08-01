# syntax=docker/dockerfile:1

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

RUN addgroup -S app \
    && adduser -S -G app app

WORKDIR /site

COPY --chown=app:app --chmod=0444 index.html ./index.html
COPY --chown=app:app --chmod=0555 server.sh ./server.sh

USER app

EXPOSE 8080

CMD ["/site/server.sh"]
