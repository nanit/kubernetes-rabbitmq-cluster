FROM rabbitmq:3.6.6-management-alpine

ADD rabbitmq_delayed_message_exchange-0.0.1.ez /plugins
ADD rabbitmq_clusterer-1.0.3.ez  /plugins
RUN rabbitmq-plugins enable rabbitmq_delayed_message_exchange
RUN rabbitmq-plugins enable rabbitmq_clusterer --offline

ENV RABBITMQ_BOOT_MODULE rabbit_clusterer
ENV RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS "-pa /plugins/rabbitmq_clusterer-1.0.3.ez/rabbitmq_clusterer-1.0.3/ebin"

ADD rabbitmq.config /etc/rabbitmq/
RUN chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /etc/rabbitmq
