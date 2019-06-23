.PHONY: deploy
DOCKER_REPOSITORY?=nanit
CONFIG_NAME=rabbitmq
SUDO?=sudo

RABBITMQ_APP_NAME?=rabbitmq
RABBITMQ_SERVICE_NAME?=$(RABBITMQ_APP_NAME)
RABBITMQ_MANAGEMENT_SERVICE_NAME?=$(RABBITMQ_SERVICE_NAME)-management
RABBITMQ_HEADLESS_SERVICE_NAME?=$(RABBITMQ_SERVICE_NAME)-headless
RABBITMQ_DOCKER_DIR=docker
NAMESPACE?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/namespace)
RBAC?=FALSE
SERVICE_ACCOUNT=$(shell if [ "$(RBAC)" = "TRUE" ]; then echo '\"serviceAccount\": \"$(RABBITMQ_APP_NAME)-sa\"'; fi)
RABBITMQ_IMAGE_TAG=$(shell git log -n 1 --pretty=format:%h $(RABBITMQ_DOCKER_DIR))
RABBITMQ_IMAGE_NAME=$(DOCKER_REPOSITORY)/$(RABBITMQ_APP_NAME):$(RABBITMQ_IMAGE_TAG)
RABBITMQ_REPLICAS?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/replicas)
RABBITMQ_ADDITIONAL_YAML?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/additional_yaml)
RABBITMQ_DEFAULT_USER?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/user)
RABBITMQ_DEFAULT_PASS?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/password)
RABBITMQ_ERLANG_COOKIE?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/erlang_cookie)
RABBITMQ_EXPOSE_MANAGEMENT?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/expose_management)
RABBITMQ_MANGEMENT_SERVICE_TYPE?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/management_service_type)
RABBITMQ_HA_POLICY?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/ha_policy)
RABBITMQ_LOG_LEVEL?=$(shell curl -s config/$(NANIT_ENV)/$(CONFIG_NAME)/log_level)

define generate-rabbitmq-headless-svc
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s/{{SVC_NAME}}/$(RABBITMQ_HEADLESS_SERVICE_NAME)/g' kube/svc.headless.yml
endef

define generate-rabbitmq-management-svc
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s/{{SVC_NAME}}/$(RABBITMQ_MANAGEMENT_SERVICE_NAME)/g;s/{{SERVICE_TYPE}}/$(RABBITMQ_MANAGEMENT_SERVICE_TYPE)/g' kube/svc.management.yml
endef

define generate-rabbitmq-svc
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s/{{SVC_NAME}}/$(RABBITMQ_SERVICE_NAME)/g' kube/svc.yml
endef

define generate-rabbitmq-stateful-set
	if [ -z "$(RABBITMQ_REPLICAS)" ]; then echo "ERROR: RABBITMQ_REPLICAS is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_DEFAULT_USER)" ]; then echo "ERROR: RABBITMQ_DEFAULT_USER is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_DEFAULT_PASS)" ]; then echo "ERROR: RABBITMQ_DEFAULT_PASS is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_ERLANG_COOKIE)" ]; then echo "ERROR: RABBITMQ_ERLANG_COOKIE is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_LOG_LEVEL)" ]; then echo "ERROR: RABBITMQ_LOG_LEVEL is empty!"; exit 1; fi
	sed -e 's/{{SVC_NAME}}/$(RABBITMQ_HEADLESS_SERVICE_NAME)/g;s/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s,{{IMAGE_NAME}},$(RABBITMQ_IMAGE_NAME),g;s/{{REPLICAS}}/$(RABBITMQ_REPLICAS)/g;s/{{RABBITMQ_DEFAULT_USER}}/$(RABBITMQ_DEFAULT_USER)/g;s/{{RABBITMQ_DEFAULT_PASS}}/$(RABBITMQ_DEFAULT_PASS)/g;s/{{RABBITMQ_ERLANG_COOKIE}}/$(RABBITMQ_ERLANG_COOKIE)/g;s/{{RABBITMQ_LOG_LEVEL}}/$(RABBITMQ_LOG_LEVEL)/g;s/{{SERVICE_ACCOUNT}}/$(SERVICE_ACCOUNT)/g;s@{{ADDITIONAL_YAML}}@$(RABBITMQ_ADDITIONAL_YAML)@g' kube/stateful.set.yml
endef

define generate-ha-policy-on-rabbitmq-cluster
	sed -i -e 's/{{RABBITMQ_HA_POLICY}}/$(RABBITMQ_HA_POLICY)/g' docker/set_ha.sh
endef

define set-rbac-policy
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s/{{NAMESPACE}}/$(NAMESPACE)/g' kube/rbac.role.yml
endef

deploy-rabbitmq: docker-rabbitmq
	kubectl get ns $(NAMESPACE) || kubectl create ns $(NAMESPACE)
	kubectl get svc -n $(NAMESPACE) $(RABBITMQ_APP_NAME) || $(call generate-rabbitmq-svc) | kubectl create -n $(NAMESPACE) -f -
	if [ "$(RBAC)" = "TRUE" ]; then $(call set-rbac-policy) | kubectl apply -f - ; fi
	kubectl get svc -n $(NAMESPACE) $(RABBITMQ_HEADLESS_SERVICE_NAME) || $(call generate-rabbitmq-headless-svc) | kubectl create -n $(NAMESPACE) -f -
	if [ "$(RABBITMQ_EXPOSE_MANAGEMENT)" = "TRUE" ]; then kubectl get svc -n $(NAMESPACE) $(RABBITMQ_MANAGEMENT_SERVICE_NAME) || $(call generate-rabbitmq-management-svc) | kubectl create -n $(NAMESPACE) -f - ; fi
	$(call generate-rabbitmq-stateful-set) | kubectl apply -n $(NAMESPACE) -f -

docker-rabbitmq:
	$(call generate-ha-policy-on-rabbitmq-cluster)
	$(SUDO) docker pull $(RABBITMQ_IMAGE_NAME) || ($(SUDO) docker build -t $(RABBITMQ_IMAGE_NAME) $(RABBITMQ_DOCKER_DIR) && $(SUDO) docker push $(RABBITMQ_IMAGE_NAME))

deploy: deploy-rabbitmq

clean:
	kubectl delete statefulset $(RABBITMQ_APP_NAME) || true
	kubectl delete service $(RABBITMQ_SERVICE_NAME) || true
	kubectl delete service $(RABBITMQ_MANAGEMENT_SERVICE_NAME) || true
	kubectl delete service $(RABBITMQ_HEADLESS_SERVICE_NAME) || true
