#!/bin/bash
# =============================================================
# Echo Envia - Managed Identity Setup for ACR Access
#
# Run this ONCE after initial infrastructure deployment.
# Grants App Services permission to pull images from ACR
# using Managed Identity (no stored credentials needed).
#
# Requirements: Azure CLI, Owner/User Access Administrator role
# =============================================================

set -e

RG="rg_delivery2"
ACR_NAME="acrechoenviadevb4ab45f0"
APPS=("app-echo-envia-dev-1" "app-echo-envia-dev-2")

echo "Getting ACR resource ID..."
ACR_ID=$(az acr show --name "$ACR_NAME" --resource-group "$RG" --query id -o tsv)
echo "ACR: $ACR_ID"

for APP in "${APPS[@]}"; do
    echo ""
    echo "=== Configuring: $APP ==="

    # Enable system-assigned managed identity
    echo "  Enabling Managed Identity..."
    PRINCIPAL_ID=$(az webapp identity assign \
        --name "$APP" \
        --resource-group "$RG" \
        --query principalId -o tsv)
    echo "  Principal ID: $PRINCIPAL_ID"

    # Assign AcrPull role
    echo "  Assigning AcrPull role..."
    az role assignment create \
        --assignee "$PRINCIPAL_ID" \
        --role AcrPull \
        --scope "$ACR_ID" \
        --output none
    echo "  AcrPull role assigned"

    # Configure App Service to use Managed Identity for ACR auth
    echo "  Enabling Managed Identity for container pulls..."
    APP_ID=$(az webapp show --name "$APP" --resource-group "$RG" --query id -o tsv)
    az resource update \
        --ids "${APP_ID}/config/web" \
        --set properties.acrUseManagedIdentityCreds=true \
        --output none
    echo "  Managed Identity ACR auth enabled"
done

echo ""
echo "Managed Identity setup complete for all apps."
echo "   Apps can now pull from $ACR_NAME without stored credentials."
