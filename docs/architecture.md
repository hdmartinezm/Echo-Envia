# Arquitectura del Sistema - Envia

## 🏗️ Visión General

Esta arquitectura implementa una aplicación web de alta disponibilidad en Azure usando las mejores prácticas de seguridad, escalabilidad y resiliencia.

## 📐 Diagrama de Arquitectura

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Application Gateway (WAF v2)                               │
│  - WAF OWASP 3.2                                           │
│  - SSL/TLS Termination                                     │
│  - Load Balancing                                          │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Virtual Network (10.0.0.0/16)                             │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  App Gateway Subnet (10.0.1.0/24)                   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  App Service Integration Subnet (10.0.2.0/24)       │  │
│  │                                                       │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌────────────┐ │  │
│  │  │ App Service 1│  │ App Service 2│  │ App Svc N  │ │  │
│  │  │ (Node.js)    │  │ (Node.js)    │  │ (Node.js)  │ │  │
│  │  └──────────────┘  └──────────────┘  └────────────┘ │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Private Endpoint Subnet (10.0.3.0/24)              │  │
│  │                                                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │  │
│  │  │ MySQL PE │  │ KV PE    │  │ Storage PE       │  │  │
│  │  └──────────┘  └──────────┘  └──────────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
    │                    │                    │
    ▼                    ▼                    ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────────┐
