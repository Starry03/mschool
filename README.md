# MSchool

One of the projects of the "just buy a nas and self-host everything" kind

Important: written by AI, reviewed as much as possible.

## Features

1. Data management
2. Teacher lessons schedule generation (modelled as SAT problem)

## Goal

Make a school buy a 200$ computer to protect the privacy of teachers, other workers and students

## Installation

### Setup

1. oauth has to be configured (https://console.cloud.google.com)
1. pull image (all-in-one or backend only) or download docker compose file
1. download env file
1. create admin user (directly access db as there is not a first account creation thing)

.env
```ini
# server config

# oauth
PROJECT_ID=PROJECT_ID
AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
AUTH_URI=https://accounts.google.com/o/oauth2/auth
TOKEN_URI=https://oauth2.googleapis.com/token

# web
WEB_CLIENT_ID=WEB_CLIENT_ID
WEB_CLIENT_SECRET=WEB_CLIENT_SECRET
WEB_REDIRECT_URI=http://localhost:8080

# desktop
DESKTOP_CLIENT_ID=DESKTOP_CLIENT_ID
DESKTOP_CLIENT_SECRET=DESKTOP_CLIENT_SECRET

# mobile
ANDROID_CLIENT_ID=ANDROID_CLIENT_ID
IOS_CLIENT_ID=IOS_CLIENT_ID
```

### Installation options

You can choose one of the following methods based on the hardware you have to host the service:

#### Option A: All-in-one stack (Frontend Web + Backend + Databases)

Host the full stack on a single server:

**For Development (local build from source):**
```sh
cd docker
docker compose up -d --build
```

**For Production (pull pre-built images from GitHub Container Registry):**
```sh
cd docker
docker compose -f docker-compose.prod.yml up -d
```

#### Option B: Host backend only (useful when running native compiled Desktop/Mobile clients)

Only host the database, redis cache, and FastAPI backend:

**For Development (local build from source):**
```sh
cd backend
docker compose up -d --build
```

**For Production (pull pre-built backend image from GHCR):**
```sh
cd backend
docker compose -f docker-compose.prod.yml up -d
```
