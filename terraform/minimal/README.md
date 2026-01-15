# Terraform Minimal Configuration

Esta es una configuración simplificada de Terraform que evita los bugs del provider AzureRM 3.85.0.

## Recursos Incluidos

- ✅ Resource Group
- ✅ App Service Plan (Basic B1)
- ✅ Linux Web App (Node.js 18)
- ✅ MySQL Flexible Server (B1s)
- ✅ MySQL Database
- ✅ Storage Account
- ✅ Storage Container

## Despliegue

### Desde GitHub Actions (Recomendado)

1. Ve a: https://github.com/hdmartinezm/Echo-Envia/actions
2. Selecciona: "Terraform Minimal Deploy"
3. Click: "Run workflow"
4. Selecciona: "dev"
5. Click: "Run workflow"

### Desde Local

```bash
cd terraform/minimal

# Inicializar
terraform init

# Planificar
terraform plan -var-file="dev-simple.tfvars"

# Aplicar
terraform apply -var-file="dev-simple.tfvars"
```

## Configuración

La configuración se encuentra en `dev-simple.tfvars`:

- **App Service**: Basic B1 (1 instancia)
- **MySQL**: B1s (20GB, sin HA)
- **Storage**: Standard LRS
- **Región**: West US 2
- **Private Endpoints**: Deshabilitados

## Costos Estimados

| Recurso | SKU | Costo Mensual |
|---------|-----|---------------|
| App Service Plan | B1 | ~$13 |
| MySQL Flexible Server | B1s | ~$12 |
| Storage Account | Standard LRS | ~$2 |
| **Total** | | **~$27/mes** |

## Diferencias con la Configuración Completa

| Característica | Completa | Mínima |
|----------------|----------|--------|
| Application Gateway | ✅ | ❌ |
| WAF | ✅ | ❌ |
| Private Endpoints | ✅ | ❌ |
| Key Vault | ✅ | ❌ |
| High Availability | ✅ | ❌ |
| Multiple App Services | ✅ | ❌ |
| Private DNS Zones | ✅ | ❌ |

## Próximos Pasos

Una vez que esta configuración funcione correctamente, puedes:

1. **Migrar a la configuración completa** cuando se solucione el bug del provider
2. **Agregar componentes gradualmente** (Key Vault, Application Gateway, etc.)
3. **Escalar verticalmente** (cambiar a SKUs más grandes)
4. **Agregar alta disponibilidad** (múltiples instancias, geo-redundancia)

## Troubleshooting

### Error: "Provider produced inconsistent result"
- Asegúrate de usar AzureRM provider 3.80.0 (no 3.85.0)
- Limpia el Resource Group antes de volver a desplegar

### Error: "max_connections invalid value"
- MySQL B1s solo permite 10-171 conexiones
- El valor está configurado en 100 (válido)

### Error: "Insufficient quota"
- Verifica que tengas una suscripción Pay-As-You-Go
- Solicita aumento de cuota si es necesario