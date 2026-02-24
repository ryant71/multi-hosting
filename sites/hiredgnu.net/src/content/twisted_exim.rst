Twisted Exim
============

:date: 2006-03-06 10:10
:tags: python, exim, twisted
:category: tech
:author: Ryan Tracey
:slug: twisted-exim

.. _Kirill: https://lists.exim.org/lurker/message/20041220.091414.43faf90b.html


Use the source, Luke
--------------------

The great thing about open source is that you can learn from those who have published code on the 'net. At the very least you can shamelessly plagiarise it and bend it until it looks like something you could use ;-)

Another great thing about OSS is the inter-operability. Where else can you get an MTA to speak to a daemon you have plagiarised/written yourself in next to no time at all, except in the OSS world.

I was once tasked to *very quickly* get something in place to monitor the rate of outgoing emails for each staff member. Won't get into the details, except to say that a director wanted to know when people were sending mails in bulk.

So you have to know when colleagues on your LAN are sending mails in bulk and you are running Exim 4 and you recall that someone posted an interesting Twisted Python example on the Exim mailing list in the not too distant past. Here's what you do.

Google
------

To find the mailing-list post that I vaguely recalled contained the interesting code, the following query did the trick:

``site:www.exim.org exim twisted rate``

The Rate Limiter
----------------

The example twisted application that the fellow Exim 4 user posted to the mailing list was intended to help in limiting the number of connections a remote mail server could make to host running Exim.

It listens on a Domain Socket and takes in the Sender IP address that Exim passes to it and stores that IP in a dictionary along with the number of times that IP has been passed to the running script. In Exim 4.20 and greater the mechanism to speak to a domain socket is:

``${readsocket{/path/to/socket.sock}{$some_variable}{timeout}{eol-string}{fail-string}}``

Before we look at the twisted code, a disclaimer: I do not know twisted-python all that well -- at all, in fact. What I do know is that Twisted takes care off daemonizing a process for you and uses the event model instead of the Parent/Child or Threading models to handle concurrency.

The code below is pretty self-explanatory even if one has not yet had that "a ha" moment with Twisted code. Basically, a process that listens on a Domain Socket "/tmp/relay.sock" is fired up. That process reads in inputs and returns an output based on the sum total of inputs with the same value that most recent input.

Here's the code written by Kirill_ Miazine:

.. code-block:: python

	import os
	import time
	 
	from twisted.internet import reactor
	from twisted.internet.protocol import Factory
	from twisted.protocols.basic import LineOnlyReceiver
	 
	stats = {}
	class RelayLimit(LineOnlyReceiver):
	    delimiter = '\n'
	    def lineReceived(self, line):
	        host = line.strip()
	        now = int(time.time())
	        global stats
	        # new or expired, reset counter and allow
	        if not stats.has_key(host) or stats[host][0] + 3600 <now:
	            stats[host] = [now, 1]
	            self.sendLine('no')
	        # limit reached, just deny
	        elif stats[host][1]> 99:
	            self.sendLine('yes')
	        # limit not reached, increment counter and allow
	        else:
	            stats[host][1] += 1
	            self.sendLine('no')
	        self.transport.loseConnection()
	 
	try:
	    os.unlink('/tmp/relay.sock')
	except OSError:
	    pass
 
	rl = Factory()
	rl.protocol =  RelayLimit
	reactor.listenUNIX('/tmp/relay.sock', rl, 10)
	 
	reactor.run()


As mentioned above I am probably not the right person to explain the Twisted type stuff so I'll limit my explanation to the lineReceived() method.

Exim, via the readsocket directive sends the listening twisted daemon an IP address -- $sender_host_address. This IP address is stored in the stats dictionary as the key, the timestamp and number of that IP's occurrences is stored in a list as the associated key-value. An example entry might be::

	stats = {
	     '100.100.100.100': [1141652394, 34]
	}

So, to get the number of times that Exim has received an email from the MTA with the IP address 100.100.100.100, you'd call:

``stats['100.100.100.100'][1]``

