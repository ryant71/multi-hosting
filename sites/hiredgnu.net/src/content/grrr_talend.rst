Grrr Talend
===========

:date: 2017-03-07 17:48
:tags: python, talend
:category: tech
:author: Ryan Tracey
:slug: grrr-talend

The company I work for really likes Talend at the moment. However,
they often don't consider that, as great as Talend is, it seemingly
cannot do things like take in command line parameters. For instance,
like a date that you'd like to regenerate a data extract job for.

The only way to do this seemed to be to edit Talend's Default.properties
file, a set particular variable (RUN_HOUR) which can co-incidently be abused
to calculate dates as hours-in-the-past.

To do this manually for a lot of dates would have been mind-numbing, so...


.. code-block:: python

    #!/usr/bin/env python

    import os
    import re
    import sys
    from datetime import datetime
    from subprocess import call

    rootdir = '/home/myemployers/applications/xyz-giftcard'

    files = {
        'na':
        {
           'recon': (
                     ('%s/na/recon/latest/XYZ_GIFTCARD_RECON_NA/'
                      'xyz_data_extracts/'
                      'xyz_giftcard_recon_na_1_1/contexts/'
                      'Default.properties' % rootdir),
                     '%s/na/recon/run.sh' % rootdir
                    ),
           'revoke': (
                      ('%s/na/revoke/latest/XYZ_GIFTCARD_REVOKE_NA/'
                       'xyz_data_extracts/xyz_giftcard_revoke_na_1_1/contexts/'
                       'Default.properties' % rootdir),
                      '%s/na/revoke/run.sh' % rootdir
                     ),
        },
        'za':
        {
           'recon': (
                     ('%s/za/recon/latest/XYZ_GIFTCARD_RECON_ZA/'
                      'xyz_data_extracts/xyz_giftcard_recon_za_1_1/'
                      'contexts/Default.properties' % rootdir),
                     '%s/za/recon/run.sh' % rootdir),
           'revoke': (
                      '%s/za/revoke/latest/XYZ_GIFTCARD_REVOKE_ZA/'
                      'xyz_data_extracts/xyz_giftcard_revoke_za_1_1/'
                      'contexts/Default.properties' % rootdir,
                      '%s/za/revoke/run.sh'
                     ),
        },

    }

    outfiles = '%s/files/out'
    tmpdir = '/home/myemployers/file-regen'


    def hours_from_date(thedate):
        diff = datetime.now() - datetime.strptime(thedate, '%Y%m%d')
        return diff.days * 24 * -1


    def make_file(config_file, hours_ago):
        txt = ''
        with open(config_file, 'r') as f:
            for line in f:
                if line.startswith('RUN_HOUR'):
                    hour = re.match(r'RUN_HOUR=(\-*[0-9]+)', line).group(1)
                    txt += line.replace(hour, hours_ago)
                else:
                    txt += line
        return txt


    def reset_config(config_file):
        txt = ''
        with open(config_file, 'r') as f:
            for line in f:
                if line.startswith('RUN_HOUR'):
                    hour = re.match(r'RUN_HOUR=(\-*[0-9]+)', line).group(1)
                    txt += line.replace(hour, '0')
                else:
                    txt += line
        return txt


    def call_app(runapp, thedate):
        """
        NAM_RECON_20170127120427.csv
        NAM_RVK20170127120510.csv
        """
        today = datetime.strftime(datetime.today(), '%Y%m%d')
        call([runapp])
        for filename in os.listdir(outfiles):
            newfilename = filename.replace(today, thedate)
            filepath = '%s/%s' % (outfiles, filename)
            newfilepath = '%s/%s' % (tmpdir, newfilename)
            print('%s -> %s' % (filepath, newfilepath))
            os.rename(filepath, newfilepath)


    if __name__ == "__main__":

        try:
            country = sys.argv[1]
            filetype = sys.argv[2]
            thedate = sys.argv[3]
        except IndexError:
            print('Usage: %s <za|na> <recon|revoke> YYYYmmdd')
            sys.exit()

        if country not in ['za', 'na']:
            print('Usage: %s <za|na> <recon|revoke> YYYYmmdd')
            sys.exit()

        if filetype not in ['recon', 'revoke']:
            print('Usage: %s <za|na> <recon|revoke> YYYYmmdd')
            sys.exit()

        config_file = files[country][filetype][0]
        runapp = files[country][filetype][1]
        hours_ago = str(hours_from_date(thedate))
        new_file = make_file(config_file, hours_ago)
        os.rename(config_file, '%s.bak' % config_file)

        with open(config_file, 'wb') as f:
            f.write(new_file)

        print('Updated file')
        with open(config_file, 'r') as f:
            print(f.read())

        call_app(runapp, thedate)

        reset_file = reset_config(config_file)
        with open(config_file, 'wb') as f:
            f.write(reset_file)

        print('Reset file')
        with open(config_file, 'r') as f:
            print(f.read())
