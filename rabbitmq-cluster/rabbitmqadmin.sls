# Until something better exists in salt states, use modified rabbitmqadmin as hack to allow for password hashes to be
# stored in pillar, as opposed to cleartext passwords.  Resets the maintenance account
# password with each subsequent run

{% set maintenance_password = salt['cmd.run']('/usr/bin/openssl rand -hex 32')|default('openssl_not_found_pw') %}

# Install a slightly modified version of the rabbitmqadmin script that uses
# password_hash, not password
/usr/local/bin/rabbitmqadmin:
  file.managed:
    - source: salt://rabbitmq-cluster/files/rabbitmqadmin
    - user: root
    - group: root
    - mode: 755


# Configuration for rabbitmqadmin, used by the root account
/root/.rabbitmqadmin.conf:
  file.managed:
    - source: salt://rabbitmq-cluster/files/rabbitmqadmin.conf
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    - context:
      maintenance_password: "{{ maintenance_password }}"


{# Create the maintenance account, or reset the password/tag #}
rabbitmq_maintenance_account:
  rabbitmq_user.present:
    - name: maintenance
    - password: "{{ maintenance_password }}"
    - tags: administrator
# force doesn't seem to work for rabbitmq_user.present, so support password changes
rabbitmq_maintenance_password_update:
  cmd.run:
    - name: "rabbitmqctl change_password maintenance {{ maintenance_password }}"
  require:
    - rabbitmq_user: rabbitmq_maintenance_account


# This option doesn't work as of now as there is a bug with using force: True
