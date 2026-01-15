# Guía de Migración: Bicep a Terraform

Esta guía te ayudará a migrar tu infraestructura existente de Azure Bicep a Terraform.

## 📋 Tabla de Contenidos

1. [Antes de Comenzar](#antes-de-comenzar)
2. [Estrategias de Migración](#estrategias-de-migración)
3. [Migración Paso a Paso](#migración-paso-a-paso)
4. [Importar Recursos Existentes](#importar-recursos-existentes)
5. [Validación Post-Migración](#validación-post-migración)
6. [Rollback](#rollback)

## Antes de Comenzar

### ⚠️ Advertencias Importantes

- La migración puede causar downtime si no se planifica correctamente
- Algunos recursos pueden necesitar ser recreados
- Haz backup de todos los datos críticos
- Prueba primero en un entorno de desarrollo

### ✅ Checklist Pre-Migración

- [ ] Backup de base de datos MySQL
- [ ] Backup de Storage Account
- [ ] Documentar configuración actual
- [ ] Exportar secretos de Key Vault
- [ ] Notificar al equipo sobre la migración
- [ ] Preparar plan de rollback

## Estrategias de Migración

### Opción 1: Greenfield (Recomendado para Dev)

**Descripción**: Crear nueva infraestructura desde cero

**Ventajas**:
- ✅ Más limpio y seguro
- ✅ Permite probar antes de migrar
- ✅ Sin riesgo de afectar producción

**Desventajas**:
- ❌ Requiere migración de datos
- ❌ Cambio de URLs/IPs

**Proceso**:
```bash
# 1. Desplegar nueva infraestructura con Terraform
cd Terraform-Envia
make apply ENV=dev

# 2. Migrar datos
# (Ver sección de migración de datos)

# 3. Probar nueva infraestructura

# 4. Cambiar DNS/routing

# 5. Destruir infraestructura antigua
cd ../AzureBicep-Envia
az group delete --name rg-azure-web-project-dev
```

### Opción 2: Import (Recomendado para Prod)

**Descripción**: Importar recursos existentes a Terraform

**Ventajas**:
- ✅ Sin downtime
- ✅ Mantiene IPs y configuración
- ✅ Migración gradual

**Desventajas**:
- ❌ Más complejo
- ❌ Requiere mapeo cuidadoso

**Proceso**:
```bash
# 1. Inicializar Terraform
cd Terraform-Envia/terraform
terraform init

# 2. Importar recursos uno por uno
# (Ver sección de importación)

# 3. Validar state

# 4. Aplicar cambios incrementales
```

### Opción 3: Híbrido

**Descripción**: Migrar servicios gradualmente

**Ventajas**:
- ✅ Riesgo distribuido
- ✅ Permite aprender gradualmente

**Desventajas**:
- ❌ Gestión dual temporal
- ❌ Más tiempo total

## Migración Paso a Paso

### Paso 1: Preparación

```bash
# 1. Clonar o actualizar repositorio
cd Terraform-Envia

# 2. Instalar herramientas
brew install terraform azure-cli jq

# 3. Login en Azure
az login

# 4. Verificar suscripción
az account show
```

### Paso 2: Documentar Estado Actual

```bash
# Exportar configuración actual
az group show --name rg-azure-web-project-dev > current-rg.json

# Listar todos los recursos
az resource list --resource-group rg-azure-web-project-dev > current-resources.json

# Exportar configuración de App Services
az webapp show --name azure-web-project-dev-app1 \
  --resource-group rg-azure-web-project-dev > current-app1.json

# Exportar configuración de MySQL
az mysql flexible-server show --name azure-web-project-dev-mysql \
  --resource-group rg-azure-web-project-dev > current-mysql.json
```

### Paso 3: Backup de Datos

```bash
# Backup de MySQL
MYSQL_HOST=$(az mysql flexible-server show \
  --name azure-web-project-dev-mysql \
  --resource-group rg-azure-web-project-dev \
  --query "fullyQualifiedDomainName" -o tsv)

mysqldump -h $MYSQL_HOST -u adminuser -p --all-databases > backup-$(date +%Y%m%d).sql

# Backup de Storage Account
az storage blob download-batch \
  --account-name azurewebprojectdevstorage \
  --source '$web' \
  --destination ./storage-backup/
```

### Paso 4: Crear Nueva Infraestructura (Greenfield)

```bash
# 1. Revisar configuración
cat terraform/environments/dev.tfvars

# 2. Ajustar nombres si es necesario para evitar conflictos
# Editar: project_name = "envia-new"

# 3. Desplegar
make apply ENV=dev

# 4. Verificar
make outputs ENV=dev
```

### Paso 5: Migrar Datos

#### MySQL

```bash
# Obtener nueva conexión
NEW_MYSQL_HOST=$(cd terraform && terraform output -raw mysql_server_fqdn)
KEY_VAULT=$(cd terraform && terraform output -raw key_vault_name)
NEW_MYSQL_PASS=$(az keyvault secret show \
  --vault-name $KEY_VAULT \
  --name mysql-admin-password \
  --query value -o tsv)

# Restaurar backup
mysql -h $NEW_MYSQL_HOST -u enviaadmin -p$NEW_MYSQL_PASS < backup-$(date +%Y%m%d).sql
```

#### Storage Account

```bash
# Obtener nueva storage account
NEW_STORAGE=$(cd terraform && terraform output -raw storage_account_name)

# Copiar datos
az storage blob copy start-batch \
  --source-account-name azurewebprojectdevstorage \
  --destination-account-name $NEW_STORAGE \
  --destination-container app-data
```

### Paso 6: Validar Nueva Infraestructura

```bash
# Health check
make health ENV=dev

# Probar API
make test-api ENV=dev

# Verificar base de datos
make db-connect ENV=dev

# Revisar logs
make logs ENV=dev
```

### Paso 7: Cambiar Tráfico

```bash
# Opción A: Cambiar DNS (si usas dominio custom)
# Actualizar registro A/CNAME a nueva IP del Application Gateway

# Opción B: Actualizar configuración de clientes
# Proporcionar nueva URL a usuarios

# Obtener nueva IP
NEW_IP=$(cd terraform && terraform output -raw app_gateway_public_ip)
echo "Nueva IP: $NEW_IP"
```

### Paso 8: Monitorear

```bash
# Ver métricas en Application Insights
make monitor-app ENV=dev

# Ver health del Application Gateway
make monitor-gateway ENV=dev

# Logs en tiempo real
make logs ENV=dev
```

### Paso 9: Limpiar Infraestructura Antigua

```bash
# ⚠️ Solo después de confirmar que todo funciona

# Esperar al menos 24-48 horas

# Destruir infraestructura Bicep
az group delete --name rg-azure-web-project-dev --yes
```

## Importar Recursos Existentes

Si prefieres importar en lugar de recrear:

### Preparar Mapeo

```bash
# Crear archivo de mapeo
cat > import-map.txt << EOF
azurerm_resource_group.main=/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/rg-azure-web-project-dev
azurerm_virtual_network.main=/subscriptions/{SUBSCRIPTION_ID}/resourceGroups/rg-azure-web-project-dev/providers/Microsoft.Network/virtualNetworks/azure-web-project-dev-vnet
# ... más recursos
EOF
```

### Importar Recursos

```bash
cd terraform

# Importar Resource Group
terraform import \
  -var-file="environments/dev.tfvars" \
  azurerm_resource_group.main \
  /subscriptions/{SUBSCRIPTION_ID}/resourceGroups/rg-azure-web-project-dev

# Importar VNet
terraform import \
  -var-file="environments/dev.tfvars" \
  module.networking.azurerm_virtual_network.main \
  /subscriptions/{SUBSCRIPTION_ID}/resourceGroups/rg-azure-web-project-dev/providers/Microsoft.Network/virtualNetworks/azure-web-project-dev-vnet

# Continuar con cada recurso...
```

### Herramienta Automatizada: aztfexport

```bash
# Instalar aztfexport
brew install aztfexport

# Exportar resource group completo
aztfexport resource-group rg-azure-web-project-dev

# Revisar archivos generados
ls -la

# Ajustar a estructura de módulos
# (Requiere trabajo manual)
```

## Validación Post-Migración

### Checklist de Validación

- [ ] Todos los recursos están en Terraform state
- [ ] Application Gateway responde correctamente
- [ ] App Services están healthy
- [ ] Base de datos es accesible
- [ ] Storage Account tiene los datos
- [ ] Key Vault tiene los secretos
- [ ] Application Insights recibe telemetría
- [ ] Logs se están generando
- [ ] Backups están configurados
- [ ] Private Endpoints funcionan

### Tests Automatizados

```bash
# Health check
curl https://$(cd terraform && terraform output -raw app_gateway_public_ip)/health

# Database connectivity
make db-connect ENV=dev

# Storage access
az storage blob list \
  --account-name $(cd terraform && terraform output -raw storage_account_name) \
  --container-name app-data

# Application Insights
az monitor app-insights component show \
  --app appi-envia-dev \
  --resource-group rg-envia-dev
```

## Rollback

Si algo sale mal, puedes hacer rollback:

### Rollback Rápido (Greenfield)

```bash
# 1. Cambiar tráfico de vuelta a infraestructura antigua
# (Revertir cambios de DNS)

# 2. Destruir nueva infraestructura
cd Terraform-Envia
make destroy ENV=dev

# 3. Verificar que infraestructura antigua funciona
```

### Rollback Complejo (Import)

```bash
# 1. Remover recursos del state de Terraform
cd terraform
terraform state rm azurerm_resource_group.main
terraform state rm module.networking.azurerm_virtual_network.main
# ... todos los recursos importados

# 2. Verificar que recursos siguen en Azure
az resource list --resource-group rg-azure-web-project-dev

# 3. Continuar gestionando con Bicep
```

## Troubleshooting

### Error: "Resource already exists"

```bash
# Opción 1: Importar el recurso
terraform import <resource_type>.<name> <azure_resource_id>

# Opción 2: Cambiar nombre en Terraform
# Editar variables.tf o tfvars
```

### Error: "State lock"

```bash
# Ver locks
az storage blob list \
  --account-name tfstateenvia \
  --container-name tfstate

# Forzar unlock (solo si estás seguro)
terraform force-unlock <LOCK_ID>
```

### Error: "Insufficient permissions"

```bash
# Verificar roles
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Asignar rol necesario
az role assignment create \
  --assignee $(az account show --query user.name -o tsv) \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)
```

## Mejores Prácticas

1. **Siempre prueba en dev primero**
2. **Documenta cada paso**
3. **Haz backups antes de cualquier cambio**
4. **Migra en horarios de bajo tráfico**
5. **Ten un plan de rollback claro**
6. **Monitorea activamente durante y después**
7. **Comunica con el equipo**
8. **No elimines la infraestructura antigua inmediatamente**

## Recursos Adicionales

- [Terraform Import Documentation](https://www.terraform.io/docs/cli/import/index.html)
- [aztfexport Tool](https://github.com/Azure/aztfexport)
- [Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)

## Soporte

Si encuentras problemas durante la migración:

1. Revisa los logs: `make logs ENV=dev`
2. Consulta la [guía de troubleshooting](deployment-guide.md#-troubleshooting)
3. Revisa el [changelog](../CHANGELOG.md) para cambios conocidos
4. Abre un issue en el repositorio

---

**Última actualización**: Enero 2026  
**Versión**: 2.0.0
