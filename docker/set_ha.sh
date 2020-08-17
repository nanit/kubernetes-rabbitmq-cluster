#!/bin/bash -ex
while true ; do 
  sleep 20
  echo "Waiting for RabbitMQ be ready...."
  rabbitmqctl status
  ready=$?
  if [ ${ready} == 0 ]; then
    echo "RabbitMQ is ready, setting ha policy"
    sleep 5
    rabbitmqctl set_policy ha-all '.*' '{{RABBITMQ_HA_POLICY}}' --apply-to queues || break
    rabbitmqctl set_policy expiry '.*' '{"expires":1800000}' --apply-to queues || break
    rabbitmqctl set_policy max-length '.*' '{"max-length":200000, "overflow":"drop-head"}' --apply-to queues || break
    echo "all policies were set successfully"
    break
  fi
  echo "RabbitMQ still not ready..."
  sleep 5
done

