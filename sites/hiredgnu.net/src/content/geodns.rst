Bind, GeoIP, and Python a Beautiful Soup doth make
==================================================

:date: 2007-11-20 09:27
:tags: dns, python
:category: tech
:author: Ryan Tracey
:slug: geodns-and-python

.. _GeoDNS: http://www.caraytech.com/geodns/

The week that was
-----------------

This past week saw me get a tooth implant. Ouch. You know its bad when the dentist says “close your eyes, we don’t want you blinded by flying tooth fragments”! OMG WTF!

This past week also saw me doing something just as painful as having my left-front incisor chiselled out. Or so it would have been had I not thought “Oh stuff it! There has to be a better way?!”

BIND and GeoDNS
---------------

For a client who has multiple DNS round-robin balanced web servers I had patched the BIND source to support GeoDNS_ and had installed and configured a working instance with some basic examples to demonstrate that BIND was working with the GeoDNS_ patch. The GeoDNS_ patch extends the “view” functionality available in later versions of BIND. Basically views work like this:

A client connects to BIND and says gimme the IP address for www.example.com
BIND sees that the client matches a particular “view”.
BIND finds the zone file associated with that view and dishes out the IP address it finds therein
(for each view there should be a corresponding zone file)

What the GeoDNS_ patch does is add a new method by which a “view” can be chosen. Now the client’s country, as determined by GeoIP, can determine which view, and thus which zonefile, and thus which IP address will be returned. Here’s the example from the GeoDNS_ website:::

	view "north_america" {
	      match-clients { country_US; country_CA; country_MX; };
	      recursion no;
	      zone "example555.com" {
	            type master;
	            file "pri/example555-north-america.db";
	      };
	};
	view "south_america" {
	      match-clients { country_AR; country_CL; country_BR; country_PY; country_PE; country_EC; country_CO; country_VE; country_BO, country_UY; };
	      recursion no;
	      zone "example555.com" {
	            type master;
	            file "pri/example555-south-america.db";
	      };
	};
	view "other" {
	      match-clients { any; };
	      recursion no;
	      zone "example555.com" {
	            type master;
	            file "pri/example555-other.db";
	      };
	};

The GeoDNS_ patch allows one to use the match-clients keyword and its associated list of countries (country_XX) within views. In the above example clients from Mexico (country_MX), Canada (country_CA), and the US (country_US) will get the data from the example555-north-america.db zonefile returned to them in response to their DNS requests. South America is similarly configured. Any client not matched by the countries in the North and South America views will default to the “other” view.

The beauty of this is that BIND can, for the same FQDN, dish out a different IP address to clients from different countries. So, if you have web servers in Europe, South Africa, and America you can have your clients connect to the web server that they are closest to. This is a huge saving over method such as DNS round robin where, potentially, you divide the load between web servers equally but randomly and you could have American or European clients hitting your South African web server and eating its bandwidth up.

Now, back to my client installation. I had tested GeoDNS_ with only a few countries listed in the views definitions I had configured. Now I needed to list ALL the countries in the views I had configured. However, while there is an official website list of country codes (iso3166) which offers text.csv, HTML, and XML versions of the iso3166 database I could find no text or XML file which catalogued the countries by continent or region. I did however find a website which listed countries by region in a nicely laid table. This is where the fun began.

Hmm, what should I use to get the info I need out of an HTML table. Sed? Sure, could do that. Done it before… and I don’t want to do it again. Hmm, Python regexes. Done that before too. Same thing as sed, though, Regular Expressions. Helpful but… been there, done that.

Enter BeautifulSoup, the HTML parsing toolkit for Python. A thing of wonder and beauty. I fired up the python listener and started typing.


.. code-block:: python

	from BeautifulSoup import BeautifulSoup
	from urllib2 import urlopen

	url = 'http://resources.potaroo.net/iso3166/iso3166tablecc.html'
	page = urlopen(url)
	soup = BeautifulSoup(page)

Looking at the source I had printed to another terminal using curl I could see that I needed the second table on that page:

.. code-block:: python

	table = soup.findAll('table')[1]

And then I needed all the table rows except for the first (I don’t need the headers.)

.. code-block:: python

	rows = table.findAll('tr')[1:]

And then I need to step through that list of rows and extract the contents from each of the table data elements. Let’s just pick the first one to find out how that’s done:

.. code-block:: python

	>>> rows[0].findAll('td')[0].contents[0]
	u'AD'
	>>> rows[0].findAll('td')[1].contents[0]
	u'Andorra'
	>>> rows[0].findAll('td')[2].contents[0]
	u'Southern Europe'
	>>> rows[0].findAll('td')[3].contents[0]
	u'Europe'
	Ah, you have to love the instant response of a scripting language’s listener.

Here’s what I ended up with:

.. code-block:: python

	from BeautifulSoup import BeautifulSoup
	from urllib2 import urlopen
	from sys import argv

	url = 'http://resources.potaroo.net/iso3166/iso3166tablecc.html'

	args = argv[1:]
	if '-t' in args:
	    test=True
	    args.remove('-t')
	else:
	    test=False

	region = args[0]
	try:
	    subregion = args[1]
	except:
	    subregion = ''

	page = urlopen(url)
	soup = BeautifulSoup(page)

	i=0
	txt=u''
	prnt=False
	for row in soup.findAll('table')[1].findAll('tr')[1:]:
	    row = row.findAll('td')
	    try:
	        subreg = row[2].contents[0]
	        reg = row[3].contents[0]
	        code = row[0].contents[0]
	        country = row[1].contents[0]
	    except:
	        if test:
	            print row
	        continue
	    if region==reg:
	        prnt=True
	        if subregion:
	            if subregion==subreg:
	                prnt=True
	            else:
	                prnt=False
	        if prnt:
	            if test:
	                print '%st"%s"t%st%s' % (reg, subreg, code, country)
	            else:
	                if i>5:
	                    txt+='n'
	                    i=0
	                txt+='country_%s; ' % (code,)
	                i+=1
	print txt

And here’s the output nicely formatted for inclusion into named.conf:::

	ryant@uma:~$ ./fetch3166codes.py Europe
	country_AD; country_AL; country_AT; country_AX; country_BA; country_BE;
	country_BG; country_BY; country_CH; country_CS; country_CZ; country_DE;
	country_DK; country_EE; country_ES; country_EU; country_FI; country_FO;
	country_FR; country_GB; country_GI; country_GR; country_HR; country_HU;
	country_IE; country_IS; country_IT; country_LI; country_LT; country_LU;
	country_LV; country_MC; country_MD; country_MK; country_MT; country_NL;
	country_NO; country_PL; country_PT; country_RO; country_RU; country_SE;
	country_SI; country_SJ; country_SK; country_SM; country_UA; country_UK;
	country_VA;

All in all a much nicer way to spend an evening than painstakingly looking up country abbreviations and plonking them in their correct regions. Or getting a tooth extracted and replaced by something that looks like a drill-bit.
