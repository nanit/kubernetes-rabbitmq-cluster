FROM rabbitmq:3.6.6-management-alpine

RUN apk add --update jq curl bash

ADD rabbitmq_delayed_message_exchange-0.0.1.ez /plugins
ADD rabbitmq_clusterer-1.0.3.ez  /plugins
RUN rabbitmq-plugins enable rabbitmq_delayed_message_exchange --offline
RUN rabbitmq-plugins enable rabbitmq_clusterer --offline

ENV RABBITMQ_BOOT_MODULE rabbit_clusterer
ENV RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS "-pa /plugins/rabbitmq_clusterer-1.0.3.ez/rabbitmq_clusterer-1.0.3/ebin"
ADD clusterer.config /etc/rabbitmq/

ADD set_cluster_nodes.sh /

RUN chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /etc/rabbitmq
COPY docker-entrypoint.sh /usr/local/bin/
