Slack Cleaner
=============

:date: 2017-03-20 17:48
:tags: python, slack
:category: tech
:author: Ryan Tracey
:slug: slack-cleaner


If you find you're running out of space on Slack, it may be that you have too many
images floating in storage. However, deleting them via the Slack interface is
tedious to say the least.

Enter stage left: the Slack API. Here's a script I wrote to list and then delete any
images older than a given number of months.


.. code-block:: python

    #!/usr/bin/env python

    import sys
    import json
    import time
    import datetime
    import requests

    try:
        user = open('user.slack', 'rb').readline().strip()
        token = open('token.slack', 'rb').readline().strip()
    except IOError:
        print('Create user.txt and token.txt')
        sys.exit()

    baseurl = 'https://slack.com/api'


    def epoch_to_date(seconds):
        return time.strftime('%Y-%m-%d', time.gmtime(float(seconds)))


    def get_date_seconds(months_ago):
        d = datetime.date.today() - datetime.timedelta(months_ago*365/12)
        return int(d.strftime('%s'))


    def get_file_ids(token, user, months_ago):
        files_dict = {}
        date_seconds = get_date_seconds(months_ago)
        list_url = '%s/files.list?token=%s&user=%s&ts_to=%d&types=images' \
            % (baseurl, token, user, date_seconds)
        ret = requests.get(list_url)
        try:
            js = json.loads(ret.text)
        except:
            print('Could not turn ret.txt into json')
            sys.exit()
        # create sortable (by date) dictionary
        for slack_file in js['files']:
            files_dict[slack_file['created']] = (slack_file['id'],
                                                 slack_file['name'])
        return files_dict


    def delete_files(files_dict):
        _delete_url = '%s/files.delete?token=%s&file=%s'
        created_list = files_dict.keys()
        created_list.sort()
        for create_time in created_list:
            file_id = files_dict[create_time][0]
            file_name = files_dict[create_time][1]
            file_date = epoch_to_date(create_time)
            print('[Created: %s] [id: %s] Deleting %s' % (file_date, file_id,
                                                          file_name,)),
            delete_url = _delete_url % (baseurl, token, file_id)
            r = requests.get(delete_url)
            print(' ...[%d]' % (r.status_code,))


    def main(token, user, months_ago):
        files_dict = get_file_ids(token, user, months_ago)
        delete_files(files_dict)


    if __name__ == '__main__':

        try:
            months_ago = int(sys.argv[1])
        except IndexError, TypeError:
            print('Usage: %s <months-ago>' % sys.argv[0])
            sys.exit()

        main(token, user, months_ago)
