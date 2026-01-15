# Configuración de GitHub Actions con Azure

Esta guía te ayudará a configurar la conexión entre GitHub y tu tenant de Azure para desplegar automáticamente con Terraform.

## Requisitos Previos

- Acceso a Azure Portal con permisos de administrador
- Acceso a tu repositorio de GitHub con permisos de administrador
- Azure CLI instalado (opcional, para comandos locales)

## Paso 1: Crear Service Principal en Azure

### Opción A: Usando Azure Portal

1. Ve a **Azure Active Directory** > **App registrations** > **New registration**
2. Nombre: `github-actions-terraform-envia`
3. Copia los siguientes valores:
   - **Application (client) ID**
   - **Directory (tenant) ID**

4. Ve a **Certificates & secrets** > **New client secret**
   - Descripción: `GitHub Actions Secret`
   - Expiration: 24 meses (o según tu política)
   - Copia el **Value** (solo se muestra una vez)

5. Ve a **Subscriptions** > Tu suscripción > **Access control (IAM)**
   - Click **Add role assignment**
   - Role: **Contributor**
   - Assign access to: **User, group, or service principal**
   - Select: `github-actions-terraform-envia`
   - Click **Save**

### Opción B: Usando Azure CLI

```bash
# Login a Azure
az login

# Obtener tu Subscription ID
az account show --query id -o tsv

# Crear Service Principal con rol Contributor
az ad sp create-for-rbac \
  --name "github-actions-terraform-envia" \
  --role contributor \
  --scopes /subscriptions/{SUBSCRIPTION_ID} \
  --sdk-auth

# Esto generará un JSON con todas las credenciales necesarias
```

El comando anterior generará algo como:

```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

## Paso 2: Configurar Secrets en GitHub

1. Ve a tu repositorio en GitHub: https://github.com/hdmartinezm/Echo-Envia
2. Click en **Settings** > **Secrets and variables** > **Actions**
3. Click en **New repository secret** y agrega los siguientes secrets:

### Secrets Requeridos:

#### AZURE_CREDENTIALS
Copia todo el JSON generado por el comando `az ad sp create-for-rbac --sdk-auth`:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

#### ARM_CLIENT_ID
El `clientId` del JSON anterior

#### ARM_CLIENT_SECRET
El `clientSecret` del JSON anterior

#### ARM_SUBSCRIPTION_ID
El `subscriptionId` del JSON anterior

#### ARM_TENANT_ID
El `tenantId` del JSON anterior

## Paso 3: Configurar Environments en GitHub (Opcional pero Recomendado)

Para mayor seguridad y control, configura environments:

1. Ve a **Settings** > **Environments**
2. Crea tres environments:
   - `dev`
   - `staging`
   - `prod`

3. Para cada environment (especialmente `prod`):
   - Habilita **Required reviewers** (aprobación manual antes de deploy)
   - Configura **Wait timer** si deseas un delay
   - Limita a branches específicas (ej: solo `main` para prod)

## Paso 4: Configurar Backend de Terraform (Recomendado)

Para almacenar el estado de Terraform en Azure:

```bash
# Crear Resource Group para el backend
az group create \
  --name rg-terraform-state \
  --location eastus

# Crear Storage Account
az storage account create \
  --name tfstateenvia \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob

# Crear Container
az storage container create \
  --name tfstate \
  --account-name tfstateenvia
```

Luego actualiza `terraform/backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateenvia"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
```

## Paso 5: Probar el Workflow

### Opción 1: Push a main
```bash
git add .
git commit -m "Add GitHub Actions workflow"
git push origin main
```

### Opción 2: Ejecución Manual
1. Ve a **Actions** en tu repositorio
2. Selecciona el workflow **Terraform Deploy to Azure**
3. Click en **Run workflow**
4. Selecciona el environment (dev/staging/prod)
5. Click en **Run workflow**

## Flujo de Trabajo

### Para Pull Requests:
- Se ejecuta `terraform plan` automáticamente
- Muestra los cambios propuestos
- No aplica cambios

### Para Push a main:
- Se ejecuta `terraform plan`
- Si el plan es exitoso, ejecuta `terraform apply`
- Despliega los cambios automáticamente

### Para Ejecución Manual:
- Puedes elegir el environment
- Útil para deploys controlados a staging/prod

## Verificación

1. Ve a **Actions** en GitHub
2. Verifica que el workflow se ejecute correctamente
3. Revisa los logs de cada step
4. Verifica en Azure Portal que los recursos se crearon

## Troubleshooting

### Error: "No valid credential sources found"
- Verifica que todos los secrets estén configurados correctamente
- Asegúrate de que no haya espacios extra en los valores

### Error: "Insufficient permissions"
- Verifica que el Service Principal tenga rol Contributor
- Verifica el scope de la asignación de rol

### Error: "Backend initialization required"
- Asegúrate de que el Storage Account para el backend exista
- Verifica las credenciales de acceso al backend

## Seguridad

- ✅ Nunca commitees credenciales en el código
- ✅ Usa GitHub Secrets para información sensible
- ✅ Configura environments con aprobaciones para prod
- ✅ Rota los secrets periódicamente
- ✅ Usa el principio de menor privilegio
- ✅ Habilita branch protection rules

## Recursos Adicionales

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Service Principal](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-objects-and-service-principals)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
