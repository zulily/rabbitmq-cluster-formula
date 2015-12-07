# Include rabbitmqadmin.sls, in the scenario where
# user management is all that is desired
include:
  - rabbitmq-cluster.rabbitmqadmin

# The rabbitmq_users present state only supports passwords, not
# password_hash -- a modified version of rabbitmqadmin is used
# instead so that we may avoid storing clear-text passwords in pillar.
# This method also allows for password_hash and tag updates when pillar
# data changes

{% for user in salt['pillar.get']('rabbitmq_cluster:users:present', []) %}
{{ user['username'] }}_rabbitmq_present:
  cmd.run:
    - name: "/usr/local/bin/rabbitmqadmin declare user name={{ user['username'] }} password_hash={{ user['password_hash'] }} tags={{ user['tags']|default('')|join(',') }}"
    - user: root

  {% set count = 0 %}
  {% for vhost_permissions in user['permissions']|default([]) %}
{{ user['username'] }}_rabbitmq_permissions_{{ count }}:
  cmd.run:
      - name: "/usr/sbin/rabbitmqctl set_permissions -p \"{{ vhost_permissions['vhost']|default('/') }}\" {{ user['username'] }} \"{{ vhost_permissions['conf']|default('^$') }}\" \"{{ vhost_permissions['write']|default('^$') }}\" \"{{ vhost_permissions['read']|default('^$') }}\""
      - user: root
      {% set count = count + 1 %}
  {% endfor %}

{% endfor %}


# Remove any users set to absent in pillar data

{% for user in salt['pillar.get']('rabbitmq_cluster:users:absent', []) %}
{{ user }}_rabbitmq_absent:
  rabbitmq_user.absent:
    - name: {{ user }}
{% endfor %}
