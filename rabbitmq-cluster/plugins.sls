{% from "rabbitmq-cluster/map.jinja" import rabbitmq with context %}

{#
   Maintain plugins with each run of this state file, but only stop rabbitmq if
   this is an initial install, determined by the presence of /etc/rabbitmq/enabled_plugins,
   which is not necessarily 100% accurate

#}

{% set is_initial_install = salt['cmd.run']('/usr/bin/test -e /etc/rabbitmq/enabled_plugins || echo True')|default('False') %}

{# rabbitmq must be running for the saltstack plugin management to work #}
{{ rabbitmq.package }}_plugins:
  service.running:
    - name: {{ rabbitmq.package }}


{% for plugin in salt['pillar.get']('rabbitmq_cluster:plugins:enabled', []) %}
{{ plugin }}_enabled:
    rabbitmq_plugin.enabled:
      - name: {{ plugin }}
      - require_in:
        - cmd: do_nothing_plugins
{% endfor %}

{% for plugin in salt['pillar.get']('rabbitmq_cluster:plugins:disabled', []) %}
{{ plugin }}_disabled:
    rabbitmq_plugin.disabled:
      - name: {{ plugin }}
      - require_in:
        - cmd: do_nothing_plugins
{% endfor %}

do_nothing_plugins:
  cmd.run:
    - name: ":"
    - require:
      - service: {{ rabbitmq.package }}_plugins


{#
   If this is the initial install, stop rabbit, it will be restarted later
   in the process after additional steps such as config file generation
   have completed
#}
{% if is_initial_install == 'True' %}
rabbit_stew_plugins:
  service.dead:
    - name: {{ rabbitmq.service }}
    - require:
      - cmd: do_nothing_plugins
{% endif %}
