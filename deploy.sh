#!/bin/bash

export RABBITMQ_REPLICAS=3 && \
  export RABBITMQ_USER=user && \
  export RABBITMQ_PASSWORD=password && \
  export RABBITMQ_ERLANG_COOKIE="secret" && \
  export SUDO="" && \
  make deploy
