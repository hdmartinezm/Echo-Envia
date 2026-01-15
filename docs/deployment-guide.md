# Guía de Despliegue - Terraform Envia

## 📋 Prerrequisitos

### Herramientas Requeridas

1. **Terraform** >= 1.6.0
   ```bash
   # macOS
   brew install terraform
   
   # Verificar instalación
   terraform version
   ```

2. **Azure CLI**
   ```bash
   # macOS
   brew install azure-cli
   
   # Login
   az login
   
   # Verificar suscripción
   az account show
   ```

3. **Node.js** >= 18.0.0
   ```bash
   # macOS
   brew install node@18
   
   # Verificar
   node --version
   npm --version
   ```

4. **jq** (para scripts)
   ```bash
   brew install jq
   ```

### Permisos de Azure

Tu cuenta debe tener los siguientes roles:
- **Contributor** en la suscripción
- **User Access Administrator** (para asignar roles a Managed Identities)

## 🚀 Despliegue Paso a Paso

### 1. Clonar y Configurar

```bash
cd Terraform-Envia
```

### 2. Revisar Variables de Entorno

Edita el archivo correspondiente en `terraform/environments/`:
- `dev.tfvars` - Desarrollo
- `staging.tfvars` - Staging
- `prod.tfvars` - Producción

```bash
# Ejemplo: Editar configuración de dev
vim terraform/environments/dev.tfvars
```

### 3. Desplegar Infraestructura

```bash
# Ir a la carpeta de scripts
cd scripts

# Hacer ejecutables los scripts (si no lo están)
chmod +x *.sh

# Plan (revisar cambios sin aplicar)
./deploy-infrastructure.sh dev plan

# Apply (desplegar infraestructura)
./deploy-infrastructure.sh dev apply
```

Este proceso creará:
- ✅ Resource Group
- ✅ Virtual Network con 3 subnets
- ✅ Network Security Groups
- ✅ Private DNS Zones
- ✅ Key Vault con secretos
- ✅ MySQL Flexible Server
- ✅ Storage Account con Private Endpoints
- ✅ App Service Plan y App Services
- ✅ Application Insights
- ✅ Application Gateway con WAF

**Tiempo estimado**: 15-20 minutos

### 4. Verificar Infraestructura

```bash
# Ver outputs de Terraform
cd ../terraform
terraform output

# O revisar el archivo JSON
cat outputs-dev.json | jq
```

### 5. Inicializar Base de Datos

```bash
# Obtener información de conexión
MYSQL_HOST=$(cd terraform && terraform output -raw mysql_server_fqdn)
MYSQL_USER=$(cd terraform && terraform output -raw mysql_admin_username)

# Obtener contraseña desde Key Vault
KEY_VAULT_NAME=$(cd terraform && terraform output -raw key_vault_name)
MYSQL_PASSWORD=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name mysql-admin-password --query value -o tsv)

# Ejecutar script de inicialización
mysql -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD < scripts/database/init.sql
```

### 6. Desplegar Aplicación

```bash
cd scripts

# Desplegar a todos los App Services
./deploy-app.sh dev
```

Este proceso:
- ✅ Instala dependencias de Node.js
- ✅ Ejecuta tests
- ✅ Crea paquete de despliegue
- ✅ Despliega a todos los App Services
- ✅ Reinicia servicios
- ✅ Verifica health checks

**Tiempo estimado**: 5-10 minutos

### 7. Verificar Despliegue

```bash
# Obtener IP del Application Gateway
GATEWAY_IP=$(cd ../terraform && terraform output -raw app_gateway_public_ip)

# Probar health check
curl https://$GATEWAY_IP/health

# Probar API
curl https://$GATEWAY_IP/api/

# Ver logs de App Service
APP_NAME=$(cd ../terraform && terraform output -json app_service_names | jq -r '.[0]')
az webapp log tail --name $APP_NAME --resource-group rg-envia-dev
```

## 🔄 Actualizar Aplicación

Para actualizar solo el código de la aplicación (sin cambiar infraestructura):

```bash
cd scripts
./deploy-app.sh dev
```

## 🔄 Actualizar Infraestructura

```bash
cd scripts

# 1. Revisar cambios
./deploy-infrastructure.sh dev plan

# 2. Aplicar cambios
./deploy-infrastructure.sh dev apply
```