│ MySQL        │  │ Key Vault    │  │ Storage Account  │
│ Flexible     │  │              │  │                  │
│ Server       │  │ - Secrets    │  │ - Blob           │
│              │  │ - Certs      │  │ - Files          │
│ - Primary    │  │ - Keys       │  │                  │
│ - Standby    │  └──────────────┘  └──────────────────┘
└──────────────┘
```

## 🔧 Componentes Principales

### 1. Application Gateway

**Propósito**: Punto de entrada único con balanceo de carga y protección WAF

**Características**:
- WAF v2 con reglas OWASP 3.2
- SSL/TLS termination
- Redirección automática HTTP → HTTPS
- Health probes para backend
- Balanceo de carga entre App Services
- Protección DDoS básica

**Configuración**:
- SKU: WAF_v2
- Capacidad: 1-3 instancias (según entorno)
- Modo WAF: Detection (dev) / Prevention (prod)

### 2. Virtual Network

**Propósito**: Aislamiento de red y segmentación

**Subnets**:

1. **App Gateway Subnet** (10.0.1.0/24)
   - Dedicada para Application Gateway
   - NSG con reglas para tráfico HTTP/HTTPS
   - Permite tráfico de GatewayManager

2. **App Service Integration Subnet** (10.0.2.0/24)
   - Delegada a Microsoft.Web/serverFarms
   - Permite integración VNet de App Services
   - NSG permite solo tráfico desde App Gateway

3. **Private Endpoint Subnet** (10.0.3.0/24)
   - Para Private Endpoints de servicios PaaS
   - Conectividad privada a MySQL, Key Vault, Storage
   - Sin acceso directo desde Internet

### 3. App Services

**Propósito**: Hosting de aplicación Node.js

**Características**:
- Runtime: Node.js 18 LTS
- OS: Linux
- Integración con VNet
- Managed Identity para acceso a Key Vault
- Application Insights integrado
- Auto-scaling (según configuración)

**Configuración por Entorno**:

| Entorno | SKU | Instancias | Workers |
|---------|-----|------------|---------|
| Dev | P1v3 | 2 | 1 |
| Staging | P1v3 | 2 | 2 |
| Prod | P2v3 | 3 | 3 |

### 4. MySQL Flexible Server

**Propósito**: Base de datos relacional

**Características**:
- Versión: MySQL 8.0.21
- Conectividad privada (Private Endpoint)
- Backups automáticos
- Geo-redundancia (staging/prod)
- Alta disponibilidad zone-redundant (prod)

**Configuración por Entorno**:

| Entorno | SKU | Storage | HA | Backup |
|---------|-----|---------|----|----|
| Dev | B1s | 20GB | No | 7 días |
| Staging | B2s | 50GB | SameZone | 14 días |
| Prod | D2ds_v4 | 100GB | ZoneRedundant | 35 días |

### 5. Key Vault

**Propósito**: Gestión centralizada de secretos

**Características**:
- RBAC habilitado
- Network ACLs (deny by default)
- Soft delete habilitado
- Purge protection (prod)
- Private Endpoint

**Secretos Almacenados**:
- MySQL admin password
- MySQL admin username
- Certificados SSL
- API keys (según necesidad)

### 6. Storage Account

**Propósito**: Almacenamiento de archivos y datos

**Características**:
- Tipo: StorageV2
- Access Tier: Hot
- TLS 1.2 mínimo
- Private Endpoints (Blob y File)
- Versioning habilitado
- Soft delete (7 días)

**Containers**:
- `app-data`: Datos de aplicación
- `backups`: Backups de aplicación

**File Shares**:
- `config`: Configuración compartida

### 7. Application Insights

**Propósito**: Monitoreo y telemetría

**Características**:
- Integrado con App Services
- Log Analytics Workspace
- Retención: 30 días
- Métricas de rendimiento
- Distributed tracing
- Alertas configurables

## 🔐 Seguridad

### Capas de Seguridad

1. **Perímetro**
   - Application Gateway con WAF
   - Protección DDoS
   - SSL/TLS obligatorio

2. **Red**
   - Network Security Groups
   - Private Endpoints
   - No acceso público a servicios backend

3. **Identidad**
   - Managed Identities
   - RBAC en Key Vault
   - Sin credenciales hardcodeadas

4. **Datos**
   - Encriptación en tránsito (TLS 1.2+)
   - Encriptación en reposo
   - Backups geo-redundantes

### Flujo de Autenticación

```
App Service → Managed Identity → Key Vault → Secretos
```

No se requieren credenciales en código o configuración.

## 🔄 Alta Disponibilidad

### Estrategias Implementadas

1. **Múltiples Instancias**
   - 2-3 App Services según entorno
   - Balanceo de carga automático

2. **MySQL HA**
   - Standby replica en zona diferente (prod)
   - Failover automático < 60 segundos

3. **Application Gateway**
   - Múltiples instancias
   - Health probes cada 30 segundos
   - Automatic failover

4. **Backups**
   - MySQL: Backups automáticos diarios
   - Storage: Geo-redundancia (staging/prod)
   - Retención configurable

## 📊 Escalabilidad

### Escalado Horizontal

**App Services**:
- Manual: Ajustar `capacity` en tfvars
- Auto-scaling: Configurar reglas basadas en CPU/memoria

**Application Gateway**:
- Auto-scaling: 1-10 instancias
- Basado en carga de tráfico

### Escalado Vertical

**MySQL**:
- Cambiar SKU sin downtime
- Aumentar storage automáticamente

**App Service Plan**:
- Cambiar tier (P1v3 → P2v3)
- Requiere breve reinicio

## 🌐 Networking

### DNS Resolution

```
Private DNS Zones:
- privatelink.mysql.database.azure.com
- privatelink.blob.core.windows.net
- privatelink.file.core.windows.net
- privatelink.vaultcore.azure.net
```

Todas las conexiones internas usan DNS privado.

### Flujo de Tráfico

1. **Request Externo**
   ```
   Internet → App Gateway (WAF) → App Service → MySQL/Storage
   ```

2. **Request Interno**
   ```
   App Service → Private Endpoint → MySQL/Key Vault/Storage
   ```

## 📈 Monitoreo y Observabilidad

### Métricas Clave

**Application Gateway**:
- Request count
- Failed requests
- Backend response time
- WAF blocked requests

**App Services**:
- CPU percentage
- Memory percentage
- Response time
- HTTP errors

**MySQL**:
- CPU percentage
- Storage used
- Active connections
- Replication lag

### Logs

**Tipos de Logs**:
- Application logs (App Service)
- HTTP logs (App Service)
- WAF logs (Application Gateway)
- Audit logs (Key Vault)
- Query logs (MySQL)

**Retención**:
- Application Insights: 30 días
- Storage Account: Configurable
- Log Analytics: 30 días

## 🔄 Disaster Recovery

### RTO y RPO

| Componente | RTO | RPO |
|------------|-----|-----|
| App Services | < 5 min | 0 (stateless) |
| MySQL | < 1 min | < 5 min |
| Storage | < 1 min | < 15 min |

### Estrategia de Backup

1. **MySQL**
   - Backups automáticos diarios
   - Point-in-time restore
   - Geo-redundancia (prod)

2. **Storage**
   - Soft delete (7 días)
   - Versioning habilitado
   - Geo-replicación

3. **Configuración**
   - Terraform state en Azure Storage
   - Versionado en Git

## 💡 Mejores Prácticas Implementadas

✅ Infrastructure as Code (Terraform)
✅ Módulos reutilizables
✅ Separación por entornos
✅ Secretos en Key Vault
✅ Managed Identities
✅ Private Endpoints
✅ Network segmentation
✅ WAF habilitado
✅ SSL/TLS obligatorio
✅ Monitoreo centralizado
✅ Backups automáticos
✅ Alta disponibilidad
✅ Auto-scaling ready
✅ Disaster recovery plan

## 🚀 Próximas Mejoras

- [ ] Azure Front Door para multi-región
- [ ] Azure CDN para contenido estático
- [ ] Redis Cache para sesiones
- [ ] Azure DevOps Pipelines
- [ ] Terraform Cloud para state management
- [ ] Azure Monitor Alerts
- [ ] Log Analytics queries personalizadas
- [ ] Chaos engineering tests
