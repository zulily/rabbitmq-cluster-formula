{% from "rabbitmq-cluster/map.jinja" import rabbitmq with context %}

{{ rabbitmq.rabbitmq_env_conf_file }}:
  file.managed:
    - source: salt://rabbitmq-cluster/files/rabbitmq-env.conf
    - template: jinja
    - user: rabbitmq
    - group: rabbitmq
    - mode: 644
    - makedirs: True
    - context:
      environment_variables: {{ salt['pillar.get']('rabbitmq_cluster:environment_variables', []) }}
