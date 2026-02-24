Discovering the Seagate Central
===============================

:date: 2013-06-29 13:39
:tags: nmap
:category: tech
:author: Ryan Tracey
:slug: discovering-seagate-central


NMAP Scan
---------

::

	ryant@spitfire:~$ nmap 192.168.1.11

	Starting Nmap 6.00 ( http://nmap.org ) at 2013-06-29 13:17 SAST
	Nmap scan report for 192.168.1.11
	Host is up (0.0098s latency).
	Not shown: 990 closed ports
	PORT     STATE SERVICE
	21/tcp   open  ftp
	22/tcp   open  ssh
	80/tcp   open  http
	139/tcp  open  netbios-ssn
	443/tcp  open  https
	445/tcp  open  microsoft-ds
	548/tcp  open  afp
	631/tcp  open  ipp
	3689/tcp open  rendezvous
	9000/tcp open  cslistener

	Nmap done: 1 IP address (1 host up) scanned in 1.89 seconds

