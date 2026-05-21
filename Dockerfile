# syntax=docker/dockerfile:1.7

# Stage 1 — compila Flutter web
FROM ghcr.io/cirruslabs/flutter:3.38.3 AS build

WORKDIR /app

# Cache de dependencias: copia primero los manifests.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Fuente
COPY . .

# Variables que sobreescriben los `String.fromEnvironment` del código.
ARG API_BASE_URL
ARG GOOGLE_WEB_CLIENT_ID

RUN flutter pub get && \
    flutter build web --release \
      --dart-define=API_BASE_URL=${API_BASE_URL} \
      --dart-define=GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID}

# Stage 2 — sirve los estáticos con nginx
FROM nginx:1.27-alpine

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Healthcheck simple para Coolify / Traefik
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
