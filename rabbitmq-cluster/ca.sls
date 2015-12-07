{#
    Generates the CA cert and key in /root/ca/
    To be run on a cluster member.  Once cert and key are
    generated, they should be added to the
    pillar file, and /root/ca may be safely removed from
    the system once in pillar
#}

# CN may be set here
{% set cn = 'rabbitmq_cluster' %}

/root/ca/serial:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: "01"
    - makedirs: True


/root/ca/index.txt:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: ""


/root/ca/openssl.cnf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://rabbitmq-cluster/files/openssl.cnf
    - require:
      - file: /root/ca/serial
      - file: /root/ca/index.txt


ca_keypair_gen:
  cmd.run:
    - name: "/usr/bin/openssl req -x509 -config /root/ca/openssl.cnf -newkey rsa:2048 -days 3650 -out /root/ca/cert.pem -keyout /root/ca/key.pem -outform PEM -subj /CN={{ cn }}/ -nodes"
    - require:
      - file: /root/ca/openssl.cnf

