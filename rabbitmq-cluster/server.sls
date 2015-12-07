{% from "rabbitmq-cluster/map.jinja" import rabbitmq with context %}

{% set is_initial_install = salt['cmd.run']('/usr/bin/test -e /etc/init.d/rabbitmq-server || echo True')|default('False') %}


{{ rabbitmq.package }}:
  pkg.installed:
    - hold: True
    - service:
      - name: {{ rabbitmq.service }}
      - enable: True

{#
   If this is the initial install, stop rabbit, subsequent steps such
   as enabling of plugins require a restart.
#}
{% if is_initial_install == 'True' %}
rabbit_stew:
  service.dead:
    - name: {{ rabbitmq.service }}
    - require:
      - pkg: {{ rabbitmq.package }}

{{ rabbitmq.erlang_cookie }}_absent:
  file.absent:
    - name: {{ rabbitmq.erlang_cookie }}
    - require:
      - service: rabbit_stew


{% endif %}
