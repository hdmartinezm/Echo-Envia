#!/bin/bash

# Script para limpiar recursos de Azure cuando hay conflictos con Terraform
# Uso: ./cleanup-resources.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
PROJECT_NAME="envia"
RESOURCE_GROUP="rg-${PROJECT_NAME}-${ENVIRONMENT}"

echo "================================================"
echo "Limpieza de Recursos de Azure"
echo "Proyecto: $PROJECT_NAME"
echo "Entorno: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP"
echo "================================================"
echo ""

# Verificar autenticación
az account show > /dev/null 2>&1 || {
  echo "Error: No estás autenticado en Azure"
  echo "Ejecuta: az login"
  exit 1
}

echo "✓ Autenticado correctamente"
echo ""

# Verificar si el Resource Group existe
if az group exists --name "$RESOURCE_GROUP" | grep -q "true"; then
  echo "⚠️  Resource Group '$RESOURCE_GROUP' existe"
  echo ""
  
  # Listar recursos
  echo "Recursos en el Resource Group:"
  az resource list --resource-group "$RESOURCE_GROUP" --output table
  echo ""
  
  # Confirmar eliminación
  read -p "¿Deseas eliminar el Resource Group y todos sus recursos? (y/n): " -n 1 -r
  echo ""
  
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Eliminando Resource Group '$RESOURCE_GROUP'..."
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    
    echo ""
    echo "✓ Eliminación iniciada (proceso asíncrono)"
    echo ""
    echo "Esperando a que se complete la eliminación..."
    
    # Esperar hasta que se elimine
    while az group exists --name "$RESOURCE_GROUP" | grep -q "true"; do
      echo -n "."
      sleep 5
    done
    
    echo ""
    echo ""
    echo "✓ Resource Group eliminado exitosamente"
  else
    echo "Operación cancelada"
    exit 0
  fi
else
  echo "✓ Resource Group '$RESOURCE_GROUP' no existe"
fi

echo ""
echo "================================================"
echo "Limpieza completada"
echo "================================================"
echo ""
echo "Ahora puedes ejecutar Terraform:"
echo "  cd terraform"
echo "  terraform init"
echo "  terraform plan -var-file=environments/${ENVIRONMENT}.tfvars"
echo "  terraform apply -var-file=environments/${ENVIRONMENT}.tfvars"
