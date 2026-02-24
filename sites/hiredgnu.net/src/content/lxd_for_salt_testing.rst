Using LXD to Test SaltStack
===========================

:date: 2021-05-24 12:00:00
:tags: LXD, SaltStack, Python, pyenv
:category: tech
:author: Ryan Tracey
:slug: 
:summary: Using LXD to Test SaltStack

.. _Linode: https://linode.com/

.. _oh-my-zsh: https://ohmyz.sh/

.. _Pyenv: https://github.com/pyenv/pyenv

.. _SaltStack: https://docs.saltproject.io/en/getstarted/

.. _LXD: https://linuxcontainers.org/lxd/

.. _ZFS: https://itsfoss.com/what-is-zfs/

.. _Ubuntu: https://ubuntu.com/

.. _Bootstrap: https://github.com/saltstack/salt-bootstrap

.. _GitHub: https://github.com/ryant71/my-slat


What, why, and how?
-------------------

I recently setup a new company MacBook and discovered that the default
shell was ZSH, so I thought it was about time I followed the advice from
my colleagues and try out its magic. I got stuck in and proceeded to perfect
my environment. Initially with oh-my-zsh_ and then with Pyenv_. 

After doing that and discovering Nirvana I thought it would be cool to do the
same for my Linode_ instance. 

That was just a process of repeating what I'd done on the Mac and it got me
thinking about setting it up on SaltStack_ in case I ever had to do it again.

Furthermore, as I already had LXD_ installed and running on the Linode_ instance,
I thought I could test it out there. 

LXD
---

As it turned out my LXD_ implementation was... agricultural to put it charitably.
When I had first set it up I had simply used the loopback ZFS_ storage pool and
this turned out to be too small and while researching how to increase its size
I came to realise that creating the pool on a dedicated device would be a 
better approach. So, I headed over to Linode_ and created a new volume and 
attached it to my trusty Ubuntu_ 20.04 instance. 

Then I had to figure out how to make LXD_ use that device. After much searching through
the LXD_ documentation which pretty much rivals the pre-fire Library of Alexandria in
volume and complexity, it turned out to be quite easy.

Furthermore, migrating the existing LXD_ containers to the new volume turned out to
be just as easy.

Create the volume
+++++++++++++++++

Find the newly attached volume:

In the Linode_ console I had named the new volume `zfspool`, so I searched for its
local mapping per the LXD_ docs.

.. code-block:: bash

   ls -l /dev/disk/by-id/
   lrwxrwxrwx 1 root  9 May 23 13:23 scsi-0Linode_Volume_zfspool -> ../../sdc

Then came creating the "zpool". I did this using the native ZFS_ tool, however, it
turned out to be not-an-easy-thing to figure out how to "bind" it to LXD_. So, 
I eventually deleted it after much head-scratching:

.. code-block:: bash

   # cool
   sudo zpool create zfs_lxd /dev/sdc
   # erg...
   sudo zpool destroy zfs_lxd

Thereafter, I created and the new zpool using the `lxc` commmand:

.. code-block:: bash

   lxc storage create lxd_zfs_pool zfs source=/dev/sdc zfs.pool_name=zfs_pool

To confirm that I had done it properly, I checked the storage list:

.. code-block:: bash

   lxc storage list
   +--------------+--------+--------------------------------------------+-------------+---------+
   |     NAME     | DRIVER |                   SOURCE                   | DESCRIPTION | USED BY |
   +--------------+--------+--------------------------------------------+-------------+---------+
   | default      | zfs    | /var/snap/lxd/common/lxd/disks/default.img |             | 5       |
   +--------------+--------+--------------------------------------------+-------------+---------+
   | lxd_zfs_pool | zfs    | zfs_pool                                   |             | 2       |
   +--------------+--------+--------------------------------------------+-------------+---------+

Using `lxc storage list --debug` shows a lot more output which includes information on which storage pools the 
various items are kept. By default, there were two items: `images` and `profiles` (containers?)

