#!/bin/bash
# =============================================================
# Echo Envia - Database Setup Script
#
# Creates the application database and user on Azure MySQL.
# Run ONCE after initial deployment or when resetting the database.
#
# Requirements: mysql-client, Azure CLI
# Usage: DB_PASSWORD="yourpassword" bash scripts/setup-database.sh
# =============================================================

set -e

RG="rg_delivery2"
MYSQL_SERVER="mysql-echo-envia-dev-a074ba49"
MYSQL_HOST="${MYSQL_SERVER}.mysql.database.azure.com"
ADMIN_USER="enviaadmin"
APP_USER="echoadmin"
APP_DB="envia_delivery"

# Get admin password (reset it to known value to proceed)
echo "Resetting MySQL admin password..."
ADMIN_PASS="Envia$(date +%Y)Dev.Setup$(date +%S)"
az mysql flexible-server update \
    --name "$MYSQL_SERVER" \
    --resource-group "$RG" \
    --admin-password "$ADMIN_PASS" \
    --output none

# Get app user password from environment or prompt
if [ -z "$DB_PASSWORD" ]; then
    read -s -p "Enter password for $APP_USER: " DB_PASSWORD
    echo
fi

# Add local IP to firewall temporarily
echo "Adding local IP to MySQL firewall..."
LOCAL_IP=$(curl -s https://api.ipify.org)
az mysql flexible-server firewall-rule create \
    --name "$MYSQL_SERVER" \
    --resource-group "$RG" \
    --rule-name "TempSetup-$(date +%s)" \
    --start-ip-address "$LOCAL_IP" \
    --end-ip-address "$LOCAL_IP" \
    --output none

sleep 5

echo "Creating database and user..."
python3 - <<PYEOF
import subprocess

HOST = "$MYSQL_HOST"
ADMIN = "$ADMIN_USER"
ADMIN_PASS = "$ADMIN_PASS"
APP_USER = "$APP_USER"
APP_PASS = "$DB_PASSWORD"
DB = "$APP_DB"

sql = f"""
CREATE DATABASE IF NOT EXISTS {DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '{APP_USER}'@'%' IDENTIFIED BY '{APP_PASS}';
ALTER USER '{APP_USER}'@'%' IDENTIFIED BY '{APP_PASS}';
GRANT ALL PRIVILEGES ON {DB}.* TO '{APP_USER}'@'%';
FLUSH PRIVILEGES;
SELECT user, host FROM mysql.user WHERE user = '{APP_USER}';
"""

result = subprocess.run(
    ["mysql", "-h", HOST, "-u", ADMIN, f"-p{ADMIN_PASS}", "--ssl-mode=REQUIRED", "--connect-timeout=20", "-e", sql],
    capture_output=True, text=True
)
print(result.stdout)
if result.returncode != 0:
    print("ERROR:", result.stderr)
    exit(1)
print(f"Database '{DB}' and user '{APP_USER}' created successfully")
PYEOF

echo ""
echo "Database setup complete."
echo "   Remember to:"
echo "   1. Remove the temporary firewall rule (TempSetup-*) from Azure Portal"
echo "   2. Run configure-app-settings.py to set DB_PASSWORD in App Services"
