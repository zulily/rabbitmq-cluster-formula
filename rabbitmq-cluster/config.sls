{% from "rabbitmq-cluster/map.jinja" import rabbitmq with context %}


{{ rabbitmq.conf_file }}:
  file.managed:
    - template: jinja
    - source: salt://rabbitmq-cluster/files/rabbitmq.config
    - context:
      ssl_enabled: {{ salt['pillar.get']('rabbitmq_cluster:rabbitmq_config:ssl:enabled', True) }}
      ssl_port: {{ salt['pillar.get']('rabbitmq_cluster:rabbitmq_config:ssl:port', 5671) }}
    - user: rabbitmq
    - group: rabbitmq
    - mode: 644