Move the containers
+++++++++++++++++++

Then came moving the existing containers which were stored one the `loopback` pool onto the new dedicated device pool.
This involved stopping each container and then moving it to a temp container on the new pool. The `-s` switch allowed
for new storage to be specified. Thereafter, the moved container was given its old name back. The process was:

.. code-block:: bash

   lxc stop <container>
   lxc move <container> <container>-temp -s lxd_zfs_pool
   lxc move <container>-temp <container>
   lxc start <container>

My containers were already stopped so I did the migration with this one-liner:

.. code-block:: bash

   for c in nginx timescaledb ubuntu-docker; \
      do lxc move ${c} ${c}-temp -s lxd_zfs_pool && \
      lxc move ${c}-temp ${c}; \
   done


I then confirmed that the containers had been migrated:

.. code-block:: none

   lxd storage list --debug
   <lots of lines>
   [
      {
         "config": {
            "size": "5GB",
            "source": "/var/snap/lxd/common/lxd/disks/default.img",
            "zfs.pool_name": "default"
         },
         "description": "",
         "name": "default",
         "driver": "zfs",
         "used_by": [
            "/1.0/images/52c9bf12cbd3b06d591c5f56f8d9a185aca4a9a7da4d6e9f26f0ba44f68867b7"
         ],
         "status": "Created",
         "locations": [
            "none"
         ]
      },
      {
         "config": {
            "source": "zfs_pool",
            "volatile.initial_source": "/dev/sdc",
            "zfs.pool_name": "zfs_pool"
         },
         "description": "",
         "name": "lxd_zfs_pool",
         "driver": "zfs",
         "used_by": [
            "/1.0/images/52c9bf12cbd3b06d591c5f56f8d9a185aca4a9a7da4d6e9f26f0ba44f68867b7",
            "/1.0/instances/mariadb",
            "/1.0/instances/nginx",
            "/1.0/instances/timescaledb",
            "/1.0/instances/ubuntu-docker",
            "/1.0/profiles/default"
         ],
         "status": "Created",
         "locations": [
            "none"
         ]
      }
   ]


Thereafter, to ensure that further containers are created in the correct pool, I made the dedicated device the default:

.. code-block:: bash

   lxc profile device set default root pool=lxd_zfs_pool


Set Up SaltStack
----------------

With LXD_ in good order, I went ahead with the SaltStack_ setup. For the moment, one master and one minion.


The containers
++++++++++++++

.. code-block:: bash

   lxc launch ubuntu:20.04 salt-minion-test
   lxc launch ubuntu:20.04 salt-master


I used Salt Bootstrap_ to do exactly that on the Salt master and minion.

By this stage I had already worked on some very basic SaltStack_ `states` and `pillars` which you can see, on GitHub_.

From my repo on my Linode_ instance, I copied the master and minion configs to where they needed to be:

.. code-block:: bash

   lxc file push configs/master salt-master/etc/salt/
   lxc file push configs/minion salt-minion-test/etc/salt/
   lxc exec salt-minion-test systemctl restart salt-minion

I also needed to have the master accept the minion's key using `salt-key -A`. Note to self: Just turn autoaccept on - it's safe enough
to do on a closed network.


SaltStack Code
++++++++++++++

For the moment, I just want to ensure that the target minion has:

   * A user for me
   * ZSH installed
   * ZSH is the default shell for me
   * Pyenv_ is installed in my home directory

The GitHub_ repo contains the necessary to make it all work. I still have to add some documentation to the repo and, of course, continually add
further `states` and `pillars`. Furthermore, it would be cool to test out other SaltStack_ components such as `syndic` and `vault` for storing
secret data - I have already used GPG for this purpose at work, so it would be good to test something new.

I cannot go into each SaltStack_ file, but I'll go over some of them here.

