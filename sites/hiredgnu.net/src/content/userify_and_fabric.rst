Deploying Userify with Fabric
=============================

:date: 2015-10-09 09:29
:tags: python, fabric
:category: tech
:author: Ryan Tracey
:slug: userify_and_fabric
:summary: Deploying Userify using Fabric


Userify
-------

Userify provisions SSH keys, server users, and sudo permissions (root) to your datacenter servers, EC2, Azure, and other public and hybrid clouds.

https://userify.com/tour/

To get Userify working on all your servers, you'll need to install the Userify "daemon". To make this easier, you could automate setting up the daemon. Enter Fabric...

Fabric
------

Fabric is a Python (2.5-2.7) library and command-line tool for streamlining the use of SSH for application deployment or systems administration tasks.

http://www.fabfile.org/


Here's what you could define in your fabfile.py:


.. code-block:: python

	def deploy_userify():
	    #env.sudo_prefix = "sudo -E -S -p '%(sudo_prompt)s' " % env
	    print('env.effective_roles=%s' % env.effective_roles)
	    if env.effective_roles[0]=='some_cores':
	        group='core'
	        sudo('curl -k "https://shim.userify.com/installer.sh" | api_id="MY_API_ID1" api_key="MY_API_ID1" /bin/bash')
	    elif env.effective_roles[0]=='some_clients':
	        group='client'
	        sudo('curl -k "https://shim.userify.com/installer.sh" | api_id="MY_API_ID2" api_key="MY_API_ID2" /bin/bash')
	    elif env.effective_roles[0]=='other_apps':
	        group='other_app'
	        sudo('curl -k "https://shim.userify.com/installer.sh" | api_id="MY_API_ID3" api_key="MY_API_ID3" /bin/bash')
	    elif env.effective_roles[0]=='some_apphosts':
	        group='some_apphosts'
	        sudo('curl -k "https://shim.userify.com/installer.sh" | api_id="MY_API_ID4" api_key="MY_API_ID4" /bin/bash')
	    elif env.effective_roles[0]=='other_apphosts':
	        group='other_apphosts'
	        sudo('curl -k "https://shim.userify.com/installer.sh" | api_id="MY_API_ID5" api_key="MY_API_ID5" /bin/bash')
	    elif env.effective_roles[0]=='some_qa':
	        group='some_qa'
	        sudo('curl -k "https://shim.userify.com/installer.sh" | api_id="MY_API_ID6" api_key="MY_API_ID6" /bin/bash')
	    elif env.effective_roles[0]=='webhosts':
	        group='webhosts'
	        sudo('curl -k "https://shim.userify.com/installer.sh" | api_id="MY_API_ID7" api_key="MY_API_ID7" /bin/bash')
	    else:
	        print('Usage: fab deploy_userify -R <some_cores|some_clients|other_apps>')
	        print('   Only one role at a time.')
	        return
	    sudo('nohup /opt/userify/shim.sh >/dev/null &', pty=False)
	    print('Deployed %s to %s' % (group, env.effective_roles[0]))


Then call it with `fab deploy_userify -R <a_role>`.

This makes it easy to deploy Userify and the server group keys to the servers they need to be on.


