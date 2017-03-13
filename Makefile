DOCKER_REPOSITORY?=nanit
SUDO?=sudo

RABBITMQ_APP_NAME=rabbitmq
RABBITMQ_DOCKER_DIR=docker
RABBITMQ_IMAGE_TAG=$(shell git log -n 1 --pretty=format:%h $(RABBITMQ_DOCKER_DIR))
RABBITMQ_IMAGE_NAME=$(DOCKER_REPOSITORY)/$(RABBITMQ_APP_NAME):$(RABBITMQ_IMAGE_TAG)
RABBITMQ_REPLICAS?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/replicas)
RABBITMQ_USER?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/user)
RABBITMQ_PASSWORD?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/password)
RABBITMQ_ERLANG_COOKIE?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/erlang_cookie)

define generate-rabbitmq-svc
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g' kube/svc.yml
endef

define generate-rabbitmq-stateful-set
	if [ -z "$(RABBITMQ_REPLICAS)" ]; then echo "ERROR: RABBITMQ_REPLICAS is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_USER)" ]; then echo "ERROR: RABBITMQ_USER is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_PASSWORD)" ]; then echo "ERROR: RABBITMQ_PASSWORD is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_ERLANG_COOKIE)" ]; then echo "ERROR: RABBITMQ_ERLANG_COOKIE is empty!"; exit 1; fi
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s,{{IMAGE_NAME}},$(RABBITMQ_IMAGE_NAME),g;s/{{REPLICAS}}/$(RABBITMQ_REPLICAS)/g;s/{{RABBITMQ_USER}}/$(RABBITMQ_USER)/g;s/{{RABBITMQ_PASSWORD}}/$(RABBITMQ_PASSWORD)/g;s/{{RABBITMQ_ERLANG_COOKIE}}/$(RABBITMQ_ERLANG_COOKIE)/g' kube/stateful.set.yml
endef

deploy-rabbitmq: docker-rabbitmq
	kubectl get svc $(RABBITMQ_APP_NAME) || $(call generate-rabbitmq-svc) | kubectl create -f -
	$(call generate-rabbitmq-stateful-set) | kubectl apply -f -

docker-rabbitmq:
	$(SUDO) docker pull $(RABBITMQ_IMAGE_NAME) || ($(SUDO) docker build -t $(RABBITMQ_IMAGE_NAME) $(RABBITMQ_DOCKER_DIR) && $(SUDO) docker push $(RABBITMQ_IMAGE_NAME))

deploy: deploy-rabbitmq

