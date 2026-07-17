# Security

## Data flow

The only external request is for google oauth, which is used to ensure only institutional accounts can log in.

## External Services

| Service | Description |
| --- | --- |
| Google OAuth | User authentication |

## Self-hosted services

1. Redis (docker)
2. Mysql (docker)
3. FastAPI (repo image in `/backend`)
4. Web build (from flutter) (repo image in `/frontend`)

Details in `/docker/docker-compose.yml` and docker files