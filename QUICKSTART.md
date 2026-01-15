# 🚀 Inicio Rápido - Terraform Envia

Guía de 5 minutos para desplegar tu primera infraestructura.

## ✅ Prerrequisitos (5 min)

```bash
# 1. Instalar Terraform
brew install terraform

# 2. Instalar Azure CLI
brew install azure-cli

# 3. Instalar Node.js
brew install node@18

# 4. Instalar jq
brew install jq

# 5. Login en Azure
az login
```

## 🎯 Despliegue Rápido (10 min)

### Opción 1: Usando Makefile (Recomendado)

```bash
# 1. Ir al directorio del proyecto
cd Terraform-Envia

# 2. Ver comandos disponibles
make help

# 3. Desplegar todo (infraestructura + app)
make deploy-all ENV=dev
```

¡Listo! Tu aplicación estará disponible en ~15 minutos.

### Opción 2: Paso a Paso

```bash
# 1. Ir al directorio del proyecto
cd Terraform-Envia

# 2. Desplegar infraestructura
cd scripts
./deploy-infrastructure.sh dev apply

# 3. Desplegar aplicación
./deploy-app.sh dev
```

## 🔍 Verificar Despliegue

```bash
# Ver información del despliegue
make outputs ENV=dev

# Probar health check
make health ENV=dev

# Probar API
make test-api ENV=dev
```

## 📊 Acceder a tu Aplicación

```bash
# Obtener IP pública
cd terraform
terraform output app_gateway_public_ip

# Acceder en el navegador
# https://<IP_PUBLICA>/
```

## 🎨 Personalizar

### Cambiar Configuración

Edita `terraform/environments/dev.tfvars`:

```hcl
# Cambiar región
location = "West Europe"

# Cambiar número de instancias
app_service_instances = 3

# Cambiar SKU de MySQL
mysql_sku_name = "B_Standard_B2s"
```

Aplica cambios:
```bash
make apply ENV=dev
```

## 🗑️ Limpiar

```bash
# Destruir todo
make destroy ENV=dev
```

## 📚 Próximos Pasos

1. Lee la [Guía de Despliegue Completa](docs/deployment-guide.md)
2. Revisa la [Arquitectura](docs/architecture.md)
3. Configura [Monitoreo](docs/deployment-guide.md#-monitoreo)
4. Despliega a [Staging/Prod](docs/deployment-guide.md#-desplegar-a-otros-entornos)

## 🆘 Problemas Comunes

### Error: "Insufficient permissions"
```bash
# Asignar rol Contributor
az role assignment create \
  --assignee $(az account show --query user.name -o tsv) \
  --role Contributor
```

### Error: "MySQL connection failed"
```bash
# Verificar firewall
az mysql flexible-server firewall-rule list \
  --name mysql-envia-dev \
  --resource-group rg-envia-dev
```

### Error: "Terraform state locked"
```bash
# Forzar unlock (solo si estás seguro)
cd terraform
terraform force-unlock <LOCK_ID>
```

## 💡 Comandos Útiles

```bash
# Ver logs en tiempo real
make logs ENV=dev

# Conectar a MySQL
make db-connect ENV=dev

# Ver costos
make az-costs ENV=dev

# Ver recursos
make az-list-resources ENV=dev

# Monitorear Application Gateway
make monitor-gateway ENV=dev
```

## 🎓 Recursos

- [Documentación Completa](docs/)
- [Comparación Bicep vs Terraform](docs/bicep-vs-terraform.md)
- [Troubleshooting](docs/deployment-guide.md#-troubleshooting)

---

**¿Necesitas ayuda?** Revisa la [documentación completa](docs/deployment-guide.md) o abre un issue.
