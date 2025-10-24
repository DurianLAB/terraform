.PHONY: init plan apply destroy validate fmt dev-plan dev-apply dev-destroy staging-plan staging-apply staging-destroy prod-plan prod-apply prod-destroy

export TF_VAR_ssh_public_key := $(shell cat id_ed25519.pub)

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply

destroy:
	terraform destroy

validate:
	terraform validate

fmt:
	terraform fmt -recursive

dev-plan:
	terraform workspace select dev || terraform workspace new dev
	terraform plan

dev-apply:
	terraform workspace select dev || terraform workspace new dev
	terraform apply

dev-destroy:
	terraform workspace select dev
	terraform destroy

staging-plan:
	terraform workspace select staging || terraform workspace new staging
	terraform plan

staging-apply:
	terraform workspace select staging || terraform workspace new staging
	terraform apply

staging-destroy:
	terraform workspace select staging
	terraform destroy

prod-plan:
	terraform workspace select prod || terraform workspace new prod
	terraform plan

prod-apply:
	terraform workspace select prod || terraform workspace new prod
	terraform apply

prod-destroy:
	terraform workspace select prod
	terraform destroy