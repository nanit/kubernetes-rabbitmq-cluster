# kubernetes-rabbitmq-cluster

A ready to deploy rabbitmq cluster to work on top of Kubernetes.

It uses [rabbitmq clusterer plugin](https://github.com/rabbitmq/rabbitmq-clusterer) to achieve clustering.

## Requirements:
1. Kubernetes version 1.5.X (We're using StatefulSet)
2. kubectl configured to work with your Kubernetes API
3. Tested on Kubernetes 1.5.2 on top of AWS (See future work)
4. Optional - Access to your own docker repository to store your own images. That's relevant if you don't want to use the default images offered here.

## Contents:

1. A 3 nodes rabbitmq cluster as StatefulSet
2. A rabbitmq-headless headless service to control the StatefulSet domain
3. a rabbitmq service to access the cluster
4. An optional, rabbitmq-management service to access the admin control panel

## Environment Variables:
| Name                         | Default Value         | Purpose                                                                  
|------------------------------|-----------------------|--------------------------------------------------------------------------
| NAMESPACE                    | default               | Change it if you want to create the RabbitMQ cluster in a custom Kubernetes namespace. If the namespace does not exist in the moment of deployment, it will be created for you.          
| DOCKER_REPOSITORY            | nanit                 | Change it if you want to build and use custom docker repository    
| POD_MEMORY_REQUEST           | None                  | memory allocated per pod by default         
| POD_CPU_REQUEST              | None                  | cpu per pod
| SUDO                         | sudo                  | Should docker commands be prefixed with sudo. Change to "" to omit sudo.
| RBAC                         | FALSE                 | Should create a role/system account and role binding
| RABBITMQ_REPLICAS            | 3                     | Number of nodes in the cluster                                           
| RABBITMQ_DEFAULT_USER        | None                  | The default username to access the management console                    
| RABBITMQ_DEFAULT_PASS        | None                  | The default password to access the management console                    
| RABBITMQ_ERLANG_COOKIE       | None                  | Erlang secret needed for nodes communication                             
| RABBITMQ_EXPOSE_MANAGEMENT   | FALSE                 | Should RMQ management console be exposed as a service              
| RABBITMQ_MANAGEMENT_SERVICE_TYPE   | LoadBalancer    | [Kubernetes service](https://kubernetes.io/docs/concepts/services-networking/service/) type for the management console                       
| RABBITMQ_HA_POLICY           | None                  | Set this variable to automatically set [HA policy](https://www.rabbitmq.com/ha.html) on all queues           
| RABBITMQ_LOG_LEVEL           | info                  | Log levels are set for all RabbitMQ log types: connection, mirroring, channel and federation. Valid values are: none, error, warning, info, debug 
| RABBITMQ_ADDITIONAL_YAML     | ""                    | Inject additional arbitrary YAML into the stateful set 

## Deployment:

1. Clone this repository
2. Run:

```
export NAMESPACE=default && \
export DOCKER_REPOSITORY=nanit && \
export POD_CPU_REQUEST=300m && \
export POD_MEMORY_REQUEST=5Gi && \
export RABBITMQ_REPLICAS=5 && \
export RABBITMQ_DEFAULT_USER=username && \
export RABBITMQ_DEFAULT_PASS=password && \
export RABBITMQ_ERLANG_COOKIE=secret && \
export RABBITMQ_EXPOSE_MANAGEMENT=TRUE && \
export RABBITMQ_MANAGEMENT_SERVICE_TYPE=LoadBalancer && \
export RABBITMQ_HA_POLICY='{\"ha-mode\":\"all\"}' && \
export RABBITMQ_LOG_LEVEL=info && \
export RABBITMQ_ADDITIONAL_YAML="" && \
export SUDO="" && \
make deploy
```

## Usage:

At the end of the installation you should have a service named `rabbitmq` which you can use to connect to the cluster.
If you've set the environment variable `RABBITMQ_HA_POLICY` a policy named `ha-all` is created to match all queues.
These are the resource you're supposed to see on the cluster when running `kubectl get pods,svc`:

![k8s-resources](https://github.com/nanit/kubernetes-rabbitmq-cluster/blob/master/k8s-resources.png)

Please note the following:

1. The number of rabbitmq pods may be different in case you chose a different number of `RABBITMQ_REPLICAS` than 5
2. The rabbitmq-management service will only be available if you've set `RABBITMQ_EXPOSE_MANAGEMENT` to TRUE


## Changing the number of nodes:

Number of nodes is configurable with RABBITMQ_REPLICAS environment variable.
Note that changing the number of nodes after the initial deployment of the cluster is problematic since old rabbitmq instance won't fetch the new nodes hosts into the clusterer.config file.

For now, the best option is to:

1. Delete the current statefulset with `kubectl delete statefulset rabbitmq`
2. Re-deploy the cluster with the new `RABBITMQ_REPLICAS` value

## Building your own images:
If you want to build use your own images make sure to change the DOCKER_REPOSITORY environment variable to your own docker repository.
It will build the images, push them to your docker repository and use them to create all the needed kubernetes deployments.

## Docker Compose:
You can run the same setup in docker-compose using
```
$ docker-compose build && docker-compose up
```
Then, go to `localhost:15672` and you'll see the cluster is already formed up.

