#/bin/bash

set -e
set -u

function join_by { local IFS="$1"; shift; echo "$*"; }

STATEFUL_SETS=$(curl -f -k https://${KUBERNETES_SERVICE_HOST}/apis/apps/v1/statefulsets -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)")
RMQ_SS=$(echo $STATEFUL_SETS | jq ".items[] | select(.metadata.name == \"${RABBITMQ_APP_NAME}\")")
REPLICAS=$(echo $RMQ_SS | jq .spec.replicas)
SERVICE_NAME=$(echo $RMQ_SS | jq .spec.serviceName | tr -d '"')
(( REPLICAS-= 1 ))
NODES=()
RABBITMQ_HOSTNAME=${POD_NAME}.${SERVICE_NAME}

until host ${RABBITMQ_HOSTNAME}
do
  echo "Waiting for ${RABBITMQ_HOSTNAME} to be resolved"
  sleep 5
done
echo ${RABBITMQ_HOSTNAME} resolved!

for i in $(seq 0 $REPLICAS)
do
  NODES+=("{'rabbit@${RABBITMQ_APP_NAME}-$i.${SERVICE_NAME}', disc}")
done

JOINED=$(join_by , "${NODES[@]}")

sed -i "s/@@RABBITMQ_NODES@@/$JOINED/g" /etc/rabbitmq/clusterer.config
sed -i "s/@@RABBITMQ_GOSPEL_NODE@@/'rabbit@${RABBITMQ_APP_NAME}-0.$SERVICE_NAME'/g" /etc/rabbitmq/clusterer.config
