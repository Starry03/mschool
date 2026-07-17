# Stage 1: Build stage
FROM debian:stable-slim AS build-env

# Install base dependencies required by Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for building Flutter to avoid tar UID/GID extraction permission issues
RUN useradd -ms /bin/bash builder
USER builder
WORKDIR /home/builder

# Install Flutter SDK (stable channel, shallow clone to minimize size and speed up build)
RUN git clone --depth 1 https://github.com/flutter/flutter.git -b stable /home/builder/flutter

# Add flutter to environment path
ENV PATH="/home/builder/flutter/bin:/home/builder/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Enable web support and pre-download web artifacts
RUN flutter config --enable-web && \
    flutter precache --web

# Set working directory for app
WORKDIR /home/builder/app

# Copy dependency configuration files first to leverage Docker cache
COPY --chown=builder:builder pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the application source code
COPY --chown=builder:builder . .

# Build argument for compile-time API base URL config
ARG API_URL
RUN if [ -n "$API_URL" ]; then \
      flutter build web --release --dart-define=API_URL=$API_URL; \
    else \
      flutter build web --release; \
    fi

# Stage 2: Web Server Stage
FROM nginx:alpine

# Copy Nginx config file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build output from Stage 1
COPY --from=build-env /home/builder/app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
