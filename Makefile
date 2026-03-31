# Echo-Envia Infrastructure Makefile
# Comandos para gestionar la infraestructura de la plataforma de envíos

.PHONY: help init plan apply destroy clean validate fmt docs

# Variables
TERRAFORM_DIR := terraform
ENV ?= dev
TFVARS_FILE := environments/$(ENV).tfvars

help: ## Mostrar ayuda
	@echo "Echo-Envia Infrastructure Management"
	@echo "===================================="
	@echo ""
	@echo "Comandos disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Inicializar Terraform
	@echo "🚀 Inicializando Terraform para Echo-Envia..."
	cd $(TERRAFORM_DIR) && terraform init

validate: ## Validar configuración de Terraform
	@echo "✅ Validando configuración de Terraform..."
	cd $(TERRAFORM_DIR) && terraform validate

fmt: ## Formatear archivos de Terraform
	@echo "🎨 Formateando archivos de Terraform..."
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

plan: ## Planificar cambios (ENV=dev|staging|prod)
	@echo "📋 Planificando despliegue para entorno: $(ENV)"
	cd $(TERRAFORM_DIR) && terraform plan -var-file="$(TFVARS_FILE)" -out=tfplan-$(ENV)

apply: ## Aplicar cambios (ENV=dev|staging|prod)
	@echo "🚀 Desplegando infraestructura para entorno: $(ENV)"
	cd $(TERRAFORM_DIR) && terraform apply -var-file="$(TFVARS_FILE)" -auto-approve

apply-plan: ## Aplicar plan específico (ENV=dev|staging|prod)
	@echo "🚀 Aplicando plan para entorno: $(ENV)"
	cd $(TERRAFORM_DIR) && terraform apply tfplan-$(ENV)

destroy: ## Destruir infraestructura (ENV=dev|staging|prod)
	@echo "🗑️ Destruyendo infraestructura para entorno: $(ENV)"
	@echo "⚠️  Esta acción es irreversible. Presiona Ctrl+C para cancelar."
	@sleep 5
	cd $(TERRAFORM_DIR) && terraform destroy -var-file="$(TFVARS_FILE)" -auto-approve

output: ## Mostrar outputs de Terraform
	@echo "📊 Outputs de Terraform:"
	cd $(TERRAFORM_DIR) && terraform output

clean: ## Limpiar archivos temporales
	@echo "🧹 Limpiando archivos temporales..."
	find $(TERRAFORM_DIR) -name "*.tfplan" -delete
	find $(TERRAFORM_DIR) -name "tfplan-*" -delete
	find . -name ".DS_Store" -delete

# Comandos de desarrollo
dev-init: ## Inicializar entorno de desarrollo
	@echo "🔧 Configurando entorno de desarrollo..."
	$(MAKE) init
	$(MAKE) validate
	$(MAKE) fmt

dev-deploy: ## Desplegar entorno de desarrollo
	$(MAKE) plan ENV=dev
	$(MAKE) apply-plan ENV=dev

dev-destroy: ## Destruir entorno de desarrollo
	$(MAKE) destroy ENV=dev

# Comandos de aplicación
app-build: ## Construir aplicación Node.js
	@echo "📦 Construyendo aplicación Echo-Envia..."
	cd src && npm install

app-start: ## Iniciar aplicación localmente
	@echo "🚀 Iniciando Echo-Envia API..."
	cd src && npm start

app-dev: ## Iniciar aplicación en modo desarrollo
	@echo "🔧 Iniciando Echo-Envia API en modo desarrollo..."
	cd src && npm run dev

# Default target
.DEFAULT_GOAL := help