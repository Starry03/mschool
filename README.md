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
2. set environment variables for oauth client credentials: backend/.env or docker-compose.yml.
3. create admin user (directly access db as there is not a first account creation thing)

#### Backend/.env
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
```

#### Docker-compose.yml:
```yaml
services:
    ...    
        environment:
            - PROJECT_ID=PROJECT_ID # change
            - AUTH_PROVIDER_X509_CERT_URL=https://www.googleapis.com/oauth2/v1/certs
            - AUTH_URI=https://accounts.google.com/o/oauth2/auth
            - TOKEN_URI=https://oauth2.googleapis.com/token
            - WEB_CLIENT_ID=WEB_CLIENT_ID # change
            - WEB_CLIENT_SECRET=WEB_CLIENT_SECRET # change
            - WEB_REDIRECT_URI=http://localhost:8080 # change
```


### Build and run

```sh
cd docker
docker compose up -d --build  # build & run
docker compose up -d          # run
```