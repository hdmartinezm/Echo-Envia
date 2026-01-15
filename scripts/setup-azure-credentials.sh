#!/bin/bash

# Script para configurar credenciales de Azure para GitHub Actions
# Uso: ./setup-azure-credentials.sh

set -e

echo "================================================"
echo "Configuración de Azure Service Principal"
echo "para GitHub Actions - Proyecto Envia"
echo "================================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que Azure CLI está instalado
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI no está instalado${NC}"
    echo "Instala Azure CLI desde: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

echo -e "${GREEN}✓ Azure CLI encontrado${NC}"
echo ""

# Login a Azure
echo "Iniciando sesión en Azure..."
az login

echo ""
echo "Obteniendo información de la suscripción..."

# Obtener Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)

echo -e "${GREEN}Suscripción activa:${NC}"
echo "  Nombre: $SUBSCRIPTION_NAME"
echo "  ID: $SUBSCRIPTION_ID"
echo ""

# Confirmar suscripción
read -p "¿Es esta la suscripción correcta? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cambia de suscripción con: az account set --subscription <subscription-id>"
    exit 1
fi

# Nombre del Service Principal
SP_NAME="github-actions-terraform-envia"

echo ""
echo "Creando Service Principal: $SP_NAME"
echo ""

# Crear Service Principal
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Service Principal creado exitosamente${NC}"
else
    echo -e "${RED}Error al crear Service Principal${NC}"
    exit 1
fi

echo ""
echo "================================================"
echo "CREDENCIALES GENERADAS"
echo "================================================"
echo ""
echo -e "${YELLOW}IMPORTANTE: Guarda estas credenciales de forma segura${NC}"
echo -e "${YELLOW}Solo se mostrarán una vez${NC}"
echo ""

# Extraer valores individuales
CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.clientId')
CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.clientSecret')
TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenantId')

echo "================================================"
echo "Secrets para GitHub Actions:"
echo "================================================"
echo ""
echo "1. AZURE_CREDENTIALS (JSON completo):"
echo "---"
echo "$SP_OUTPUT" | jq .
echo "---"
echo ""
echo "2. ARM_CLIENT_ID:"
echo "$CLIENT_ID"
echo ""
echo "3. ARM_CLIENT_SECRET:"
echo "$CLIENT_SECRET"
echo ""
echo "4. ARM_SUBSCRIPTION_ID:"
echo "$SUBSCRIPTION_ID"
echo ""
echo "5. ARM_TENANT_ID:"
echo "$TENANT_ID"
echo ""

# Guardar en archivo temporal
TEMP_FILE="azure-credentials-$(date +%Y%m%d-%H%M%S).json"
echo "$SP_OUTPUT" | jq . > "$TEMP_FILE"

echo "================================================"
echo "Próximos pasos:"
echo "================================================"
echo ""
echo "1. Ve a tu repositorio de GitHub:"
echo "   https://github.com/hdmartinezm/Echo-Envia/settings/secrets/actions"
echo ""
echo "2. Agrega los siguientes secrets:"
echo "   - AZURE_CREDENTIALS (contenido del JSON completo)"
echo "   - ARM_CLIENT_ID"
echo "   - ARM_CLIENT_SECRET"
echo "   - ARM_SUBSCRIPTION_ID"
echo "   - ARM_TENANT_ID"
echo ""
echo "3. Las credenciales también se guardaron en:"
echo "   $TEMP_FILE"
echo ""
echo -e "${RED}⚠️  IMPORTANTE: Elimina este archivo después de configurar GitHub${NC}"
echo "   rm $TEMP_FILE"
echo ""
echo "4. Lee la guía completa en:"
echo "   docs/github-azure-setup.md"
echo ""
echo -e "${GREEN}✓ Configuración completada${NC}"
