20 Lines of Python
==================

:date: 2014-01-07 17:48
:tags: python, sqlalchemy, requests
:category: tech
:author: Ryan Tracey
:slug: 20-lines-of-python

Querying a Database and POSTing data in 20 lines
------------------------------------------------

I love Python and its many libraries. The HTTP library by the name
of `requests` is particularly awesome.

Note: I have not used any authentication, basic or otherwise, but
it's easy enough to add.

StringIO is used because the `cvs` library expects to write data to
a file and I don't want to write any files. `StringIO`, as I
understand it, fakes a file so the data is written to a file
object in memory. Sort of.

.. code-block:: python

	#!/usr/bin/env python

	import csv
	import StringIO
	import requests
	import sqlalchemy as sa

	sql = "select foo, bar, baz from table where something='blecch'"
	posturl = 'https://some.url.com/stuff'
	headers = {'content-type': 'application/csv'}
	dburi = 'mysql://username:password@localhost:3307/db'

	engine = sa.create_engine(dburi)
	ret = engine.execute(sql)

	# create csv data in psuedo file
	outstring = StringIO.StringIO()
	writer = csv.writer(outstring, quoting=csv.QUOTE_NONNUMERIC)
	writer.writerows(ret)

	# POST the data
	r = requests.post(posturl, data=outstring.getvalue(), headers=headers)

	print(r.status_code)
	print(r.reason)
	print(r.text)

