.PHONY: install lint lint-strict run run-docker \
		build push deploy create-sa \
		setup-secret destroy all

PROJECT_ID := $(PROJECT_ID)
SECRET_NAME := GOOGLE_API_KEY
REPOSITORY_NAME := cloud-run-app
IMAGE_NAME := cloud-run-app
SERVICE_NAME := cloud-run-app
SERVICE_ACCOUNT_NAME := cloud-run-app-sa
IMAGE_URI := us-central1-docker.pkg.dev/$(PROJECT_ID)/$(REPOSITORY_NAME)/$(IMAGE_NAME)
SHELL := /bin/bash

# Para desarrollo local
.venv/bin/activate:
	@# suprime la salida
	@test -d .venv || uv venv .venv --python=3.11  

install: .venv/bin/activate
	uv sync

install-dev: .venv/bin/activate
	uv sync --dev

lint: install-dev
	uv run ruff check .

lint-strict: install-dev
	uv run ruff check . --select E,F,B,I,N,D,UP,C4,ANN,ARG

run: install
	uv run uvicorn src.main:app --host 0.0.0.0 --port 8080

build:
	docker build -t $(IMAGE_NAME) .

run-docker: build
	docker run --rm --env-file .env -p 8080:8080 cloud-run-app

setup-gcloud:
	@echo "Autenticando con Google Cloud ..." && \
	gcloud auth login && \
	echo "Uilizando el proyecto $(PROJECT_ID) ..." && \
	gcloud config set project $(PROJECT_ID)

enable-gcloud-apis:
	gcloud services enable artifactregistry.googleapis.com \
	secretmanager.googleapis.com \
	run.googleapis.com

disable-gcloud-apis:
	gcloud services disable artifactregistry.googleapis.com \
	secretmanager.googleapis.com \
	run.googleapis.com

check-enabled-apis:
	gcloud services list --enabled

create-artifact-registry:
	@echo "Creando repositorio para $(SERVICE_NAME) ..."
	gcloud artifacts repositories create $(REPOSITORY_NAME) --repository-format=docker \
    --location=us-central1 --description="Repositorio de mi imagen" \
	--disable-vulnerability-scanning

delete-artifact-registry:
	gcloud artifacts repositories delete $(REPOSITORY_NAME) --location=us-central1

# Crear un secret (best practice)
create-api-key-secret:
	gcloud secrets create $(SECRET_NAME) \
	--replication-policy="automatic" && \
	gcloud secrets versions add $(SECRET_NAME) \
	--data-file=<(grep '^$(SECRET_NAME)=' .env | cut -d '=' -f2- | tr -d '\n')

delete-api-key-secret:
	gcloud secrets delete $(SECRET_NAME) --project $(PROJECT_ID)

create-sa:
	@echo "Creando Service Account $(SERVICE_ACCOUNT_NAME) con acceso a secrets ..." && \
	gcloud iam service-accounts create $(SERVICE_ACCOUNT_NAME) \
	--display-name="SA Para mi app en Cloud Run" && \
	gcloud secrets add-iam-policy-binding $(SECRET_NAME) \
	--member="serviceAccount:$(SERVICE_ACCOUNT_NAME)@$(PROJECT_ID).iam.gserviceaccount.com" \
	--role="roles/secretmanager.secretAccessor" \

delete-sa:
	@echo "Eliminando Service Account $(SERVICE_ACCOUNT_NAME) ..." && \
	gcloud iam service-accounts delete "$(SERVICE_ACCOUNT_NAME)@$(PROJECT_ID).iam.gserviceaccount.com" \
	--project=$(PROJECT_ID)

push:
	echo "Autenticando con Artifact Registry ..." && \
	gcloud auth configure-docker us-central1-docker.pkg.dev && \
	echo "re-taggeando imagen local ..." && \
	docker tag $(IMAGE_NAME) $(IMAGE_URI)
	docker push $(IMAGE_URI)

create-cloud-run-service:
	gcloud run deploy $(SERVICE_NAME) \
	--image $(IMAGE_URI) \
	--region us-central1 \
	--platform managed \
	--allow-unauthenticated \
	--update-secrets=$(SECRET_NAME)=$(SECRET_NAME):latest \
	--service-account "$(SERVICE_ACCOUNT_NAME)@$(PROJECT_ID).iam.gserviceaccount.com" \
	--project $(PROJECT_ID)

delete-cloud-run-service:
	gcloud run services delete $(SERVICE_NAME) --region us-central1 --project $(PROJECT_ID)

deploy: build push create-cloud-run-service

deploy-all: create-artifact-registry create-api-key-secret create-sa deploy

delete-all: delete-cloud-run-service delete-sa delete-api-key-secret delete-artifact-registry
