================
rabbitmq-cluster
================

The rabbitmq_cluster formula and pillar data may be used to bring up a new, highly available rabbitmq cluster with simplified user account management in minutes.  It does not manage balancing, queues, exchanges, bindings, nor federation -- the burden of this is left on clients.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``rabbitmq-cluster``
--------------------
The main entry point, including all of the necessary state files to get a new rabbitmq cluster built, assuming pillar data has first been created.  With the exception of user account management states which may be run as frequently as necessary, init.sls is generally the only state file that needs to be run, calls to individual state files should not be necessary.


``ca``
------
A state file that creates a CA cert and key to be included in pillar data.  This should only be run once on a single cluster node.

``config``
----------
Manages the rabbitmq.config file, which is generated from a template and pillar data.  Contains only the most basic settings and settings to enable an SSL listener and SSL for the admin interface.

``server``
----------
Installs rabbitmq-server.  For an initial install, kills rabbitmq as subsequently run states require a restart.

``cluster``
-----------
Creates the erlang cookie, starts the service and joins the cluster by connecting to cluster_join_host, defined in pillar.  If the current node is the cluster_join_host, no cluster joining is attempted.  Note that all cluster members are joined as disc nodes.

``environment``
---------------
Creates /etc/rabbitmq/rabbitmq-env.conf and places environment variables in this file.  Variables are defined in pillar data.

``plugins``
-----------
Enables and disables rabbitmq plugins such as rabbitmq_management, based on settings in pillar.

``policies``
------------
Policy settings, currently only related to setting all queues to ha-mode all.

``rabbitmqadmin``
-----------------
Installs a customized version of rabbitmqadmin, which is able to maintain user accounts with password hashes (as opposed to cleartext passwords).  Also creates a maintenance account and sets a password for this account, specified in the /root/.rabbitmqadmin.conf file.

``ssl``
-------
Populates /etc/rabbitmq/ssl/, including a server key, the CA cert and a CA-signed certificate for the server.  As CA certificate signing is distributed, the CA key and certificate reside in pillar, and the CA key is temporarily copied to minions whenever a new minion cert and key are generated.  Of note otherwise is that some serial number hackery is present in this state file, to attempt to have unique, always incrementing serial numbers, each time a new node is added.

``users``
---------
Utilizing the forked version of rabbitmqadmin (a python script), adds and removes users and sets permissions as defined in pillar data.


Features
========
+ A pair of state files have been developed to manage user settings including tags (authorization levels), password hashes,
  vhosts and read/write permissions, which all reside within pillar.  A script called rabbit_hash has been developed
  to assist in generating password hashes, it is bundled with this formula.
+ SSL ( more specifically, TLS 1.1 and 1.2) is supported for client-server communications.  It is possible to enable
  encrypted inter-node communication, but this formula does not yet support that functionality.  See docs/tls.txt
  for a tutorial on setting up inter-node encrypted communication.
+ States for generating a CA key and cert are included
+ The HA policy is automatically put in place for all queues
+ Plugins may be enabled or disabled with lists in pillar
+ Environment variables (rabbitmq-env.conf) may be set in pillar
+ Joins a cluster automatically at install time
+ Installs rabbitmq-server
+ Will not restart rabbitmq in subsequent, post-install salt formula runs


Getting Started
===============

+ Bring up any instances that will be part of the cluster, with base installs.
+ Give each cluster member a unique node number and set a grain, for example:

::

  root@rabbit1:/# salt-call grains.setval node_number 1
  root@rabbit2:/# salt-call grains.setval node_number 2

+ Create a CA certificate and key for the cluster and place this in the pillar data

::

  root@ca-server1:/# salt-call state.sls rabbitmq-cluster.ca

.. note::

  The certificate and key will be placed in /root/ca/.  Clients will have to trust this new
  signing authority.

+ Also update the pillar data by adding an erlang cookie and any users and password hashes.  To generate a
  password hash, use bin/rabbit_hash, a python script.

+ Build the first cluster member, which should be set in the pillar data for "cluster_join_host"

::

  root@rabbit1:/# salt-call state.highstate

+ Build additional cluster members, e.g.:

::

  root@rabbit2:/# salt-call state.highstate

+ That should be it! Verifiable with rabbitmqctl:

::

  root@rabbit2:/# rabbitmqctl cluster_status
  Cluster status of node rabbit@rabbit2 ...
  [{nodes,[{disc,[rabbit@rabbit1,rabbit@rabbit2]}]},
   {running_nodes,[rabbit@rabbit1,rabbit@rabbit2]},
   {cluster_name,<<"rabbit@rabbit2.example.com">>},
   {partitions,[]}]

ToDo / Known Issues
===================
+ Add support for non-Debian-based distributions


License
=======

Apache License, version 2.0.  Please see LICENSE
