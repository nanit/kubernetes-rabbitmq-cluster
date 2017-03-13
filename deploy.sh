#!/bin/bash

RABBITMQ_REPLICAS=3 && \
  RABBITMQ_USER=aaa && \
  RABBITMQ_PASSWORD=bbb && \
  RABBITMQ_ERLANG_COOKIE="secret" && \
  SUDO="" && \
  make deploy
