# Proyecto Azure con Terraform - Envia

Implementación completa de arquitectura web en Azure usando Terraform con mejoras de seguridad y alta disponibilidad.

## 🏗️ Arquitectura

### Componentes Principales

- **Application Gateway v2** con WAF (OWASP 3.2) y certificado SSL
- **App Services** (2 instancias) con integración VNet
- **MySQL Flexible Server** con alta disponibilidad zone-redundant
- **Azure Key Vault** para gestión de secretos
- **Storage Account** con acceso privado
- **Private Endpoints** para conectividad segura
- **Private DNS Zones** para resolución interna

## 📁 Estructura del Proyecto

```
Terraform-Envia/
├── terraform/
│   ├── main.tf                 # Configuración principal
│   ├── variables.tf            # Variables de entrada
│   ├── outputs.tf              # Outputs del despliegue
│   ├── providers.tf            # Configuración de providers
│   ├── modules/
│   │   ├── networking/         # VNet, subnets, NSGs
│   │   ├── compute/            # App Services
│   │   ├── database/           # MySQL Flexible Server
│   │   ├── security/           # Key Vault, Private Endpoints
│   │   ├── gateway/            # Application Gateway
│   │   └── storage/            # Storage Account
│   ├── environments/
│   │   ├── dev.tfvars
│   │   ├── staging.tfvars
│   │   └── prod.tfvars
│   └── backend.tf              # Backend remoto (Azure Storage)
├── src/                        # Código de la aplicación
├── scripts/                    # Scripts de automatización
└── docs/                       # Documentación

```

## 🚀 Inicio Rápido

### Prerrequisitos

- Terraform >= 1.6.0
- Azure CLI instalado y autenticado
- Node.js >= 18.0.0

### Despliegue Local

```bash
# 1. Inicializar Terraform
cd terraform
terraform init

# 2. Planificar despliegue (dev)
terraform plan -var-file="environments/dev.tfvars"

# 3. Aplicar infraestructura
terraform apply -var-file="environments/dev.tfvars"

# 4. Desplegar aplicación
cd ../scripts
./deploy-app.sh dev
```

### Despliegue con GitHub Actions

Para configurar CI/CD automático desde GitHub a Azure:

1. **Configura las credenciales de Azure**:
   ```bash
   ./scripts/setup-azure-credentials.sh
   ```

2. **Agrega los secrets en GitHub**:
   - Ve a: `Settings` > `Secrets and variables` > `Actions`
   - Agrega: `AZURE_CREDENTIALS`, `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`

3. **Despliega automáticamente**:
   - Push a `main` para despliegue automático
   - O ejecuta el workflow manualmente desde `Actions`

📖 **Guía completa**: [Configuración GitHub-Azure](docs/github-azure-setup.md)

## 🔐 Mejoras de Seguridad Implementadas

1. **Secretos en Key Vault**: Contraseñas y credenciales almacenadas de forma segura
2. **Certificados SSL**: HTTPS obligatorio con certificados gestionados
3. **Network Security Groups**: Reglas de firewall granulares
4. **Private Endpoints**: Toda la comunicación interna por red privada
5. **Managed Identities**: Autenticación sin credenciales hardcodeadas
6. **WAF**: Protección contra OWASP Top 10

## 💰 Estimación de Costos

| Recurso | SKU | Costo Mensual (USD) |
|---------|-----|---------------------|
| App Service Plan | P1v3 | ~$73 |
| MySQL Flexible Server | Standard_B2s | ~$50 |
| Application Gateway | WAF_v2 | ~$125 |
| Storage Account | Standard_LRS | ~$5 |
| Key Vault | Standard | ~$1 |
| **Total Estimado** | | **~$254/mes** |

## 📚 Documentación Adicional

- [Configuración GitHub-Azure](docs/github-azure-setup.md) - CI/CD con GitHub Actions
- [Guía de Despliegue](docs/deployment-guide.md)
- [Arquitectura Detallada](docs/architecture.md)
- [Guía de Migración desde Bicep](docs/migration-guide.md)
- [Bicep vs Terraform](docs/bicep-vs-terraform.md)
