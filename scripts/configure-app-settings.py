#!/usr/bin/env python3
"""
Echo Envia - Azure App Service Settings Configurator

Configures all required environment variables for the Echo Envia
Laravel application on Azure App Service.

IMPORTANT: Uses Python subprocess + az rest (not bash) to avoid
shell history expansion corrupting passwords with special characters (!)

Usage:
    python3 scripts/configure-app-settings.py [--env dev|staging|prod]

Requirements:
    - Azure CLI installed and authenticated (az login)
    - Sufficient permissions on the App Services
"""

import json
import subprocess
import argparse
import sys

# ─── Configuration ────────────────────────────────────────────────────────────

SUBSCRIPTION_ID = "c603e7c0-d0c7-4981-8474-99ee145262a8"

ENVIRONMENTS = {
    "dev": {
        "resource_group": "rg_delivery2",
        "apps": ["app-echo-envia-dev-1", "app-echo-envia-dev-2"],
        "acr": "acrechoenviadevb4ab45f0.azurecr.io",
        "image_tag": "74",  # Use specific tag, NOT :latest (OCI multi-platform issue)
        "mysql_host": "mysql-echo-envia-dev-a074ba49.mysql.database.azure.com",
        "mysql_db": "envia_delivery",
        "mysql_user": "echoadmin",
        "redis_name": "redis-echo-envia-dev",
        "redis_host": "tls://redis-echo-envia-dev.redis.cache.windows.net",
        "redis_port": "6380",  # SSL port - requires tls:// prefix in host
    }
}

# ─── Helpers ──────────────────────────────────────────────────────────────────

def run(cmd, check=True):
    result = subprocess.run(cmd, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"ERROR: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip()

def get_redis_key(redis_name, resource_group):
    return run([
        "az", "redis", "list-keys",
        "--name", redis_name,
        "--resource-group", resource_group,
        "--query", "primaryKey", "-o", "tsv"
    ])

def get_db_password():
    """Get DB password from environment variable or prompt."""
    import os
    password = os.environ.get("DB_PASSWORD")
    if not password:
        import getpass
        password = getpass.getpass("Enter DB_PASSWORD (echoadmin): ")
    return password

def get_app_key():
    """Get or generate APP_KEY."""
    import os
    key = os.environ.get("APP_KEY")
    if not key:
        import base64
        key = "base64:" + base64.b64encode(os.urandom(32)).decode("utf-8")
        print(f"  Generated new APP_KEY: {key[:20]}...")
        print("  WARNING: SAVE THIS KEY - changing it invalidates all sessions/encrypted data")
    return key

# ─── Main ─────────────────────────────────────────────────────────────────────

def configure_app(app_name, env_config, db_password, app_key):
    resource_group = env_config["resource_group"]
    sub = SUBSCRIPTION_ID
    base_url = f"https://management.azure.com/subscriptions/{sub}/resourceGroups/{resource_group}/providers/Microsoft.Web/sites/{app_name}"

    print(f"\n{'='*60}")
    print(f"  Configuring: {app_name}")
    print(f"{'='*60}")

    # Get Redis key
    print("  Getting Redis key...")
    redis_key = get_redis_key(env_config["redis_name"], resource_group)

    # Build complete settings dict
    settings = {
        # Application
        "APP_KEY": app_key,
        "APP_ENV": "production",
        "APP_DEBUG": "false",
        "APP_URL": f"https://{app_name}.azurewebsites.net",

        # Database
        "DB_CONNECTION": "mysql",
        "DB_HOST": env_config["mysql_host"],
        "DB_PORT": "3306",
        "DB_DATABASE": env_config["mysql_db"],
        "DB_USERNAME": env_config["mysql_user"],
        "DB_PASSWORD": db_password,

        # Redis - IMPORTANT: host must have tls:// prefix for Azure Redis (port 6380)
        "REDIS_HOST": env_config["redis_host"],
        "REDIS_PASSWORD": redis_key,
        "REDIS_PORT": env_config["redis_port"],
        "REDIS_CLIENT": "phpredis",
        "REDIS_DB": "0",
        "REDIS_CACHE_DB": "1",
        "REDIS_SESSION_DB": "2",
        "REDIS_QUEUE_DB": "3",

        # Cache / Session / Queue
        "CACHE_STORE": "redis",
        "CACHE_PREFIX": "envia-delivery-cache-",
        "SESSION_DRIVER": "redis",
        "SESSION_CONNECTION": "session",
        "SESSION_LIFETIME": "120",
        "QUEUE_CONNECTION": "redis",
        "REDIS_QUEUE_CONNECTION": "queue",
        "REDIS_QUEUE": "default",

        # Deployment control
        "RUN_MIGRATIONS": "false",  # Keep false - migrations run manually
        "WEBSITES_ENABLE_APP_SERVICE_STORAGE": "false",  # Use container filesystem only
    }

    # Write body to temp file (avoids any shell escaping)
    body_file = f"/tmp/appsettings_{app_name}.json"
    with open(body_file, "w") as f:
        json.dump({"properties": settings}, f)

    # PUT settings via az rest
    print("  Applying settings...")
    result = subprocess.run(
        ["az", "rest", "--method", "PUT",
         "--uri", f"{base_url}/config/appsettings?api-version=2022-03-01",
         "--body", f"@{body_file}",
         "--query", "{APP_KEY:properties.APP_KEY,APP_ENV:properties.APP_ENV,DB_CONNECTION:properties.DB_CONNECTION,DB_HOST:properties.DB_HOST,REDIS_HOST:properties.REDIS_HOST,RUN_MIGRATIONS:properties.RUN_MIGRATIONS}",
         "-o", "json"],
        capture_output=True, text=True
    )
    data = json.loads(result.stdout)
    print(f"  APP_KEY:          {data.get('APP_KEY','')[:20]}...")
    print(f"  APP_ENV:          {data.get('APP_ENV')}")
    print(f"  DB_CONNECTION:    {data.get('DB_CONNECTION')}")
    print(f"  DB_HOST:          {data.get('DB_HOST','')[:50]}")
    print(f"  REDIS_HOST:       {data.get('REDIS_HOST','')[:50]}")
    print(f"  RUN_MIGRATIONS:   {data.get('RUN_MIGRATIONS')}")
    print(f"  Settings applied")

    # Configure container image
    print(f"  Configuring container image tag:{env_config['image_tag']}...")
    subprocess.run([
        "az", "webapp", "config", "container", "set",
        "--name", app_name,
        "--resource-group", resource_group,
        "--docker-custom-image-name", f"{env_config['acr']}/echo-envia-app:{env_config['image_tag']}",
        "--output", "none"
    ], check=True)
    print(f"  Container image set to :{env_config['image_tag']}")


def main():
    parser = argparse.ArgumentParser(description="Configure Echo Envia App Service settings")
    parser.add_argument("--env", default="dev", choices=["dev", "staging", "prod"],
                        help="Environment to configure (default: dev)")
    args = parser.parse_args()

    env_config = ENVIRONMENTS[args.env]
    db_password = get_db_password()
    app_key = get_app_key()

    for app in env_config["apps"]:
        configure_app(app, env_config, db_password, app_key)

    print(f"\n{'='*60}")
    print("  All apps configured. Restart to apply:")
    for app in env_config["apps"]:
        print(f"    az webapp restart --name {app} --resource-group {env_config['resource_group']}")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
