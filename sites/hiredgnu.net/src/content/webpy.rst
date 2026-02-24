Keeping IT Simple With Web.py
=============================

:date: 2007-10-01 11:33
:tags: web.py, python
:category: tech
:author: Ryan Tracey
:slug: simply-webpy 

.. _webpy: http://webpy.org/

The web framework shootout
--------------------------

There are many Python based web frameworks out there waiting to be discovered, tested, set aside, and even used for something useful. Some argue that there are too many and that what Python needs is a Rails-style killer app. One app to rule them all… Like that’s ever going to happen. From where I sit, I see at least three web frameworks vying for the Python killer-app title: Django, TurboGears, and Pylons. Each of these frameworks brings something unique and uniquely Python to the table. I have tried each of these with varying degrees of thoroughness, persistence, and success. Each have their strong and weak points, pros and cons. I don’t feel that I could honestly compare them with each other except to say that I found it easiest to get my head around Pylons. Maybe because I tried that one last? That being said, on to web.py.

The anti-framework framework
----------------------------

Web.py was released at the beginning of 2006 and gained some small level of notoriety because it was the framework used when the Reddit developers ditched LISP and rewrote reddit.com in Python. Web.py’s creator (Aaron Swartz) was one of the Reddit developers.

Originally web.py was exactly that. Just web.py — one library that incorporated a lot of tools that made developing web pages easier. at the beginning it comprised of Cheetah for templating, some custom functions for dealing with MySQL and PostgreSQL.

Today web.py incorporates a lot more goodness and instead of having one doting parent it has a number of dedicated programmers committed to its development. It now uses by default a custom designed templating language (Templator) yet retains support for Cheetah and promises support for many other templating schemes. For example, when I asked the web.py mailing list about support for Mako someone suggested something like this:

.. code-block:: python

	from mako.lookup import TemplateLookup

	class mako_render:
	    def __init__(self, path):
	        self._lookup = TemplateLookup(directories=[path],
	                module_directory=’mako_modules’)
	    def __getattr__(self, name):
	        path = name + ‘.html’
	        t = self._lookup.get_template(path)
	        #t.__call__ = t.render
	        return t.render

	render = mako_render(’templates/’)

Which I could use in the normal web.py GET or POST methods:

.. code-block:: python

	class hello:
	    def GET(self, name):
	        i = web.input(times=1)
	        if not name:
	            name = ‘world’
	        web.header(”Content-Type”, “text/html; charset=utf-8″)
	        print render.hello(name=name, times=int(i.times))

Note the print render.hello(…). This loads up the hello.html template file in the templates/ directory and processes it as a Mako template. Here’s that file:

.. code-block:: python

	<ol>
	   % for n in range(times):
	       <li> ${n} ${name} </li>
	   % endfor
	</ol>

Anyway, that’s a brief introduction to web.py. I hope to write more about it in the coming months, especially with regards to how one serves web.py apps with Apache, Lighttpd, and Nginx.

Links
-----

* `<http://webpy.org>`_
* `<http://jottit.com/>`_
* `FastCGI, SCGI, and Apache: Background and Future <http://reddit.com/goto?id=yo3>`_
* `FastCGI — The Forgotten Treasure <http://cryp.to/publications/fastcgi/>`_
* `FastCGI becoming the new leader in server technologies? <http://programming.reddit.com/goto?id=sh13>`_