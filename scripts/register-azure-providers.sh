#!/bin/bash

# Script para registrar los Resource Providers necesarios en Azure
# Ejecutar este script una vez antes del primer despliegue

set -e

echo "================================================"
echo "Registrando Azure Resource Providers"
echo "================================================"
echo ""

# Lista de providers necesarios para el proyecto
PROVIDERS=(
  "Microsoft.Network"
  "Microsoft.Web"
  "Microsoft.DBforMySQL"
  "Microsoft.Storage"
  "Microsoft.KeyVault"
  "Microsoft.Compute"
)

echo "Verificando autenticación en Azure..."
az account show > /dev/null 2>&1 || {
  echo "Error: No estás autenticado en Azure"
  echo "Ejecuta: az login"
  exit 1
}

echo "✓ Autenticado correctamente"
echo ""

for provider in "${PROVIDERS[@]}"; do
  echo "Registrando $provider..."
  az provider register --namespace "$provider" --wait
  echo "✓ $provider registrado"
done

echo ""
echo "================================================"
echo "✓ Todos los Resource Providers registrados"
echo "================================================"
echo ""
echo "Ahora puedes ejecutar Terraform:"
echo "  cd terraform"
echo "  terraform init"
echo "  terraform plan -var-file=environments/dev.tfvars"
