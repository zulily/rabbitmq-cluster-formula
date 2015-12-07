{% from "rabbitmq-cluster/map.jinja" import rabbitmq with context %}
{% set is_initial_install = salt['cmd.run']('/usr/bin/test -e ' + rabbitmq.erlang_cookie + ' || echo True')|default('False') %}

{#
   Only join the cluster, write out the erlang cookie and start the service
   when it is determined this is a fresh install
#}
{% if is_initial_install == "True" %}

{#
   The erlang cookie comes from pillar data and must the identical
   for all cluster members

#}
{{ rabbitmq.erlang_cookie }}:
  file.managed:
    - makedirs: True
    - mode: 400
    - user: rabbitmq
    - group: rabbitmq
    - contents_pillar: rabbitmq_cluster:erlang_cookie

{{ rabbitmq.service }}_cluster:
  service.running:
    - name: {{ rabbitmq.service }}
    - enable: True
    - require:
      - file: {{ rabbitmq.erlang_cookie }}

  {% set cluster_join_host = salt['pillar.get']('rabbitmq_cluster:cluster_join_host', 'cluster_join_host_not_set_in_pillar') %}
  {# No need to join oneself... #}
  {% if cluster_join_host != grains['host'] %}
rabbit@{{ cluster_join_host }}:
  rabbitmq_cluster.join: {# Need to switch this to .joined in salt versions >= 2014.7.0, .join is deprecated #}
    - user: rabbit
    - host: {{ cluster_join_host }}
    - require:
      - service: {{ rabbitmq.service }}_cluster
  {% endif %}

{% endif %}