If an IP address has not already been added to the stats dictionary or if it has been there for more than 3600 seconds its cumulative total is set to 1:::

	if not stats.has_key(host) or stats[host][0] + 3600 < now:
	     stats[host] = [now, 1]
	     self.sendLine('no')


``self.sendLine('no')`` is the RelayLimit object sending the string 'no' back to Exim over the domain socket.

The thresholds are defined in the code itself. If any MTA makes more than 99 connections in less than 3600 seconds then a response of 'yes' is read by Exim. The Exim ACL using the readsocket function in a condition can then do something interesting like return defer (a temporary error status) to the remote MTA, or cause a 10 second delay before proceeding to the next stage of the SMTP session, etc.

[Note to self: RTFM and then explain all that rl.protocol = RelayLimit stuff ;-)]

Counting Senders
----------------

This looked like something I could use with a bit of editing. I would have Exim send then email's envelope sender -- $sender_address -- instead of the sending MTA's IP address. Of course, I would limit this lookup to emails coming from the local LAN and going to the outside world.::

	warn
	    hosts          = +my_hosts
	    condition      = ${readsocket{/tmp/sender.sock}{$sender_addressn}{5s}{}{no}}
	    log_message = tons-o-mail


The above ACL just adds a log entry for any emails that cause the readsocket condition to be true. The extended version of the twisted daemon I wrote takes care of the notifications to interested parties, etc. Here we go:

.. code-block:: python

	__doc__ = """
	Use in exim4.conf as follows:
	condition = ${readsocket{/tmp/sender.sock}{$sender_address\n}{5s}{}{no}}
	"""
	 
	import os
	import sys
	import time
	import smtplib
	import ConfigParser
	 
	from email.MIMEText import MIMEText
	from email.MIMEMultipart import MIMEMultipart
	from twisted.internet import reactor
	from twisted.internet.protocol import Factory
	from twisted.protocols.basic import LineOnlyReceiver
	 
	 
	def alert(fromAddr, toAddr, ccAddr, subject, bad_sender):
	    body = """
	    Someone has tried to send more emails through our MTA
	    than is humanly possible. The sender is
	    '"""+bad_sender+"""'
	    """+getSubjectByVolume(bad_sender)
	    msg = MIMEMultipart()
	    msg['Subject'] = subject
	    msg['From'] = fromAddr
	    msg['To'] = toAddr
	    msg['CC'] = ccAddr
	    msg.attach(MIMEText(body))
	    msg.epilogue = ''
	    s = smtplib.SMTP()
	    s.connect()
	    s.sendmail(fromAddr, toAddr, msg.as_string())
	 
	def getSubjectByVolume(addr):
	    try:
	        ret = os.popen('/usr/local/sbin/subjectbyvolume "'+addr+'"').read()
	    except:
	        ret = 'error with sender count: ' \
	            +str(sys.exc_type)+': '+str(sys.exc_value)
	    return ret
	 
	 
	pid = str(os.getpid())
	pidfile = '/var/run/exim4/twisted_sender_warn.pid'
	try:
	    os.unlink(pidfile)
	except:
	    pass
	fd = open(pidfile,'w')
	fd.write(pid)
	fd.close()
	 
	args = sys.argv[1:]
	if '-v' in args:
	    args.remove('-v')
	    verbose = 1
	else:
	    verbose = 0
	 
	try:
	    confFile = args[0]
	except:
	    confFile = '/etc/exim4/sender_warn.conf'
	 
	config = ConfigParser.ConfigParser()
	config.read(confFile)
	thresh_time  = int(config.get('thresholds', 'time'))
	thresh_count = int(config.get('thresholds', 'count'))
	fromAddr = config.get('alerts', 'fromAddr').replace("'","")
	toAddr = config.get('alerts', 'toAddr').replace("'","")
	ccAddr = config.get('alerts', 'ccAddr').replace("'","")
	subject = config.get('alerts', 'subject').replace("'","")
	 
	if verbose:
	    print 'config file: '+confFile
	    print 'threshold time: '+str(thresh_time)
	    print 'threshold_count: '+str(thresh_count)
	 
	senders = {}
	class SenderWatch(LineOnlyReceiver):
	    delimiter = '\n'
	    def lineReceived(self, line):
	        global senders
	        sender_address = line.strip()
	        if not sender_address:
	            sender_address = '<>'
	        if verbose:
	            try:
	                print sender_address+': '+str(senders[sender_address][1])
	            except KeyError:
	                print sender_address+': 0'
	        now = int(time.time())
	        # new or expired, reset counter and allow
	        if not senders.has_key(sender_address) \
	         or senders[sender_address][0] + thresh_time <now:
	            senders[sender_address] = [now, 1, 0]
	            self.sendLine('no')
	        # limit reached
	        elif senders[sender_address][1]> thresh_count:
	            self.sendLine('yes')
	            # Arf arf, woof! Good Lassy, has Johny fallen in the well again?
	            if not senders[sender_address][2]:
	                alert(fromAddr, toAddr, ccAddr, subject, sender_address)
	            senders[sender_address][2] = 1
	        # limit not reached, increment counter and allow
	        else:
	            senders[sender_address][1] += 1
	            self.sendLine('no')
	        self.transport.loseConnection()
	 
	 
	try:
	    os.unlink('/tmp/sender.sock')
	except OSError:
	    pass
	 
	sw = Factory()
	sw.protocol = SenderWatch
	reactor.listenUNIX('/tmp/sender.sock', sw, 10)
	 
	reactor.run()


