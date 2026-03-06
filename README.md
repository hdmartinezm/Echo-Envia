# Echo Envia — Azure Infrastructure

Infrastructure and deployment scripts for the **Echo Envia** admin panel (Laravel + Filament) on Azure.

The application code lives in a separate repository. This repo contains:
- Azure infrastructure (Terraform)
- Deployment and configuration scripts
- Operations runbooks

---

## Stack

| Component | Technology |
|---|---|
| Application | PHP 8.3 / Laravel 11 / Filament (Dockerized) |
| Container Registry | Azure Container Registry (ACR) |
| Hosting | Azure App Service (Linux Container) |
| Database | Azure MySQL Flexible Server 8.0 |
| Cache / Queue | Azure Redis Cache (TLS, port 6380) |
| Auth (ACR pull) | Managed Identity (AcrPull role) |

---

## Active Resources (Dev)

| Resource | Name |
|---|---|
| Resource Group | rg_delivery2 |
| App Services | app-echo-envia-dev-1, app-echo-envia-dev-2 |
| Container Registry | acrechoenviadevb4ab45f0.azurecr.io |
| MySQL Server | mysql-echo-envia-dev-a074ba49.mysql.database.azure.com |
| Redis | redis-echo-envia-dev.redis.cache.windows.net:6380 |
| Database | envia_delivery |
| DB User | echoadmin |

---

## Initial Setup

### 1. Infrastructure
```bash
# Register required Azure providers (once per subscription)
bash scripts/register-azure-providers.sh

# Set up GitHub Actions credentials
bash scripts/setup-azure-credentials.sh

# Deploy infrastructure via GitHub Actions
# → .github/workflows/terraform-minimal.yml
```

### 2. Database Setup
```bash
# Creates envia_delivery database and echoadmin user
DB_PASSWORD="your_password" bash scripts/setup-database.sh
```

### 3. Managed Identity (ACR Access)
```bash
# Run ONCE - grants App Services permission to pull from ACR
# Requires Owner or User Access Administrator role
bash scripts/setup-managed-identity.sh
```

### 4. Configure App Settings
```bash
# Sets all required environment variables in both App Services
# Uses Python to avoid bash shell escaping issues with special characters
DB_PASSWORD="your_password" APP_KEY="base64:xxx..." python3 scripts/configure-app-settings.py
```

---

## Deployment

### Build & Push Image
The application Dockerfile lives in the app repo. After a successful build:
```bash
# Tag and push to ACR (done by CI/CD in the app repo)
az acr login --name acrechoenviadevb4ab45f0
docker build -t acrechoenviadevb4ab45f0.azurecr.io/echo-envia-app:74 .
docker push acrechoenviadevb4ab45f0.azurecr.io/echo-envia-app:74
```

> **Do NOT use the `:latest` tag** — Azure App Service cannot pull OCI multi-platform manifests. Always use a specific numeric tag (e.g., `:74`).

### Restart App Services
```bash
az webapp restart --name app-echo-envia-dev-1 --resource-group rg_delivery2
az webapp restart --name app-echo-envia-dev-2 --resource-group rg_delivery2
```

---

## Known Issues & Solutions

### DB_PASSWORD corruption (bash `!` history expansion)
Never set `DB_PASSWORD` via bash if the password contains `!`. Use the Python script instead:
```bash
# WRONG — bash corrupts passwords with ! character
az webapp config appsettings set ... --settings DB_PASSWORD="Y&j9!pass"

# CORRECT — use configure-app-settings.py
DB_PASSWORD="Y&j9!pass" python3 scripts/configure-app-settings.py
```

### Redis TLS requirement
Azure Redis Cache requires TLS on port 6380. The `REDIS_HOST` must have the `tls://` prefix:
```
REDIS_HOST=tls://redis-echo-envia-dev.redis.cache.windows.net
REDIS_PORT=6380
```

### Image tag `:latest` fails
Use specific numeric tags. The `:latest` tag points to an OCI multi-platform manifest that Azure App Service cannot pull.

### APP_KEY missing
Laravel requires `APP_KEY` in Azure App Settings. The `.env` file is excluded from the Docker image via `.dockerignore`. Set it via `configure-app-settings.py`.

---

## Scripts Reference

| Script | Purpose |
|---|---|
| `scripts/configure-app-settings.py` | Set all Azure App Service environment variables |
| `scripts/setup-managed-identity.sh` | Grant AcrPull role to App Service identities |
| `scripts/setup-database.sh` | Create MySQL database and application user |
| `scripts/database/init.sql` | SQL for database/user creation |
| `scripts/setup-azure-credentials.sh` | Create Service Principal for GitHub Actions |
| `scripts/register-azure-providers.sh` | Register required Azure resource providers |
| `scripts/deploy-infrastructure.sh` | Deploy Terraform infrastructure |
| `scripts/cleanup-resources.sh` | Remove Azure resources |

---

## Required App Settings

All of these must be set in Azure App Service (via `configure-app-settings.py`):

```
APP_KEY                         base64:...  (Laravel encryption key)
APP_ENV                         production
APP_DEBUG                       false
APP_URL                         https://<app-name>.azurewebsites.net
DB_CONNECTION                   mysql
DB_HOST                         mysql-echo-envia-dev-a074ba49.mysql.database.azure.com
DB_PORT                         3306
DB_DATABASE                     envia_delivery
DB_USERNAME                     echoadmin
DB_PASSWORD                     <from secrets>
REDIS_HOST                      tls://redis-echo-envia-dev.redis.cache.windows.net
REDIS_PASSWORD                  <from Azure Redis>
REDIS_PORT                      6380
REDIS_CLIENT                    phpredis
REDIS_DB                        0
REDIS_CACHE_DB                  1
REDIS_SESSION_DB                2
REDIS_QUEUE_DB                  3
CACHE_STORE                     redis
CACHE_PREFIX                    envia-delivery-cache-
SESSION_DRIVER                  redis
SESSION_CONNECTION              session
SESSION_LIFETIME                120
QUEUE_CONNECTION                redis
REDIS_QUEUE_CONNECTION          queue
REDIS_QUEUE                     default
RUN_MIGRATIONS                  false
WEBSITES_ENABLE_APP_SERVICE_STORAGE  false
```
