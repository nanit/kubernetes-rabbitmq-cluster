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
2. A rmq-cluster headless service to control the StatefulSet domain
3. a rabbitmq service to access the cluster
4. An optional, rabbitmq-management service to access the admin control panel

## Environment Variables:
| Name                         | Default Value | Purpose                                                                  | Can be changed? |
|------------------------------|---------------|--------------------------------------------------------------------------|-----------------|
| DOCKER_REPOSITORY            | nanit         | Change it if you want to build and use custom docker repository          | Yes             |
| SUDO                         | sudo          | Should docker commands be prefixed with sudo. Change to "" to omit sudo. | Yes             |
| RABBITMQ_REPLICAS            | 3             | Number of nodes in the cluster                                           | No              |
| RABBITMQ_DEFAULT_USER        | None          | The default username to access the management console                    | Yes             |
| RABBITMQ_DEFAULT_PASS        | None          | The default password to access the management console                    | Yes             |
| RABBITMQ_ERLANG_COOKIE       | None          | Erlang secret needed for nodes communication                             | Yes             |
| RABBITMQ_EXPOSE_MANAGEMENT   | FALSE         | Should RMQ management console be exposed outside                         | Yes             |

## Deployment:

1. Clone this repository
2. Run:

```
export DOCKER_REPOSITORY=nanit && \
export RABBITMQ_REPLICAS=3 && \
export RABBITMQ_DEFAULT_USER=username && \
export RABBITMQ_DEFAULT_PASS=password && \
export RABBITMQ_ERLANG_COOKIE=secret && \
export RABBITMQ_EXPOSE_MANAGEMENT=TRUE && \
export SUDO="" && \
make deploy
```

## Usage:

At the end of the installation you should have a rabbitmq service which you can use to connect to the cluster

## Changing the number of nodes:

If you'd like to have more than 3 nodes in the cluster you have to:

1. Change the [clusterer.config](https://github.com/nanit/kubernetes-rabbitmq-cluster/blob/master/docker/clusterer.config) to include all the cluster nodes.
2. Build your own image by setting the `DOCKER_RESPOSITORY` environment variable
3. Change the `RABBITMQ_REPLICAS` to the new number of nodes
4. Run the deployment script above

## Building your own images:
If you want to build use your own images make sure to change the DOCKER_REPOSITORY environment variable to your own docker repository.
It will build the images, push them to your docker repository and use them to create all the needed kubernetes deployments.

## Docker Compose:
You can run the same setup in docker-compose using
```
$ docker-compose build && docker-compose up
```
Then, go to `localhost:15672` and you'll see the cluster is already formed up.

## Future work:
1. Allow setting a different number of replicas