I threw in some configuration options -- sender_warn.conf -- that python uses via the ConfigParser library.::

	[thresholds]
	time = 300
	count = 20

	[alerts]
	fromAddr = 'sysadmin@_____.com'
	toAddr = 'director@_____.com'
	ccAddr = 'lackey@_____.com'
	subject = 'Mail Abuse Alert'

I also call a shell script and mail its output off to the director. The aptly named subjectbyvolume. Hey, sort | uniq is a powerful thing ;-):

.. code-block:: bash

	#!/bin/sh

	# counts outgoing emails for
	 and groups by subject

	if [ $# -eq 1 ]; then
	        EXIM4LOG=/var/log/exim4/mainlog
	else
	        EXIM4LOG=$2
	fi
	SENDER=$1

	exigrep ${SENDER} ${EXIM4LOG} |
	egrep "<= ${SENDER}.*T=" |
	awk -F "T=" '{print $2}' |
	sort | uniq -c | sort -gr |
	head -n10

	exit 0


Starting and Monitoring the Daemon
----------------------------------

I also had the twisted script write its own PID to a file so I could monitor the script easily with monit. A pidfile seems to be required in the services config in most cases.

The monit snippet for watching this would have been:::

	check process twisted_sender_warn with pidfile /var/run/exim4/twisted_sender_warn.pid
	  start program = "/etc/init.d/tsw start"
	  stop program = "/etc/init.d/tsw stop"
	  if failed unixsocket /tmp/sender.sock then restart
	  if 5 restarts within 5 cycles then timeout
	  alert {somecell#}@alerts.vine.co.za
	  alert bob@______.com


The startup script for this service looked like this:

.. code-block:: bash

	#!/bin/sh

	DAEMON=/usr/local/sbin/twisted_sender_warn
	PIDFILE=/var/run/exim4/twisted_sender_warn.pid
	OPTIONS=""

	stop()
	{
	 start-stop-daemon --stop --quiet --pidfile ${PIDFILE} --retry TERM/10 --oknodo --exec $DAEMON
	 killall twisted_sender_warn
	 rm ${PIDFILE}
	}

	start()
	{
	 start-stop-daemon --start --pidfile ${PIDFILE} --chuid Debian-exim --exec ${DAEMON} -- ${OPTIONS} &
	}

	restart()
	{
	 stop
	 start
	}

	case "$1" in
	    start)
	      start
	      ;;
	    stop)
	      stop
	      ;;
	    *)
	      echo "Usage: $0 (start|stop|restart)"
	      exit 1
	      ;;
	esac

	exit 0


Hey, it worked for me on a Debian Sarge box with Exim 4.44 (I think), Python 2.3, and other standard Debian packages. There are probably a thousand ways I could have accomplished the same thing. That is Open Source for you. The choices, the choices!

Thanks Kirill! You made my day.
