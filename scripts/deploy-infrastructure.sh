#!/bin/bash

# Script de despliegue de infraestructura con Terraform
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
    log_error "Uso: $0 <environment> [action]"
    echo "  environment: dev, staging, prod"
    echo "  action: plan, apply, destroy (default: plan)"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-plan}
TERRAFORM_DIR="../terraform"
VAR_FILE="environments/${ENVIRONMENT}.tfvars"

# Validar entorno
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    log_error "Entorno inválido. Debe ser: dev, staging o prod"
    exit 1
fi

# Validar acción
if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    log_error "Acción inválida. Debe ser: plan, apply o destroy"
    exit 1
fi

log_info "Iniciando despliegue de infraestructura"
log_info "Entorno: $ENVIRONMENT"
log_info "Acción: $ACTION"

# Verificar prerrequisitos
log_step "Verificando prerrequisitos..."

if ! command -v terraform &> /dev/null; then
    log_error "Terraform no está instalado"
    exit 1
fi

if ! command -v az &> /dev/null; then
    log_error "Azure CLI no está instalado"
    exit 1
fi

if ! az account show &> /dev/null; then
    log_error "No estás autenticado en Azure. Ejecuta 'az login'"
    exit 1
fi

log_info "Prerrequisitos verificados ✓"

# Cambiar al directorio de Terraform
cd "$TERRAFORM_DIR"

# Verificar que existe el archivo de variables
if [ ! -f "$VAR_FILE" ]; then
    log_error "Archivo de variables no encontrado: $VAR_FILE"
    exit 1
fi

# Inicializar Terraform
log_step "Inicializando Terraform..."
terraform init -upgrade

# Validar configuración
log_step "Validando configuración..."
terraform validate

if [ $? -ne 0 ]; then
    log_error "La configuración de Terraform no es válida"
    exit 1
fi

log_info "Configuración válida ✓"

# Ejecutar acción
case $ACTION in
    plan)
        log_step "Generando plan de ejecución..."
        terraform plan -var-file="$VAR_FILE" -out="tfplan-${ENVIRONMENT}.out"
        log_info "Plan generado exitosamente"
        log_info "Para aplicar los cambios, ejecuta: $0 $ENVIRONMENT apply"
        ;;
    
    apply)
        log_step "Aplicando cambios..."
        
        if [ -f "tfplan-${ENVIRONMENT}.out" ]; then
            log_info "Usando plan previamente generado"
            terraform apply "tfplan-${ENVIRONMENT}.out"
        else
            log_warn "No se encontró un plan previo, generando uno nuevo..."
            terraform apply -var-file="$VAR_FILE" -auto-approve
        fi
        
        log_info "Infraestructura desplegada exitosamente ✓"
        
        # Mostrar outputs
        log_step "Información del despliegue:"
        terraform output
        
        # Guardar outputs en archivo
        terraform output -json > "outputs-${ENVIRONMENT}.json"
        log_info "Outputs guardados en: outputs-${ENVIRONMENT}.json"
        ;;
    
    destroy)
        log_warn "¡ADVERTENCIA! Estás a punto de destruir la infraestructura de $ENVIRONMENT"
        read -p "¿Estás seguro? (escribe 'yes' para confirmar): " confirmation
        
        if [ "$confirmation" != "yes" ]; then
            log_info "Operación cancelada"
            exit 0
        fi
        
        log_step "Destruyendo infraestructura..."
        terraform destroy -var-file="$VAR_FILE" -auto-approve
        log_info "Infraestructura destruida"
        ;;
esac

log_info "Proceso completado exitosamente ✓"
