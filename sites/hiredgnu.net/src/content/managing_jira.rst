Managing The Joys of Jira
=========================

:date: 2017-03-06 17:48
:tags: python, jira
:category: tech
:author: Ryan Tracey
:slug: managing-jira

Managing the joys of Jira
-------------------------

We all know and love Jira, especially when one needs to
log time and perform other soul-sucking activities.

I wrote the following script to help make working with
Jira a little bit more palatable.

Functions include deleting all the annoying email-footer
images that get attached to tickets when a person emails
to Jira, closing Jira tickets in the "In Review" state, etc.

This is a work in progress. One of those "time permitting" things.

.. code-block:: python

	#!/usr/bin/env python
	
	"""
	http://jira.readthedocs.org/en/latest/
	http://pythonhosted.org/jira/
	"""
	
	from __future__ import print_function
	
	import datetime
	import hashlib
	import argparse
	import logging
	
	
	from jira.exceptions import JIRAError
	from jira.client import JIRA
	from config import password, username
	
	from tzlocal import get_localzone
	
	tz = get_localzone()
	logging.captureWarnings(True)
	
	image_sha1 = [
	    'd4eb62ac1b88ad4a39aa1e907dc51093a11e4c2c',
	    '14ccfccf0a01c66df43601c13d09f3a7172f8de3',
	    'c263a5ec4306721aa039d5f55ae108a5cb60efea',
	    '6f53c75a06cb0ccc700e81c2a40315204dc89c53',
	    'a97c6451630ad10047cf33d505f1326f5247add0',
	    '72ebf3111b34e565aec8b23b4dba9533c3d976a2',
	    '4bf304bcd472cc92ae63b2df0d476618c2890428',
	    'f4d0668f235368a8951fb42b2112d5f162c816af',
	    '695cfde3e0d49fe546a3de07b8b2ceb89f657aac',
	    ]
	
	
	searches = {
	    'inreview': 'assignee=%s AND status = "In Review"' % username,
	    'bycreate': ('assignee=%s AND resolution = Unresolved '
	                 'order by updated DESC') % username,
	    'bypriority': ('assignee=%s AND status NOT IN (Closed, Resolved, Done)'
	                   'order by Priority') % username,
	    'done_unresolved': ('assignee=%s AND resolution = Unresolved and'
	                        'status = done order by updated DESC') % username,
	}
	
	
	issues = {
	    'ADMIN-56': 'General Admin',
	    'ADMIN-7': 'Non-client Meetings',
	    'ADMIN-58': 'Internal design requests',
	    'ADMIN-66': 'wiChillaz',
	    'ADMIN-12': 'Internal process improvements',
	    'DEVOPS-461': 'DevOps Core Activity',
	}
	
	
	def initial_monthly(jira_connection):
	    d = datetime.datetime.now()
	    started_date = tz.localize(datetime.datetime(d.year, d.month, 1))
	    # started_date = tz.localize(started_date)
	    for issue in issues:
	        jira_connection.add_worklog(issue, timeSpent='1m',
	                                    comment='Initial worklog',
	                                    started=started_date)
	        print(issue)
	
	
	def print_issue(jira_connection, issue_list, attachments=False):
	    for _issue in issue_list:
	        try:
	            issue = jira_connection.issue(_issue)
	        except JIRAError:
	            print('Issue %s does not exist' % _issue)
	            continue
	        print('%-12s %-25s %-16s %-8s %-8s %-12s %-18s %-18s %s' %
	              (issue.key,
	               issue.fields.status,
	               issue.fields.resolution,
	               issue.fields.timespent,
	               issue.fields.timeestimate,
	               issue.fields.priority,
	               issue.fields.assignee,
	               issue.fields.reporter,
	               issue.fields.summary))
	        attachments = issue.fields.attachment
	        for attachment in attachments:
	            # content = attachment.get()
	            # sha1 = hashlib.sha1(content).hexdigest()
	            print('\t\t\t%20s %s' % (attachment.filename, ''))
	
	
	def list_issues(jira_connection, verbose, search):
	    myissues = jira_connection.search_issues(searches[search])
	    for item in myissues:
	        issue = jira_connection.issue(item)
	        if verbose:
	            print_issue(jira_connection, issue)
	        else:
	            s = u'%-12s %-20s %s %s' % (
	                                    item,
	                                    issue.fields.status,
	                                    get_date(issue.fields.created),
	                                    issue.fields.summary)
	            s = s.encode('ascii', 'ignore').decode('ascii')
	            print(s)
	
	
	def remove_images(jira_connection, issue, image_name=None):
	    issue = jira_connection.issue(issue[0])
	    attachments = issue.fields.attachment
	    for attachment in attachments:
	        if image_name == attachment.filename:
	            content = attachment.get()
	            sha1 = hashlib.sha1(content).hexdigest()
	            if sha1 in image_sha1:
	                print('Deleting %s...' % attachment.filename, end=' ')
	                attachment.delete()
	                print(' done')
	            else:
	                print('Skipping %s...' % attachment.filename)
	
	
	def delete_issue(jira_connection, issue):
	    print('Delete issue %s' % (issue,))
	    issue = jira_connection.issue(issue)
	    issue.delete()
	
	
	def make_done_resolved(jira_connection, issue_list):
	    if issue_list == 'all':
	        issue_list = jira_connection.search_issues(searches['inreview'])
	    for issue in issue_list:
	        transitions = jira_connection.transitions(issue)
	        enum = enumerate(transitions)
	        while True:
	            e = enum.next()
	            id = e[0]
	            if e[1]['name'] == 'Done':
	                transition_id = e[1]['id']
	                break
	        to_id = transitions[id]['to']['id']
	        print('issue=%s transtion(id=%s, state=%s)' %
	              (issue, str(transition_id), str(to_id)))
	        jira_connection.transition_issue(issue, transition_id,
	                                         resolution={'id': to_id})
	
	
	def __make_done_resolved(jira_connection, issue):
	    transitions = jira_connection.transitions(issue)
	    print(transitions)
	    # jira_connection.transition_issue(issue, '51')
	    # jira_connection.transition_issue(issue, '21')
	
	
	def get_date(datestr):
	    return datestr.split('T')[0]
	
	
	def get_definition(issue):
	    return issue.fields.description
	
	
	def set_lorum_definition(issue):
	    if not issue.fields.description:
	        with open('lorum.txt', 'rb') as f:
	            issue.update(description=f.read())
	
	
	def projects():
	    pass
	
	
	def list_searches():
	    txt = 'List issues using one of the following searches:\n'
	    for search in searches.keys():
	        txt += '\t%s\n' % search
	    return txt
	
	
	def parse_args():
	    parser = argparse.ArgumentParser(description='Jira Tool')
	    parser.add_argument('-v', '--verbose',
	                        dest='verbose', action='store_true', default=False)
	    parser.add_argument('-d', '--delete-issue',
	                        dest='delete_issue', action='store', default='')
	    parser.add_argument('-0', '--remove-image',
	                        dest='remove_image', action='store', default='')
	    parser.add_argument('-l', '--list-issues',
	                        dest='list_issues', action='store', default='',
	                        choices=searches.keys(), help=list_searches())
	    parser.add_argument('-i', '--issue', nargs='+',
	                        dest='issue', action='store', default='')
	    parser.add_argument('-r', '--resolve-done', dest='resolve_done',
	                        action='store', default='')
	    parser.add_argument('--lorum', dest='lorum_issue', action='store',
	                        default=None)
	    parser.add_argument('--initialise', dest='initialise', action='store_true',
	                        default=False)
	    # parser.add_argument('', '', dest='', action='', default=)
	    args = parser.parse_args()
	    return args, parser
	
	
	def jira_con():
	    return JIRA(options={'server': 'https://wigroup2.atlassian.net'},
	                basic_auth=(username, password))
	
	
	if __name__ == "__main__":
	
	    args, parser = parse_args()
	    global verbose
	    verbose = args.verbose
	
	    jira_connection = jira_con()
	
	    if args.issue:
	        print_issue(jira_connection, args.issue, attachments=False)
	    elif args.remove_image and args.remove_image:
	        image_name = args.remove_image
	        remove_images(jira_connection, args.issue, image_name)
	    elif args.delete_issue:
	        delete_issue(jira_connection, args.delete_issue)
	    elif args.resolve_done:
	        make_done_resolved(jira_connection, args.resolve_done)
	    elif args.list_issues:
	        list_issues(jira_connection, verbose, args.list_issues)
	    elif args.lorum_issue:
	        issue = jira_connection.issue(args.lorum_issue)
	        set_lorum_definition(issue)
	    elif args.initialise:
	        initial_monthly(jira_connection)
	    else:
	        parser.print_help()


