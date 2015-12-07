{#
   There isn't a salt state module for ssl / tls.  There is an
   execution module, but it doesn't appear to be very flexible
   with paths in some cases, so cmd.runs are used here.

   Temporarily copies the CA key in /etc/rabbitmq/ssl/ca/, and
   it is in the pillar data that gets targeted anyway.  The
   CA key is only used for a single rabbitmq cluster and not
   considered any more sensitive than a self-signed server-specific
   certificate.
#}

{% set epoch = salt['cmd.run']('date +"%s"')|string %}
{# serial number and node_number combined must be an even number of digits #}
{% if epoch|length is divisibleby 2 %}
  {% set serial_number = epoch + "0" + grains['node_number']|string %}
{% else %}
  {% set serial_number = epoch + grains['node_number'] %}
{% endif %}

/etc/rabbitmq/ssl:
  file.directory:
    - user: root
    - group: root
    - mode: 755


/etc/rabbitmq/ssl/server:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/rabbitmq/ssl


/etc/rabbitmq/ssl/ca:
  file.directory:
    - user: root
    - group: root
    - mode: 755
    - require:
      - file: /etc/rabbitmq/ssl


/etc/rabbitmq/ssl/ca/serial:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: {{ serial_number }}
    - require:
      - file: /etc/rabbitmq/ssl/ca


/etc/rabbitmq/ssl/ca/index.txt:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: ""
    - require:
      - file: /etc/rabbitmq/ssl/ca


/etc/rabbitmq/ssl/ca/cert.pem:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents_pillar: rabbitmq_cluster:rabbitmq_config:ssl:ca_cert
    - require:
      - file: /etc/rabbitmq/ssl/ca


/etc/rabbitmq/ssl/ca/key.pem:
  file.managed:
    - user: root
    - group: root
    - mode: 640
    - contents_pillar: rabbitmq_cluster:rabbitmq_config:ssl:ca_key
    - require:
      - file: /etc/rabbitmq/ssl/ca


/etc/rabbitmq/ssl/ca/openssl.cnf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://rabbitmq-cluster/files/openssl.cnf
    - require:
      - file: /etc/rabbitmq/ssl/ca


server_rsa_gen:
  cmd.run:
    - name: "/usr/bin/openssl genrsa -out /etc/rabbitmq/ssl/server/key.pem 2048"
    - require:
      - file: /etc/rabbitmq/ssl/server
      - file: /etc/rabbitmq/ssl/ca

server_rsa_permissions:
  file.managed:
    - name: /etc/rabbitmq/ssl/server/key.pem
    - user: rabbitmq
    - group: rabbitmq
    - mode: 640
    - require:
      - cmd: server_rsa_gen


server_csr_gen:
  cmd.run:
    - name: "/usr/bin/openssl req -new -key /etc/rabbitmq/ssl/server/key.pem -out /etc/rabbitmq/ssl/server/req.pem -outform PEM -subj /CN={{ grains['fqdn'] }}/O=rabbitmq_cluster/ -nodes"
    - require:
      - cmd: server_rsa_gen


ca_sign_cert:
  cmd.run:
    - name: "/usr/bin/openssl ca -config /etc/rabbitmq/ssl/ca/openssl.cnf -in /etc/rabbitmq/ssl/server/req.pem -out /etc/rabbitmq/ssl/server/cert.pem -notext -batch -extensions server_ca_extensions"
    - user: root
    - require:
      - cmd: server_csr_gen



ca_key_remove:
  file.absent:
    - name: /etc/rabbitmq/ssl/ca/key.pem
    - require:
      - cmd: ca_sign_cert
