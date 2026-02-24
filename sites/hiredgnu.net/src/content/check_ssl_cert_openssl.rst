Check an SSL Certificate with OpenSSL
=====================================

:date: 2014-02-13 12:44
:tags: ssl, bash
:category: tech
:author: Ryan Tracey
:slug: check-ssl-with-openssl
:description: SOme metadataaaa
:summary: Some summary

To check a website's SSL certificate in one easy step from the command line:

.. code-block:: bash

    echo "quit" \
        | openssl s_client -connect www.thawte.com:443 2>&1 \
        | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' \
        | openssl x509 -noout -subject -issuer -enddate

    subject= /1.3.6.1.4.1.311.60.2.1.3=US/1.3.6.1.4.1.311.60.2.1.2=Delaware/businessCategory=Private Organization/O=Thawte, Inc./serialNumber=3898261/C=US/ST=California/L=Mountain View/OU=Infrastructure Operations/CN=www.thawte.com
    issuer= /C=US/O=thawte, Inc./OU=Terms of use at https://www.thawte.com/cps (c)06/CN=thawte Extended Validation SSL CA
    notAfter=Aug 31 23:59:59 2014 GMT


Thrown into a small shell script, we get:

.. code-block:: bash

	#!/bin/bash

	[ -z "$1" ] && { echo "Usage: $0 <host> <port>"; exit; }
	[ -z "$2" ] && { echo "Usage: $0 <host> <port>"; exit; }
	host=$1
	port=$2

	echo "quit" \
	| openssl s_client -connect ${host}:${port} 2>/dev/null \
	| sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' \
	| openssl x509 -text -noout