## 🌍 Desplegar a Otros Entornos

### Staging

```bash
# Infraestructura
./deploy-infrastructure.sh staging apply

# Aplicación
./deploy-app.sh staging
```

### Producción

```bash
# Infraestructura
./deploy-infrastructure.sh prod apply

# Aplicación
./deploy-app.sh prod
```

## 🗑️ Destruir Infraestructura

```bash
cd scripts
./deploy-infrastructure.sh dev destroy
```

⚠️ **ADVERTENCIA**: Esto eliminará TODOS los recursos del entorno.

## 📊 Monitoreo

### Application Insights

```bash
# Obtener Instrumentation Key
cd terraform
terraform output application_insights_instrumentation_key

# Ver en Azure Portal
az portal open --resource-group rg-envia-dev --resource-type Microsoft.Insights/components
```

### Logs de App Service

```bash
# Streaming de logs
az webapp log tail --name app-envia-dev-1 --resource-group rg-envia-dev

# Descargar logs
az webapp log download --name app-envia-dev-1 --resource-group rg-envia-dev --log-file logs.zip
```

### Métricas de MySQL

```bash
# Ver métricas
az mysql flexible-server show --name mysql-envia-dev --resource-group rg-envia-dev
```

## 🔐 Gestión de Secretos

### Ver Secretos en Key Vault

```bash
KEY_VAULT_NAME=$(cd terraform && terraform output -raw key_vault_name)

# Listar secretos
az keyvault secret list --vault-name $KEY_VAULT_NAME

# Obtener un secreto
az keyvault secret show --vault-name $KEY_VAULT_NAME --name mysql-admin-password
```

### Agregar Nuevo Secreto

```bash
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "mi-secreto" --value "valor-secreto"
```

## 🐛 Troubleshooting

### Error: "Insufficient permissions"

```bash
# Verificar roles
az role assignment list --assignee $(az account show --query user.name -o tsv)

# Asignar rol Contributor si es necesario
az role assignment create --assignee $(az account show --query user.name -o tsv) \
  --role Contributor \
  --scope /subscriptions/$(az account show --query id -o tsv)
```

### Error: "MySQL connection failed"

```bash
# Verificar conectividad
MYSQL_HOST=$(cd terraform && terraform output -raw mysql_server_fqdn)
nc -zv $MYSQL_HOST 3306

# Verificar firewall rules
az mysql flexible-server firewall-rule list --name mysql-envia-dev --resource-group rg-envia-dev
```

### Error: "App Service deployment failed"

```bash
# Ver logs de despliegue
az webapp log deployment show --name app-envia-dev-1 --resource-group rg-envia-dev

# Verificar configuración
az webapp config show --name app-envia-dev-1 --resource-group rg-envia-dev
```

### Application Gateway no responde

```bash
# Verificar backend health
az network application-gateway show-backend-health \
  --name appgw-envia-dev \
  --resource-group rg-envia-dev
```

## 💰 Estimación de Costos

### Desarrollo (dev.tfvars)
- App Service Plan (P1v3, 1 worker): ~$73/mes
- MySQL (B1s, sin HA): ~$15/mes
- Application Gateway (WAF_v2, 1 instancia): ~$125/mes
- Storage (LRS): ~$5/mes
- **Total**: ~$218/mes

### Staging (staging.tfvars)
- App Service Plan (P1v3, 2 workers): ~$146/mes
- MySQL (B2s, SameZone HA): ~$60/mes
- Application Gateway (WAF_v2, 2 instancias): ~$250/mes
- Storage (GRS): ~$10/mes
- **Total**: ~$466/mes

### Producción (prod.tfvars)
- App Service Plan (P2v3, 3 workers): ~$438/mes
- MySQL (D2ds_v4, ZoneRedundant HA): ~$200/mes
- Application Gateway (WAF_v2, 3 instancias): ~$375/mes
- Storage (GZRS): ~$20/mes
- **Total**: ~$1,033/mes

## 📚 Recursos Adicionales

- [Documentación de Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure App Service](https://docs.microsoft.com/azure/app-service/)
- [Azure MySQL Flexible Server](https://docs.microsoft.com/azure/mysql/flexible-server/)
- [Application Gateway](https://docs.microsoft.com/azure/application-gateway/)
