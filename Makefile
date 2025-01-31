# Makefile

# Variables
PYTEST  = pytest --cov app --cov-append --cov-report=html -v $(OPTS)
COMPILE = pip-compile -v
TERRAFORM_DIR ?= ./terraform
ENV ?= dev
VERSION ?= latest
EKS_CLUSTER_NAME=$(shell cd $(TERRAFORM_DIR) && terraform output -raw cluster_name)
KUBECONFIG_PATH=$(HOME)/.kube/config


all: help

##
## Python environment targets
##

env:  ## build python env
	@echo "==> Creating virtual environment in 'venv'"
	python -m venv venv
	@echo "==> Activating venv and installing requirements"
	. venv/bin/activate && pip install --upgrade pip pip-tools==7.0.0
	. venv/bin/activate && pip install -r requirements/requirements.txt

env_test: env  ## build python env for testing
	@echo "==> Installing test requirements in venv"
	. venv/bin/activate && pip install -r requirements/requirements-test.txt

pip_compile:  ## create requirements
	. venv/bin/activate && $(COMPILE) requirements/requirements.in
	. venv/bin/activate && $(COMPILE) requirements/requirements-test.in

pip_upgrade:  ## upgrade requirements
	. venv/bin/activate && $(COMPILE) -U requirements/requirements.in
	. venv/bin/activate && $(COMPILE) -U requirements/requirements-test.in

pip_sync:  ## sync requirements
	. venv/bin/activate && pip-sync -v requirements/requirements.txt requirements/requirements-test.txt

##
## Formatting & code checks
##

black:  ## format code with black
	. venv/bin/activate && black -l120 .

format:  ## check black code formatting
	. venv/bin/activate && black -l120 --check .

flake:  ## check using flake8
	. venv/bin/activate && flake8 . --max-line-length 120 --ignore=W605,W503,E203

mypy:  ## check python typing using mypy
	. venv/bin/activate && pip install types-mock types-tabulate
	. venv/bin/activate && mypy . --ignore-missing-imports

autoflake:
	. venv/bin/activate && autoflake --in-place --remove-all-unused-imports --expand-star-imports --remove-duplicate-keys --remove-unused-variables **/*.*
	. venv/bin/activate && black -l120 .

##
## Tests & Coverage
##

unit:  ## run unit tests
	. venv/bin/activate && pytest -vvv -rPxf --cov=. --cov-append --cov-report term-missing tests

coverage:  ## coverage report
	. venv/bin/activate && coverage report --fail-under 90
	. venv/bin/activate && coverage html -i

pytest: unit coverage  ## run all tests and test coverage

test: env_test format mypy flake pytest  ## check environment, build, lint, tests

##
## Terraform-related targets
##

tf_clear: ## remove .terraform artifacts
	cd $(TERRAFORM_DIR) && rm -rf .terraform.lock.hcl .terraform

tf_init: ## run terraform init for the given ENV
	cd $(TERRAFORM_DIR) && terraform init -backend-config=./backends/$(ENV).backend -reconfigure

tf_fmt_validate: ## format & validate your Terraform
	cd $(TERRAFORM_DIR) && terraform fmt --recursive
	cd $(TERRAFORM_DIR) && terraform validate

tf_plan: ## run terraform plan for the given ENV and VERSION

	@echo "==> Terraform plan (ENV=$(ENV), VERSION=$(VERSION))"
	cd $(TERRAFORM_DIR) && \
		TF_VAR_service_version=$(VERSION) \
		terraform plan -var-file=$(ENV).tfvars -out="$(ENV).tfplan"


tf_apply: ## run terraform apply for the given ENV and VERSION


	@echo "==> Terraform apply (ENV=$(ENV), VERSION=$(VERSION))"
	cd $(TERRAFORM_DIR) && \
		TF_VAR_service_version=$(VERSION) \
		terraform apply "$(ENV).tfplan"

tf_outputs: ## run terraform output

	@echo "==> Terraform output (ENV=$(ENV), VERSION=$(VERSION))"
	cd $(TERRAFORM_DIR) && \
	terraform output


##
## K8s
##

kubeconfig: ## kubeconfig
	cd $(TERRAFORM_DIR) && terraform refresh
	aws eks update-kubeconfig --name $(EKS_CLUSTER_NAME)
	@echo "export KUBECONFIG=$(KUBECONFIG_PATH)"


##
## Help target
##

help: ## print help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
