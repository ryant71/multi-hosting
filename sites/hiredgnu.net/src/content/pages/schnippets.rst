Schnippets
==========

Systemd (user)
--------------

.. code-block:: shell

    # reload after changing .service file
    systemctl --user daemon-reload
    
    # enable scheduler ~/.config/systemd/user/borg-backup.timer
    systemctl --user enable --now borg-backup.timer
    
    # list all the timers
    systemctl --user list-timers
    
    # force the service to run regardless of the associated timer
    systemctl --user start borg-backup.service


Linux
-----
.. _moreutils: https://prefetch.net/blog/index.php/2016/11/09/getting-more-out-of-your-linux-servers-with-moreutils/

* moreutils_

Python
------

.. code-block:: python

    #
    #http://codeblog.dhananjaynene.com/2011/06/10-python-one-liners-to-impress-your-friends/
    #
    print map(lambda x: x * 2, range(1,11))

    # Sieve of Eratosthenes
    n = 50 # We want to find prime numbers between 2 and 50
    print sorted(set(range(2,n+1)).difference(set((p * f) for p in range(2,int(n**0.5) + 2) for f in range(2,(n/p)+1))))


AWS CLI
-------

.. code-block:: bash

    # output nat gw ids and their private ips sorted by ip
    # 
    $ aws2 ec2 describe-nat-gateways \
          --query 'sort_by(NatGateways, &NatGatewayAddresses[0].PrivateIp)[*].{GW:NatGatewayId,PrivateIP:NatGatewayAddresses[0].PrivateIp}' \
          --output table
    --------------------------------------------
    |            DescribeNatGateways           |
    +------------------------+-----------------+
    |           GW           |    PrivateIP    |
    +------------------------+-----------------+
    |  nat-xxxxxxxxxxx464b40 |  10.0.4.41      |
    |  nat-xxxxxxxxxxx4efa7a |  10.41.0.176    |
    ...
    ...
    |  nat-xxxxxxxxxxxf9e176 |  172.25.24.239  |
    |  nat-xxxxxxxxxxx0ce409 |  172.31.1.212   |
    +------------------------+-----------------+

    # what is the last nat gw created?
    $ aws2 ec2 describe-nat-gateways \
        --query 'sort_by(NatGateways, &CreateTime)[-1].{GW:NatGatewayId,PrivateIP:NatGatewayAddresses[0].PrivateIp,Created:CreateTime}' \
        --output table
    -----------------------------------------------------------------------
    |                         DescribeNatGateways                         |
    +----------------------------+-------------------------+--------------+
    |           Created          |           GW            |  PrivateIP   |
    +----------------------------+-------------------------+--------------+
    |  2020-08-24T13:23:05+00:00 |  nat-xxxxxxxxxxx3ac2cb  |  10.65.1.105 |
    +----------------------------+-------------------------+--------------+


Bash
----

.. code-block:: bash

    # convert to mp4
    mkdir -p mp4
    mkdir -p completed
    for file in $@; do
        extension="${file##*.}"
        filename="${file%.*}"
        avconv -i ${file} -c:v libx264 -c:a copy mp4/${filename}.mp4
        mv ${file} completed/
    done

    # fix dangling symlinks
    cd ~/bin; find . -xtype l | sed 's/\.\///' | xargs -i find /path/to/files/in/revisioncontrol -name {} | xargs -i ln -fs {} .

    # sort files by last modified date
    find . -type f -printf '%T@' -ls | sort | tail -n


LibreOffice Macro
-----------------

Associate this with key sequence to highlight a cell

.. code-block:: bash

    Sub highlight
        Dim oActiveCell
        oActiveCell = ThisComponent.CurrentSelection
        oActiveCell.CellBackColor = 16777113
    End Sub


CouchDB to Elasticsearch
------------------------


.. code-block:: logstash

   input {
     couchdb_changes {
         db => "media"
         host => "192.168.0.70"
         port => 5984
         codec => "json"
         username => "rdd"
         password => "rdd1qaz2wsx"
         initial_sequence => 0 #this is only required for the an initial indexing
         #keep_revision=>true
     }
   }
    
   output {
     elasticsearch{
         #action => "%{[@metadata][action]}"
         action =>"index"
         document_id => "%{[@metadata][_id]}"
         hosts => "192.168.0.70:9200"
         #index => "monitor-%{+YYYY.MM.dd}"
         index => "media"
         document_type => "doc"
       }
    
     if [@metadata][action] == "delete" {
       elasticsearch{
         action => "%{[@metadata][action]}"
         #action =>"index"
         document_id => "%{[@metadata][_id]}"
         hosts => "192.168.0.70:9200"
         #index => "monitor-%{+YYYY.MM.dd}"
         index => "media"
         document_type => "doc"
       }
     }
       
       #stdout {} #enable this option for debugging purpose
   }
