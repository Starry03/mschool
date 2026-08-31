# Stage 1: Build Flutter Web frontend
FROM debian:stable-slim AS build-frontend

RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash builder
USER builder
WORKDIR /home/builder

RUN git clone --depth 1 https://github.com/flutter/flutter.git -b stable /home/builder/flutter
ENV PATH="/home/builder/flutter/bin:/home/builder/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN flutter config --enable-web && \
    flutter precache --web

WORKDIR /home/builder/app
COPY --chown=builder:builder frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

COPY --chown=builder:builder frontend/ .
RUN flutter build web --release

# Stage 2: Backend + Serve Frontend
FROM python:3.10-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/backend

WORKDIR /backend

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libmariadb-dev \
    gcc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt /backend/
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend files and migrations
COPY backend/alembic.ini /backend/
COPY backend/alembic /backend/alembic
COPY backend/entrypoint.sh /backend/
RUN chmod +x /backend/entrypoint.sh
COPY backend/app /backend/app

# Copy the compiled Flutter web assets into backend/app/static
COPY --from=build-frontend /home/builder/app/build/web /backend/app/static

EXPOSE 8000

ENTRYPOINT ["/backend/entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
