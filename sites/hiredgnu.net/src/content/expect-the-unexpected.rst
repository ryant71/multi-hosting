Expect the Unexpected
=====================

:date: 2013-06-27 09:11
:tags: expect
:category: tech
:author: Ryan Tracey
:slug: expect-the-unexpected

.. _here: http://www.thegeekstuff.com/2010/10/expect-examples/

Problem
-------

Need to automate an rsync to a fileserver and, unfortunately, required to authenticate using a password. 

Solution
--------

Use ``expect``...

.. code-block:: bash

    #!/usr/bin/expect

    set timeout 20
    set password [lindex $argv 0]

    spawn rsync -av --no-p --no-g  /media/ryant/My\ Book/Photo/ user@10.10.10.12:/Data/Public/Photos/

    expect "user@10.10.10.12's password:"
    send "$password\n";

    interact


The above code shamelessly mangled from an example here_. 
