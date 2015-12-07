include:
  - rabbitmq-cluster.server
  - rabbitmq-cluster.config
  - rabbitmq-cluster.ssl
  - rabbitmq-cluster.plugins
  - rabbitmq-cluster.environment
  - rabbitmq-cluster.cluster
  - rabbitmq-cluster.policies
  - rabbitmq-cluster.rabbitmqadmin
{#-
    Only run user management code on cluster_join_host when building,
    accounts are replicated when a new node joins the cluster.
    Note that the host grain is used, so the pillar data should
    reference the short hostname, not the fqdn
-#}
{%- if salt['pillar.get']('rabbitmq_cluster:cluster_join_host', None) == grains['host'] %}
  - rabbitmq-cluster.users
{% endif -%}
