PLATFORM_DIR := platform

.DEFAULT_GOAL := help

.PHONY: help bootstrap init plan apply destroy fmt validate outputs secrets unlock

help:
	@echo ""
	@echo "Usage: make <target>  (requires: export AWS_PROFILE=mine)"
	@echo ""
	@echo "  bootstrap   First-time deploy: local init → apply → migrate state to S3 → sync GH secrets"
	@echo "  init        terraform init with S3 backend  (requires platform/backend.tfvars)"
	@echo "  plan        terraform plan  (saved to platform/tfplan)"
	@echo "  apply       terraform apply tfplan"
	@echo "  destroy     terraform destroy"
	@echo "  fmt         terraform fmt  (auto-fix formatting)"
	@echo "  validate    terraform validate"
	@echo "  outputs     show terraform outputs"
	@echo "  secrets     sync GitHub Actions secrets from terraform outputs"
	@echo "  unlock      force-unlock stuck state  (usage: make unlock LOCK_ID=<id>)"
	@echo ""

bootstrap:
	@echo "==> [1/3] Init with local backend (S3 bucket does not exist yet)..."
	cd $(PLATFORM_DIR) && terraform init -backend=false
	@echo "==> [2/3] Apply (creates S3 state bucket and all infrastructure)..."
	cd $(PLATFORM_DIR) && terraform apply
	@echo "==> [3/3] Migrate local state to S3 and sync GitHub secrets..."
	cd $(PLATFORM_DIR) && terraform init -migrate-state -backend-config=backend.tfvars
	cd $(PLATFORM_DIR) && ./setup-oidc.sh

init:
	cd $(PLATFORM_DIR) && terraform init -input=false -backend-config=backend.tfvars

plan: init
	cd $(PLATFORM_DIR) && terraform plan -input=false -out=tfplan

apply: plan
	cd $(PLATFORM_DIR) && terraform apply -input=false tfplan

destroy:
	cd $(PLATFORM_DIR) && terraform destroy

fmt:
	cd $(PLATFORM_DIR) && terraform fmt -recursive

validate: init
	cd $(PLATFORM_DIR) && terraform validate

outputs:
	cd $(PLATFORM_DIR) && terraform output

secrets:
	cd $(PLATFORM_DIR) && ./setup-oidc.sh

unlock:
	@test -n "$(LOCK_ID)" || (echo "Error: usage: make unlock LOCK_ID=<id>" && exit 1)
	cd $(PLATFORM_DIR) && terraform force-unlock $(LOCK_ID)
