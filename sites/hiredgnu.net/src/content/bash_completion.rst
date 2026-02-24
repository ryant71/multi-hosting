Commandline Completion for Fabric
=================================

:date:     2013-06-13 13:58
:tags:     bash, fabric
:category: tech
:author:   Ryan Tracey
:slug:     bash-completion-fabric

To get a list of functions in a Fabric_ file you use ``fab --list``. I use Fabric frequently so I 
thought I'd save myself some time by using bash completion to render ``fab --list`` obsolete. 

Being a learn-from-example type of person I immediately consulted Google for some precedence_. After a 
bit of poking I ended up putting the following in ``/etc/bash_completion.d/fab``.

.. code-block:: bash

	_fab(){
	    COMPREPLY=()
	    local word="${COMP_WORDS[COMP_CWORD]}"
	    local completions="$(fab --list | egrep -v '(^Avail|^$)' | sed 's/^[ ]*//')"
	    COMPREPLY=( $(compgen -W "$completions" "$word") )
	}

    complete -F _fab fab

Now, I type ``fab`` hit ``tab`` twice and a list of Fabric functions appears and is completed, as if by magic, as I type.

I'll add to this document when my understanding of the COMP* functions and data structures improves... 


.. _Fabric: http://docs.fabfile.org/en/1.6/index.html
.. _precedence: http://blog.jcoglan.com/2013/02/12/tab-completion-for-your-command-line-apps/
