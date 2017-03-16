.PHONY: deploy
DOCKER_REPOSITORY?=nanit
SUDO?=sudo

RABBITMQ_APP_NAME=rabbitmq
RABBITMQ_SERVICE_NAME=rabbitmq
RABBITMQ_MANAGEMENT_SERVICE_NAME=rabbitmq-management
RABBITMQ_HEADLESS_SERVICE_NAME=rmq-cluster
RABBITMQ_DOCKER_DIR=docker
RABBITMQ_IMAGE_TAG=$(shell git log -n 1 --pretty=format:%h $(RABBITMQ_DOCKER_DIR))
RABBITMQ_IMAGE_NAME=$(DOCKER_REPOSITORY)/$(RABBITMQ_APP_NAME):$(RABBITMQ_IMAGE_TAG)
RABBITMQ_REPLICAS?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/replicas)
RABBITMQ_DEFAULT_USER?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/user)
RABBITMQ_DEFAULT_PASS?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/password)
RABBITMQ_ERLANG_COOKIE?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/erlang_cookie)
RABBITMQ_EXPOSE_MANAGEMENT?=$(shell curl -s config/$(NANIT_ENV)/$(RABBITMQ_APP_NAME)/expose_management)
RABBITMQ_SET_HA_POLICY=TRUE

define generate-rabbitmq-headless-svc
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s/{{SVC_NAME}}/$(RABBITMQ_HEADLESS_SERVICE_NAME)/g' kube/svc.headless.yml
endef

define generate-rabbitmq-management-svc
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s/{{SVC_NAME}}/$(RABBITMQ_MANAGEMENT_SERVICE_NAME)/g' kube/svc.management.yml
endef

define generate-rabbitmq-svc
	sed -e 's/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s/{{SVC_NAME}}/$(RABBITMQ_SERVICE_NAME)/g' kube/svc.yml
endef

define generate-rabbitmq-stateful-set
	if [ -z "$(RABBITMQ_REPLICAS)" ]; then echo "ERROR: RABBITMQ_REPLICAS is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_DEFAULT_USER)" ]; then echo "ERROR: RABBITMQ_DEFAULT_USER is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_DEFAULT_PASS)" ]; then echo "ERROR: RABBITMQ_DEFAULT_PASS is empty!"; exit 1; fi
	if [ -z "$(RABBITMQ_ERLANG_COOKIE)" ]; then echo "ERROR: RABBITMQ_ERLANG_COOKIE is empty!"; exit 1; fi
	sed -e 's/{{SVC_NAME}}/$(RABBITMQ_HEADLESS_SERVICE_NAME)/g;s/{{APP_NAME}}/$(RABBITMQ_APP_NAME)/g;s,{{IMAGE_NAME}},$(RABBITMQ_IMAGE_NAME),g;s/{{REPLICAS}}/$(RABBITMQ_REPLICAS)/g;s/{{RABBITMQ_DEFAULT_USER}}/$(RABBITMQ_DEFAULT_USER)/g;s/{{RABBITMQ_DEFAULT_PASS}}/$(RABBITMQ_DEFAULT_PASS)/g;s/{{RABBITMQ_ERLANG_COOKIE}}/$(RABBITMQ_ERLANG_COOKIE)/g' kube/stateful.set.yml
endef

define set-ha-policy-on-rabbitmq-cluster
	if [ "$(RABBITMQ_SET_HA_POLICY)" = "TRUE" ]; then
		while true ; do 
			echo "Waiting for RabbitMQ pod to be ready...."
			if [[ $(kubectl get pods | grep rabbitmq- | grep Running) ]]; then
				kubectl exec rabbitmq-0 rabbitmqctl set_policy ha-all ".*" '{"ha-mode":"all"}' --apply-to queues
				break
			fi
			echo "RabbitMQ pod still not ready..."
			sleep 5
		done
	fi
endef

deploy-rabbitmq: docker-rabbitmq
	kubectl get svc $(RABBITMQ_APP_NAME) || $(call generate-rabbitmq-svc) | kubectl create -f -
	kubectl get svc $(RABBITMQ_HEADLESS_SERVICE_NAME) || $(call generate-rabbitmq-headless-svc) | kubectl create -f -
	if [ "$(RABBITMQ_EXPOSE_MANAGEMENT)" = "TRUE" ]; then kubectl get svc $(RABBITMQ_MANAGEMENT_SERVICE_NAME) || $(call generate-rabbitmq-management-svc) | kubectl create -f - ; fi
	$(call generate-rabbitmq-stateful-set) | kubectl apply -f -
	$(call set-ha-policy-on-rabbitmq-cluster)

docker-rabbitmq:
	$(SUDO) docker pull $(RABBITMQ_IMAGE_NAME) || ($(SUDO) docker build -t $(RABBITMQ_IMAGE_NAME) $(RABBITMQ_DOCKER_DIR) && $(SUDO) docker push $(RABBITMQ_IMAGE_NAME))

deploy: deploy-rabbitmq

