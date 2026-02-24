SQL Converter
=============

:date: 2007-05-18 10:42
:tags: python, sqlalchemy
:category: tech
:author: Ryan Tracey
:slug: sqlconverter 


The Problem
-----------

I had a text file containg MS SQL Server database table definitions and I needed to make it compatible with MySQL. Here’s an example:

.. code-block:: sql

	GO
	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Blecchs]') AND type in (N'U'))
	BEGIN
	CREATE TABLE [dbo].[Blecchs](
	    [BlecchId] [int] IDENTITY(1,1) NOT NULL,
	    [BlecchProvider] [varchar](50) NULL,
	    [BlecchBrand] [varchar](50) NULL,
	    [BlecchCode] [varchar](50) NULL,
	    [BlecchGroup] [varchar](50) NULL,
	    [Description] [varchar](200) NULL,
	    [BlecchType] [varchar](2) NULL,
	    [Affected] [bit] NULL,
	 CONSTRAINT [PK_Blecchs] PRIMARY KEY NONCLUSTERED
	(
	    [BlecchId] ASC
	)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
	) ON [PRIMARY]
	END

The Solution
------------

Python! You guessed it. At the time, had I had access to the Internet and Google, I probably would have looked for an already written script to do this for me. But, since I didn’t, I fired up ipython and started writing something which could strip out all the MS SQL Server gumpf.

For better or worse I have, at least in my head, a few recipes for text processing which I have relied upon for past problem solving. In Python, it basically works thusly:

Open File
Read file line by line
Do stuff for each line

Here’s an example:::

	In [1]: f = file('.bashrc')

	In [2]: f
	Out[2]: 

	In [3]: for line in f:
	   …:         if line.find(’alias’)>=0:
	   …:                 print line
	   …:
	   …:
	alias nautilus=’nautilus –no-desktop’
	alias dusage=’du -sh `du -s * | sort -g | cut -f2`’
	alias dit=’di -x tmpfs -h’

Quick and easy grep in python.

I did a similar thing to process the SQL Server file, except with more detailed processing in the for loop. The process worked kinda like this:

Open the file
Read file line for line
* If line starts with CREATE, then create a new create string
* If line contains CONSTRAINT, set the con variable to True (IOW, start ignoring the lines which follow)
* If con is True and the line starts with a ‘)’, then set con to False and stop ignoring lines
* If lines starts with ‘)’, then append ‘);\n’ to the create string
* If flip is True then perform some string replacements and append the line to the create string

Finished!

Here’s the code:

.. code-block:: python

	#!/usr/bin/python

	# import modules
	#
	import re
	from sys import argv, exit

	# parse cmdline for filename and open it
	#
	try:
	    sqlf = argv[1]
	    f = file(sqlf,'r')
	except IndexError:
	    print 'Usage: %s ‘ % (argv[0],)
	    exit()
	except IOError:
	    print ‘Could not open %s’ % (sqlf,)
	    exit()

	# regex for finding tablename in “CREATE TABLE [dbo].[TableName](”
	#
	re_TABLE = re.compile(r’w+sw+s[dbo].[([w$_-]*)](’)

	# set some variables
	#
	flip = False
	con = False

	# start processing file line for line
	#
	for l in f:
	    if l.startswith(’CREATE’):
	        # start a new ‘create’ string
	        flip = True
	        m = re_TABLE.match(l)
	        try:
	            table = m.group(1)
	        except AttributeError:
	            print l
	            exit()
	        create = ‘DROP TABLE IF EXISTS %s;n’ % (table,)
	    if l.find(’CONSTRAINT’)>=0:
	        # start ignoring this stuff (for now)
	        flip = False
	        con = True
	        create = create[:-2]+’n’
	    if con and l.startswith(’)'):
	        # stop ignoring the constraint stuff
	        flip = True
	        con = False
	        continue
	    if l.startswith(’)'):
	        # reached the end of a ‘create’ statement
	        flip = False
	        create += ‘);n’
	        if table not in [’PFA_bancass$’]:
	            print create
	    if flip:
	        # un-sqlserver-ify
	        l = l.replace(’[',”)
	        l = l.replace(’]',”)
	        l = l.replace(’dbo.’,”)
	        l = l.replace(’IDENTITY(1,1)’,'auto_increment UNIQUE’)
	        l = l.replace(’money’,'float’)
	        # append clean line to ‘create’ string
	        create += l

	exit(0)

And, finally, to prove that it works, here’s the mysqlify.py script in action. Of course, in reality, the input file contained many table definitions.::

	ryant@uma:~/test/files$ ../mysqlify.py input.txt
	DROP TABLE IF EXISTS Blecchs;
	CREATE TABLE Blecchs(
	    BlecchId int auto_increment UNIQUE NOT NULL,
	    BlecchProvider varchar(50) NULL,
	    BlecchBrand varchar(50) NULL,
	    BlecchCode varchar(50) NULL,
	    BlecchGroup varchar(50) NULL,
	    Description varchar(200) NULL,
	    BlecchType varchar(2) NULL,
	    Affected bit NULL
	);

There were many annoyances with writing the translation script the way I did. I’d like to explore using something like SQLAlchemy to handle the table create statements. Also, I’d like to have the script handle the SQL Server constraints statements properly. There were some missing Indexes… Overall, though, I am glad I did not have to edit the input file by hand or use grep, sed, awk, tr, and other such tools to translate create statements to MySQL-ese.
