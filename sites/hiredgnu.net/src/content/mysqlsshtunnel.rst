MySQL Over an SSH Tunnel
========================

:date: 2013-06-11 10:15
:tags: mysql, bash, ssh
:category: tech
:author: Ryan Tracey
:slug: mysql-ssh-tunnel

The Problem-ette
----------------

I need to access a number of MySQL servers which are only accessible via
ssh jump boxes, ie. I have to ssh to Box A in order to connect to Box B
via SSH or the MySQL client.

This can get a bit tedious.


The Solution
------------

Being able to SSH directly to the MySQL was achieved by using an SSH proxy.
Setting up SSH proxying is best done by defining it in your SSH config file
-- on a Linux system: ``~/.ssh/config``. Here's how you do it.

.. code-block:: config

    Host BoxA
        Hostname X.X.X.X
        Port 2222

    Host BoxB
        Hostname Y.Y.Y.Y
        ProxyCommand=ssh -qax -o "clearAllForwardings=yes" X.X.X.X nc %h %p


Where X.X.X.X is the IP address (or hostname) of Box A and Y.Y.Y.Y is the IP address of Box B. The SSH options are:

.. code-block:: bash

     -q   Quiet mode
     -a   Disables forwarding of the authentication agent connection.
     -x   Disables X11 forwarding.
     -o   Allow one to specify options that would normally be in the ``~/ssh/config`` file.

Following X.X.X.X we see ``nc %h %p``. This is the command that is run on Box A.


Taking it Further with SSH Tunnels
----------------------------------

Now I just need to access BoxB with the MySQL client. No problem - I tunnel the MySQL connection through an SSH tunnel. The SSH Tunnel takes advantage of the
proxying so I can connect directly to MySQL on BoxB from my desktop.

I also feel the need to have my MySQL command prompt tell me to which host I have
connected. I do this by using the MYSQL_PS1 environment variable.

I put this all in a BASH script. Enjoy:

.. code-block:: bash

    #!/bin/sh

    if [ -z "$1" ]; then
        echo "Usage: $(basename $0) <remotedbhost> <mysql options>"
        exit 0
    else
        REMOTEHOST=$1
        shift
    fi
    if [ $# -eq 1 ] && [ "$1" = "-" ]; then
        TUNNELONLY=true
    else
        TUNNELONLY=false
    fi
    # select an unused port
    # (could make this more flexible)
    for port in 3307 3308 3309 3310 3311 3312 3313; do
        if netstat -lnt | grep -q ${port}; then
            continue
        else
            LOCALPORT=${port}
            break
        fi
    done

    # set up ssh tunnel
    echo "Tunneling ${LOCALPORT} -> ${REMOTEHOST}"
    ssh -f -L ${LOCALPORT}:localhost:3306 ${REMOTEHOST} -N || exit 0

    # are we launching mysql?
    if [ ${TUNNELONLY} = true ]; then
        echo "mysql client not launched"
        exit 0
    fi

    # make a nice mysql prompt
    export MYSQL_PS1="\\u@${REMOTEHOST}/\\d> "

    # if there is a host-specific conf file, use it
    if [ -f ~/.my.cnf.extra.${REMOTEHOST} ]; then
        EXTRAOPT="--defaults-extra-file=~/.my.cnf.extra.${REMOTEHOST}"
    else
        EXTRAOPT=""
    fi

    # now connect with local tunnel port with mysql
    # client using cmdline options
    mysql "${EXTRAOPT}" -P ${LOCALPORT} -h 127.0.0.1 $@

    # you are finished with mysql now, kill the tunnel
    # (maybe use $$ to get ssh tunnel pid)
    kill $(ps aux | grep "ssh -f -L ${LOCALPORT}" | grep -v grep | awk '{print $2}')


Cheers!
