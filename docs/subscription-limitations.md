# Limitaciones de Suscripción de Azure

## Problema Actual

Tu suscripción de Azure tiene las siguientes limitaciones que impiden el despliegue completo:

### 1. Cuotas de App Service
```
Error: Current Limit (Basic VMs): 0
Error: Current Limit (PremiumV3 VMs): 0
```

**Causa**: Suscripción de prueba/estudiante sin cuotas asignadas para App Service Plans.

**Solución**:
- Solicitar aumento de cuota en Azure Portal
- O usar Azure Functions (Consumption Plan) que no requiere cuota
- O usar Container Instances en lugar de App Service

### 2. MySQL Flexible Server no disponible
```
Error: ProvisionNotSupportedForRegion
Message: "Provisioning in requested region is not supported"
```

**Causa**: MySQL Flexible Server no está disponible en todas las regiones para suscripciones de prueba.

**Soluciones**:
1. Cambiar a otra región (West US, North Europe, etc.)
2. Usar Azure Database for MySQL Single Server (legacy)
3. Usar MySQL en Container Instance
4. Usar base de datos externa (ej: PlanetScale, AWS RDS Free Tier)

### 3. Key Vault Access Policy
```
Error: Caller is not authorized to perform action
```

**Causa**: El access policy tarda en propagarse o el Service Principal necesita permisos adicionales.

**Solución**: Esperar 5-10 minutos para propagación de permisos.

## Alternativas Recomendadas

### Opción 1: Solicitar Aumento de Cuota

1. Ve a Azure Portal
2. Busca "Quotas" o "Cuotas"
3. Selecciona "Compute" o "App Service"
4. Solicita aumento de cuota para:
   - Basic App Service Plan: 1 vCore
   - O Free App Service Plan: 1 instancia

### Opción 2: Arquitectura Simplificada (Sin Cuotas)

```
┌─────────────────────────────────────────┐
│         Azure Container Instances        │
│  - Node.js App (sin cuota requerida)   │
│  - MySQL Container                       │
└─────────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│         Storage Account                  │
│  - Blob Storage (datos)                 │
│  - File Share (config)                  │
└─────────────────────────────────────────┘
```

### Opción 3: Usar Servicios Externos

**Base de Datos**:
- [PlanetScale](https://planetscale.com/) - MySQL gratis hasta 5GB
- [Supabase](https://supabase.com/) - PostgreSQL gratis
- [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) - Free tier

**Hosting**:
- [Vercel](https://vercel.com/) - Gratis para proyectos personales
- [Netlify](https://www.netlify.com/) - Gratis con límites generosos
- [Railway](https://railway.app/) - $5 crédito mensual gratis

### Opción 4: Upgrade de Suscripción

Considera actualizar a:
- **Pay-As-You-Go**: Sin limitaciones de cuota
- **Azure for Students**: $100 crédito + servicios gratuitos
- **Visual Studio Subscription**: $50-150 crédito mensual

## Pasos Inmediatos

### 1. Verificar Tipo de Suscripción

```bash
az account show --query "{Name:name, Type:subscriptionPolicies.quotaId}" -o table
```

### 2. Ver Cuotas Actuales

```bash
# Ver cuotas de App Service
az vm list-usage --location "East US" -o table

# Ver regiones disponibles para MySQL
az mysql flexible-server list-skus --location "East US"
```

### 3. Solicitar Cuota (si es posible)

```bash
# Esto abrirá el portal para solicitar aumento
az support tickets create \
  --ticket-name "AppServiceQuota" \
  --title "Request App Service Quota Increase" \
  --description "Need Basic App Service Plan quota for development" \
  --severity "minimal"
```

## Arquitectura Alternativa con Container Instances

Si no puedes obtener cuotas, aquí está una arquitectura completamente funcional:

```hcl
# main-containers.tf
resource "azurerm_container_group" "app" {
  name                = "aci-envia-dev"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  
  container {
    name   = "app"
    image  = "node:18-alpine"
    cpu    = "0.5"
    memory = "1.0"
    
    ports {
      port     = 3000
      protocol = "TCP"
    }
  }
  
  container {
    name   = "mysql"
    image  = "mysql:8.0"
    cpu    = "0.5"
    memory = "1.0"
    
    ports {
      port     = 3306
      protocol = "TCP"
    }
    
    environment_variables = {
      MYSQL_ROOT_PASSWORD = random_password.mysql_admin_password.result
      MYSQL_DATABASE      = "enviadb"
    }
  }
  
  ip_address_type = "Public"
  dns_name_label  = "envia-dev"
}
```

**Ventajas**:
- ✅ No requiere cuotas especiales
- ✅ Muy económico (~$30/mes)
- ✅ Fácil de desplegar
- ✅ Funciona en cualquier suscripción

**Desventajas**:
- ❌ No es production-ready
- ❌ Sin auto-scaling
- ❌ Menos features empresariales

## Recomendación Final

Para desarrollo y aprendizaje con suscripción limitada:

1. **Corto plazo**: Usa Container Instances + Storage Account
2. **Mediano plazo**: Solicita upgrade a Pay-As-You-Go
3. **Largo plazo**: Considera servicios híbridos (Azure + servicios externos gratuitos)

## Recursos Útiles

- [Azure Free Services](https://azure.microsoft.com/en-us/free/)
- [Azure for Students](https://azure.microsoft.com/en-us/free/students/)
- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Request Quota Increase](https://docs.microsoft.com/en-us/azure/azure-portal/supportability/regional-quota-requests)
