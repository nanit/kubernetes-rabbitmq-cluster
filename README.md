# kubernetes-rabbitmq-cluster

A ready to deploy rabbitmq cluster to work on top of Kubernetes.

## Requirements:
1. Kubernetes version 1.5.X (We're using StatefulSet)
2. kubectl configured to work with your Kubernetes API
3. Tested on Kubernetes 1.5.2 on top of AWS (See future work)
4. Optional - Access to your own docker repository to store your own images. That's relevant if you don't want to use the default images offered here.

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


## Building your own images
If you want to build use your own images make sure to change the DOCKER_REPOSITORY environment variable to your own docker repository.
It will build the images, push them to your docker repository and use them to create all the needed kubernetes deployments.

# Docker Compose
You can run the same setup in docker-compose using
```
$ docker-compose build && docker-compose up
```
Then, go to `localhost:15672` and you'll see the cluster is already formed up.

## Future work
1. Allow setting a different number of replicas

