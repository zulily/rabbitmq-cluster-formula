# All queues are HA by default
rabbit_policy_ha_all:
  rabbitmq_policy.present:
    - name: ha_all
    - pattern: '.*'
    - definition: '{"ha-mode": "all"}'
