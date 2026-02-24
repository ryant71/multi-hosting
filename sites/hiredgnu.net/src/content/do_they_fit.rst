Do They Fit?
============

:date: 2013-06-15 10:40
:tags: python
:category: tech
:author: Ryan Tracey
:slug: do-they-fit


Do you want to know if the MP3s in that folder will fit on a CD?

No problem.

.. code-block:: python

    #!/usr/bin/env python

    import audioread
    import sys

    try:
        files = sys.argv[1:]   
    except:
        print('Usage: %s <files/glob>' % (sys.argv[0],))
        sys.exit()

    total_length = 0.0
    for file in files:
        f = audioread.audio_open(file)
        d = f.duration
        print('%-50s %f' % (file, d))
        total_length += d

    print('Total length: %d:%d' % (total_length/60,total_length%60))


Cheers!
