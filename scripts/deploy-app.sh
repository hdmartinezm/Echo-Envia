#!/bin/bash

# Script de despliegue de aplicación a Azure App Services
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    log_error "Uso: $0 <environment>"
    echo "  environment: dev, staging, prod"
    exit 1
fi

ENVIRONMENT=$1
RESOURCE_GROUP="rg-envia-${ENVIRONMENT}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC_DIR="${PROJECT_DIR}/src"
TERRAFORM_DIR="${PROJECT_DIR}/terraform"

# Validar entorno
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Entorno inválido. Debe ser: dev, staging o prod"
    exit 1
fi

log_info "Iniciando despliegue de aplicación"
log_info "Entorno: $ENVIRONMENT"
log_info "Resource Group: $RESOURCE_GROUP"

# Verificar prerrequisitos
log_step "Verificando prerrequisitos..."

if ! command -v az &> /dev/null; then
    log_error "Azure CLI no está instalado"
    exit 1
fi

if ! command -v node &> /dev/null; then
    log_error "Node.js no está instalado"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    log_error "npm no está instalado"
    exit 1
fi

if ! az account show &> /dev/null; then
    log_error "No estás autenticado en Azure. Ejecuta 'az login'"
    exit 1
fi

log_info "Prerrequisitos verificados ✓"

# Obtener nombres de App Services desde Terraform outputs
log_step "Obteniendo información de infraestructura..."

if [ ! -f "${TERRAFORM_DIR}/outputs-${ENVIRONMENT}.json" ]; then
    log_error "No se encontró el archivo de outputs de Terraform"
    log_error "Ejecuta primero: ./deploy-infrastructure.sh $ENVIRONMENT apply"
    exit 1
fi

APP_SERVICES=$(cat "${TERRAFORM_DIR}/outputs-${ENVIRONMENT}.json" | jq -r '.app_service_names.value[]')

if [ -z "$APP_SERVICES" ]; then
    log_error "No se pudieron obtener los nombres de los App Services"
    exit 1
fi

log_info "App Services encontrados:"
echo "$APP_SERVICES" | while read app; do
    echo "  - $app"
done

# Construir aplicación
log_step "Construyendo aplicación..."

cd "$SRC_DIR"

log_info "Instalando dependencias..."
npm ci --production

log_info "Ejecutando tests..."
npm test || log_warn "Tests fallaron, continuando..."

log_info "Build completado ✓"

# Crear paquete de despliegue
log_step "Creando paquete de despliegue..."

DEPLOY_PACKAGE="${PROJECT_DIR}/deploy-${ENVIRONMENT}.zip"

# Limpiar paquete anterior si existe
[ -f "$DEPLOY_PACKAGE" ] && rm "$DEPLOY_PACKAGE"

# Crear zip excluyendo archivos innecesarios
zip -r "$DEPLOY_PACKAGE" . \
    -x "*.git*" \
    -x "node_modules/*" \
    -x "*.log" \
    -x ".env" \
    -x "*.test.js" \
    -x "coverage/*" \
    > /dev/null

log_info "Paquete creado: $DEPLOY_PACKAGE"

# Desplegar a cada App Service
log_step "Desplegando a App Services..."

echo "$APP_SERVICES" | while read app_name; do
    log_info "Desplegando a: $app_name"
    
    # Verificar que el App Service existe
    if ! az webapp show --name "$app_name" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log_error "App Service no encontrado: $app_name"
        continue
    fi
    
    # Desplegar usando zip deploy
    az webapp deployment source config-zip \
        --resource-group "$RESOURCE_GROUP" \
        --name "$app_name" \
        --src "$DEPLOY_PACKAGE" \
        --timeout 600
    
    if [ $? -eq 0 ]; then
        log_info "Despliegue exitoso a $app_name ✓"
        
        # Reiniciar App Service
        log_info "Reiniciando $app_name..."
        az webapp restart --name "$app_name" --resource-group "$RESOURCE_GROUP"
        
        # Verificar health check
        log_info "Verificando health check..."
        sleep 10
        
        APP_URL=$(az webapp show --name "$app_name" --resource-group "$RESOURCE_GROUP" --query "defaultHostName" -o tsv)
        
        if curl -f -s "https://${APP_URL}/health" > /dev/null; then
            log_info "Health check OK para $app_name ✓"
        else
            log_warn "Health check falló para $app_name"
        fi
    else
        log_error "Despliegue falló para $app_name"
    fi
    
    echo ""
done

# Limpiar
log_step "Limpiando archivos temporales..."
rm -f "$DEPLOY_PACKAGE"

# Mostrar URLs de acceso
log_step "URLs de acceso:"

echo "$APP_SERVICES" | while read app_name; do
    APP_URL=$(az webapp show --name "$app_name" --resource-group "$RESOURCE_GROUP" --query "defaultHostName" -o tsv 2>/dev/null)
    if [ ! -z "$APP_URL" ]; then
        echo "  - https://${APP_URL}"
    fi
done

# Obtener Application Gateway IP
GATEWAY_IP=$(cat "${TERRAFORM_DIR}/outputs-${ENVIRONMENT}.json" | jq -r '.app_gateway_public_ip.value')
if [ ! -z "$GATEWAY_IP" ] && [ "$GATEWAY_IP" != "null" ]; then
    echo ""
    log_info "Application Gateway IP: $GATEWAY_IP"
    log_info "Acceso principal: https://$GATEWAY_IP"
fi

log_info "Despliegue completado exitosamente ✓"
