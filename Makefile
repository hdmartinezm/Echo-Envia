.PHONY: help init plan apply destroy deploy-app clean validate fmt

# Variables
ENV ?= dev
TERRAFORM_DIR = terraform
SCRIPTS_DIR = scripts

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Mostrar esta ayuda
	@echo "$(BLUE)Comandos disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Uso:$(NC)"
	@echo "  make <comando> ENV=<environment>"
	@echo ""
	@echo "$(YELLOW)Ejemplos:$(NC)"
	@echo "  make plan ENV=dev"
	@echo "  make apply ENV=staging"
	@echo "  make deploy-app ENV=prod"

init: ## Inicializar Terraform
	@echo "$(BLUE)Inicializando Terraform...$(NC)"
	cd $(TERRAFORM_DIR) && terraform init -upgrade

validate: ## Validar configuración de Terraform
	@echo "$(BLUE)Validando configuración...$(NC)"
	cd $(TERRAFORM_DIR) && terraform validate

fmt: ## Formatear archivos de Terraform
	@echo "$(BLUE)Formateando archivos...$(NC)"
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

plan: init validate ## Generar plan de ejecución
	@echo "$(BLUE)Generando plan para $(ENV)...$(NC)"
	cd $(SCRIPTS_DIR) && ./deploy-infrastructure.sh $(ENV) plan

apply: ## Aplicar cambios de infraestructura
	@echo "$(BLUE)Aplicando cambios para $(ENV)...$(NC)"
	cd $(SCRIPTS_DIR) && ./deploy-infrastructure.sh $(ENV) apply

destroy: ## Destruir infraestructura
	@echo "$(YELLOW)⚠️  Destruyendo infraestructura de $(ENV)...$(NC)"
	cd $(SCRIPTS_DIR) && ./deploy-infrastructure.sh $(ENV) destroy

deploy-app: ## Desplegar aplicación
	@echo "$(BLUE)Desplegando aplicación a $(ENV)...$(NC)"
	cd $(SCRIPTS_DIR) && ./deploy-app.sh $(ENV)

deploy-all: apply deploy-app ## Desplegar infraestructura y aplicación
	@echo "$(GREEN)✓ Despliegue completo finalizado$(NC)"

outputs: ## Mostrar outputs de Terraform
	@echo "$(BLUE)Outputs de $(ENV):$(NC)"
	cd $(TERRAFORM_DIR) && terraform output

outputs-json: ## Mostrar outputs en formato JSON
	cd $(TERRAFORM_DIR) && terraform output -json

clean: ## Limpiar archivos temporales
	@echo "$(BLUE)Limpiando archivos temporales...$(NC)"
	find . -name "*.zip" -type f -delete
	find . -name "*.tfplan" -type f -delete
	find . -name "outputs-*.json" -type f -delete
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

logs: ## Ver logs de App Service
	@echo "$(BLUE)Logs de App Service en $(ENV):$(NC)"
	@APP_NAME=$$(cd $(TERRAFORM_DIR) && terraform output -json app_service_names | jq -r '.[0]') && \
	az webapp log tail --name $$APP_NAME --resource-group rg-envia-$(ENV)

health: ## Verificar health de la aplicación
	@echo "$(BLUE)Verificando health de $(ENV):$(NC)"
	@GATEWAY_IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw app_gateway_public_ip) && \
	curl -s https://$$GATEWAY_IP/health | jq

test-api: ## Probar API
	@echo "$(BLUE)Probando API de $(ENV):$(NC)"
	@GATEWAY_IP=$$(cd $(TERRAFORM_DIR) && terraform output -raw app_gateway_public_ip) && \
	echo "Health:" && curl -s https://$$GATEWAY_IP/health | jq && \
	echo "\nAPI Info:" && curl -s https://$$GATEWAY_IP/api/ | jq

install-deps: ## Instalar dependencias de la aplicación
	@echo "$(BLUE)Instalando dependencias...$(NC)"
	cd src && npm install

test: ## Ejecutar tests de la aplicación
	@echo "$(BLUE)Ejecutando tests...$(NC)"
	cd src && npm test

dev: ## Ejecutar aplicación en modo desarrollo
	@echo "$(BLUE)Iniciando servidor de desarrollo...$(NC)"
	cd src && npm run dev

# Comandos de Azure CLI
az-login: ## Login en Azure
	az login

az-account: ## Mostrar cuenta actual de Azure
	az account show

az-list-resources: ## Listar recursos del environment
	@echo "$(BLUE)Recursos en $(ENV):$(NC)"
	az resource list --resource-group rg-envia-$(ENV) --output table

az-costs: ## Mostrar costos estimados
	@echo "$(BLUE)Costos de $(ENV):$(NC)"
	az consumption usage list --resource-group rg-envia-$(ENV) --output table

# Comandos de base de datos
db-connect: ## Conectar a MySQL
	@echo "$(BLUE)Conectando a MySQL de $(ENV)...$(NC)"
	@MYSQL_HOST=$$(cd $(TERRAFORM_DIR) && terraform output -raw mysql_server_fqdn) && \
	MYSQL_USER=$$(cd $(TERRAFORM_DIR) && terraform output -raw mysql_admin_username) && \
	KEY_VAULT=$$(cd $(TERRAFORM_DIR) && terraform output -raw key_vault_name) && \
	MYSQL_PASS=$$(az keyvault secret show --vault-name $$KEY_VAULT --name mysql-admin-password --query value -o tsv) && \
	mysql -h $$MYSQL_HOST -u $$MYSQL_USER -p$$MYSQL_PASS

db-init: ## Inicializar base de datos
	@echo "$(BLUE)Inicializando base de datos de $(ENV)...$(NC)"
	@MYSQL_HOST=$$(cd $(TERRAFORM_DIR) && terraform output -raw mysql_server_fqdn) && \
	MYSQL_USER=$$(cd $(TERRAFORM_DIR) && terraform output -raw mysql_admin_username) && \
	KEY_VAULT=$$(cd $(TERRAFORM_DIR) && terraform output -raw key_vault_name) && \
	MYSQL_PASS=$$(az keyvault secret show --vault-name $$KEY_VAULT --name mysql-admin-password --query value -o tsv) && \
	mysql -h $$MYSQL_HOST -u $$MYSQL_USER -p$$MYSQL_PASS < $(SCRIPTS_DIR)/database/init.sql

# Comandos de monitoreo
monitor-app: ## Abrir Application Insights en el portal
	@echo "$(BLUE)Abriendo Application Insights...$(NC)"
	az portal open --resource-group rg-envia-$(ENV) --resource-type Microsoft.Insights/components

monitor-gateway: ## Ver health del Application Gateway
	@echo "$(BLUE)Health del Application Gateway:$(NC)"
	az network application-gateway show-backend-health \
		--name appgw-envia-$(ENV) \
		--resource-group rg-envia-$(ENV) \
		--output table