In, the `configs` directory, you'll find the master and minion configs referenced above.
In pillars, there's the `general` directory which will be specific to the "general" environment referenced in the minion and master configs. The purpose
of environments in SaltStack_ is to easily separate production and development pillars from each other. This makes it easier to write the states, as one
doesn't need to include `if env=prod do this else do that` logic in the various state files.


The `pyenv` pillar file - `pyenv.sls` contains values specific to the "general" environment (or profile in anotherr sense.)

.. code-block:: yaml

   # vim: sts=2 ts=2 sw=2 et ai
   pyenv:
     enabled: True
     user: ryant
     shell: /bin/zsh
     shellrc: .zshrc
     shell_profile: .zprofile
     python:
       version: 3.9.5

It's corresponding `defaults.yaml` file in `states` is pretty much the same thing, but, potentially for another environmenti, the pillar file might differ. 

The state `defaults.yaml` can be overridden by the pillar `pyenv.sls` file using the mapping file in the state directory.  

.. code-block:: none

   # vim: sts=2 ts=2 sw=2 et ai
   {% import_yaml 'pyenv/defaults.yaml' as defaults %}

   {% set pyenv = salt['pillar.get']('pyenv', default=defaults.pyenv, merge=True) %}


The `init.sls` file, can be equated to Python's __init__.py and can be used to include other state files.

init.sls:

.. code-block:: yaml

   # vim: sts=2 ts=2 sw=2 et ai
   {% from "pyenv/map.jinja" import pyenv with context %}
   include:
   {% if pyenv.shellrc == '.zshrc' %}
     - pyenv.install_zsh
   {% endif %}
     - pyenv.install_pyenv
     - pyenv.configure_python

You'll notived that this `.sls` file (and all others) can be processed using `jinja` markup. In this case the `install_zsh.sls` file will be included
if the shellrc file defined in `defaults.yaml` and potentially overridden by `pyenv.sls` is `.zshrc`.

install_pyenv.sls:

.. code-block:: yaml

   # vim: sts=2 ts=2 sw=2 et ai
   {% from "pyenv/map.jinja" import pyenv with context %}

   dependencies:
     pkg.latest:
       - pkgs:
         - make
         - build-essential
         - libssl-dev
         - zlib1g-dev
         - libbz2-dev
         - libreadline-dev
         - libsqlite3-dev
         - wget
         - curl
         - llvm
         - libncursesw5-dev
         - xz-utils
         - tk-dev
         - libxml2-dev
         - libxmlsec1-dev
         - libffi-dev
         - liblzma-dev

   git_directory:
     file.absent:
       - name: /home/{{ pyenv.user }}/.pyenv

   clone_pyenv_repo:
     cmd.run:
       - name: git clone https://github.com/pyenv/pyenv.git /home/{{ pyenv.user }}/.pyenv
       - runas: {{ pyenv.user }}

   install_pyenv:
     cmd.run:
       - name: src/configure && make -C src
       - cwd: /home/{{ pyenv.user }}/.pyenv
       - runas: {{ pyenv.user }}

   configure_shellrc:
     file.append:
       - name: /home/{{ pyenv.user }}/{{ pyenv.shellrc }}
       - runas: {{ pyenv.user }}
       - text:
         - export PYENV_ROOT="$HOME/.pyenv"
         - export PATH="$PYENV_ROOT/bin:$PATH"
         - eval "$(pyenv init --path)"
         - eval "$(pyenv init -)"

   configure_shell_profile:
     file.append:
       - name: /home/{{ pyenv.user }}/{{ pyenv.shell_profile }}
       - runas: {{ pyenv.user }}
       - text:
         - export PYENV_ROOT="$HOME/.pyenv"
         - export PATH="$PYENV_ROOT/bin:$PATH"
         - eval "$(pyenv init --path)"

This, in combination with the other .sls files worked. No doubt there is room for improvment, but I'll make those 
as I add further states to the repo. Further candidates are my `neovim` setup, `timescaledb`, etc.

I hope this helps at least one person. ;)
