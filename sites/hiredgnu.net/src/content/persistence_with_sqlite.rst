Persistence With SQLite
=======================

:date: 2013-06-15 12:07
:tags: sqlite, python, sqlalchemy
:category: tech
:author: Ryan Tracey
:slug: persistence-with-sqlite

The Problem-ette
----------------

I needed to keep track of up until where in a database table I had already 
queried. Later queries needed to draw data from that point onwards. For example
if I've done the query ``select id, name, surname from table where id > 255623`` 
and it yielded results with an maximum id (assuming id is an auto_increment field)
of ``343522`` then the next query would need to be ``select id, name, surname from table where id > 343522``. I needed, therefore, to keep track of that maximum ``id``.

The Solution
------------

Because I didn't want to touch the production MySQL database I decided to store 
the persisted script data (the maximum id) in a SQLite3 databases.

I could also have decided to persist this data using Python Pickles or any number
of other method. I chose SQLite because it would be easily accessible via the 
``sqlite3`` client utility.

The following snippets went into the scripts I created. 


Set Up the SQLite Table
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

	# for speed we persist last audit_trail.id in a sqlite3 db
	# - not using 'id' as an absolute guide instead of end_date
	# - just to make the sql faster
	persistdb_engine = sa.create_engine('sqlite:////opt/monitoring/graphite_persist.db')
	persistdb_conn = persistdb_engine.connect()
	persist_table = sa.Table('persist', metadata,
	    Column('scriptname', String(100), primary_key = True),
	    Column('index_table', String(100), nullable = False),
	    Column('index_column', String(100), nullable = False),
	    Column('index_value', Integer, nullable = False))
	
	# create sqlite table if not exists
	persist_table.create(persistdb_engine, checkfirst=True)


Query the SQLite Table
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

	scriptname = sys.argv[0].split('/')[-1]
	index_table = 'audit_trail'
	index_column = 'id'
	
	# using sqlalchemy expression language
	# see: http://docs.sqlalchemy.org/en/rel_0_8/core/tutorial.html
	s = select([persist_table]).where(persist_table.c.scriptname == scriptname)
	ret = persistdb_conn.execute(s).fetchone()
	if not ret:
	    index_value = 0
	    ins = persist_table.insert().values(scriptname = scriptname,
	                                        index_table = index_table,
	                                        index_column = index_column,
	                                        index_value = index_value)
	    ret = persistdb_conn.execute(ins)
	else:
	    index_value = int(ret['index_value'])
	

Update the SQLite Table with New Max(id)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: python

	# now update persist table
	s = persist_table.update()\
	        .where(persist_table.c.scriptname==scriptname)\
	        .where(persist_table.c.index_table==index_table)\
	        .values(index_value=min_id)
	ret = persistdb_conn.execute(s)


Worked for me.
