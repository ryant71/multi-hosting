Ansible Playbook -- Add a User
==============================

:date: 2017-07-14 14:15
:tags: ansible
:category: tech
:author: Ryan Tracey
:slug: ansible-add-user-playbook
:summary:

This playbook allows you to add a user to a remove system (or bunch of systems) and email the user about their
new account. See below it, for a shell wrapper to execute the playbook.


Ansible Playbook
----------------

.. code-block:: yaml

	---
	#
	# add user (idempotent actions)
	#
	- hosts: '{{host}}'
	  remote_user: root
	  become: yes
	  become_method: sudo
	  force_handlers: True

	  # tasks to run
	  #
	  tasks:

	    # only new users will get new passwords
	    - name: Add user
	      user:
	         name='{{username}}'
	         shell=/bin/bash
	         createhome=yes
	         comment=',,,,umask=0002'
	         append=yes
	         password='{{ "pleasechangethispassword" | password_hash("sha512")}}'
	         update_password=on_create
	      register: newuser

	    - debug:
	        var: newuser

	    # new users need to change the default password
	    - name: Set change password for new users
	      command: chage -d 0 '{{username}}'
	      register: changed
	      when: newuser.changed == True

	    - debug:
	        var: changed

	    - name: Email notification
	      mail:
	         host: localhost
	         port: 25
	         to: '{{email_address}}'
	         from: 'ryan.tracey@fo0o0.net'
	         subject: 'User created on {{host}}'
	         body: >
	             A user account ({{username}}) has been created for you on {{host}}.
	             Your password is pleasechangethispassword. SSH key will be added if possible.
	             You should use the appropriate Bastion host to reach {{host}}. You can
	             do this with SSH proxying.
	      delegate_to: localhost
	      register: mailsent
	      when: newuser.changed == True

	    - debug:
	        var: mailsent


I have a bunch of target hosts defined in a hosts.ini file. More on that later.


Bash Script Wrapper
-------------------

.. code-block:: bash

	#!/bin/bash

	function usage(){
	    echo "Usage: $0 <host> <username> <emailaddress>"
	    exit 1
	}

	DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	cd ${DIR}
	cd ..

	host=$1 || usage
	user=$2 || usage
	email=$3 || usage

	ansible-playbook playbooks/add_admin_user_single.yml \
		-e "host=${host}" \
		-e "username=${user}" \
		-e "email_address=${email}" \
		-i hosts.rt.ini

