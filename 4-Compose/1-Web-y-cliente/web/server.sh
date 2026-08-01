#!/bin/sh
set -eu

content_length="$(wc -c < /site/index.html | tr -d ' ')"

while true; do
  {
    printf 'HTTP/1.1 200 OK\r\n'
    printf 'Content-Type: text/html; charset=utf-8\r\n'
    printf 'Content-Length: %s\r\n' "$content_length"
    printf 'Connection: close\r\n'
    printf '\r\n'
    cat /site/index.html
  } | nc -l -p 8080
done
