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
1. download docker compose file from the repo
    - backend only ([link](https://github.com/Starry03/mschool/blob/master/backend/docker-compose.prod.yml))
    - backend + web frontend ([link](https://github.com/Starry03/mschool/blob/master/docker/docker-compose.prod.yml))
1. download the env example file ([link](https://github.com/Starry03/mschool/blob/master/backend/.env.example))
    - rename it to .env
1. modify credentials in docker compose file(s)
1. optional: change port mapping

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

#### Create admin user

First logged in account will be set as admin
