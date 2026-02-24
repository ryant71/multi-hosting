Converting Local Github Repository To Use A Deployment Key
==========================================================

:date: 2021-04-15 17:00
:tags: python, github, ssh
:category: tech
:author: Ryan Tracey
:slug: github_repo_conversion 
:summary: Use a python script to generate

.. code-block:: python

   #!/usr/bin/env python
   """
   Requirements:
       - pip install click
       - pip install paramiko
       - pip install requests

   TODO:
       Package with setuptools or something similar
   """

   import re
   import os
   import sys
   import json
   import click
   import shutil
   import requests

   from os import listdir
   from os.path import abspath, basename, isfile
   from pathlib import Path
   from paramiko import RSAKey
   from uuid import uuid1

   HOME = str(Path.home())
   SSHDIR = f'{HOME}/.ssh'
   GH_BASE_URL = 'https://api.github.com/repos/<my_organisation>/'
   GH_ACCEPT_HEADER = {'Accept': 'application/vnd.github.v3+json'}


   SSH_TEMPLATE = """
   Host github.com-%s
       Hostname github.com
       User git
       IdentityFile ~/.ssh/id_rsa_%s
   """


   def repo_exists(repo_name, api_token):
       repo_keys_url = GH_BASE_URL + repo_name
       gh_auth_header = {'Authorization': f'token {api_token}'}
       req_headers = {**gh_auth_header, **GH_ACCEPT_HEADER}
       resp = requests.get(repo_keys_url, headers=req_headers)
       if resp.status_code == requests.codes.ok:
           return True
       else:
           return False


   def create_deploy_pubkeys(repo_name, pub_key_name, api_token):
       repo_keys_url = GH_BASE_URL + repo_name + '/keys'
       with open(pub_key_name, 'r') as f:
           pub_key_string = f.read()
       gh_auth_header = {'Authorization': f'token {api_token}'}
       req_headers = {**gh_auth_header, **GH_ACCEPT_HEADER}
       data = json.dumps({'key': pub_key_string})
       resp = requests.post(repo_keys_url, headers=req_headers, data=data)
       if resp.status_code == requests.codes.ok:
           print(u'Key {pub_key_name} uploaded successfully \u2713')
       elif resp.status_code == 422:
           message = resp.json()['errors'][0]['message']
           print(f'Deploy {message} \u2717 (this may be because you are re-running the script for this repo \u263A)')
       else:
           print(f'{resp.status_code} {resp.reason} \u2713')
           print(json.dumps(resp.json(), indent=2))


   def genkey(priv_key_name, pub_key_name):
       # generate private key
       prv = RSAKey.generate(bits=2048)
       prv.write_private_key_file(filename=priv_key_name, password=None)

       # generate public key
       pub = RSAKey(filename=priv_key_name, password=None)

       with open(pub_key_name, 'w') as f:
           f.write(f'{pub.get_name()} {pub.get_base64()}')
           f.write(f' {basename(pub_key_name)}')

       print('SSH keys generated \u2713')


   def write_ssh_config(repo_name):
       append = SSH_TEMPLATE % (repo_name, repo_name)
       ssh_config_file = f'{SSHDIR}/config'
       with open(ssh_config_file,'r') as f:
           for line in f.readlines():
               if f'github.com-{repo_name}' in line:
                   print('SSH config already updated \u2713')
                   return
       hash = str(uuid1())[:8]
       shutil.copyfile(ssh_config_file, f'{ssh_config_file}.{hash}')
       with open(ssh_config_file, 'a+') as f:
           f.write(append)
       print('SSH config updated \u2713')


   def update_git_conf(repo_name, repo_path):
       git_config_file = f'{repo_path}/.git/config'
       if not isfile(git_config_file):
           print(f'File not exists: {git_config_file} \u2717')
           return
       p = re.compile('(\s*url\s*=\s*git@github.com)(:<my_organisation>/)(\S+)(.git\s*)')
       new_file = ''
       with open(git_config_file, 'r') as f:
           for line in f.readlines():
               m = p.search(line)
               if m:
                   new_file += m.group(1) + '-' + repo_name + m.group(2) + m.group(3) + m.group(4)
               else:
                   new_file += line
       hash = str(uuid1())[:8]
       shutil.copyfile(git_config_file, f'{git_config_file}.{hash}')
       with open(git_config_file, 'w') as f:
           f.write(new_file)
       print('Git config file has been updated \u2713')


   @click.command(no_args_is_help=True)
   @click.option('--api-token', 'api_token', prompt=True, help='Your github API token. (Optional)')
   @click.argument('repo_path', type=click.Path(exists=True))
   def main(api_token, repo_path):

       repo_path = abspath(repo_path)
       repo_name = basename(repo_path)

       if not isfile(f'{repo_path}/.git/config'):
           print(f'Local directory {repo_path} is not a git repository \u2717')
           sys.exit(1)
       else:
           print(f'Local directory {repo_path} is a git repository \u2713')


       if not repo_exists(repo_name, api_token):
           print(f'Github repository {repo_name} does not exist or API Token is wrong \u2717')
           sys.exit(1)
       else:
           print(f'Github repository {repo_name} exists \u2713')


       priv_key_name = f'{SSHDIR}/id_rsa_{repo_name}'
       pub_key_name = f'{priv_key_name}.pub'

       if isfile(pub_key_name):
           print(f'Public key {pub_key_name} already exists \u2713')
       else:
           genkey(priv_key_name, pub_key_name)

       create_deploy_pubkeys(repo_name, pub_key_name, api_token)
       write_ssh_config(repo_name)
       update_git_conf(repo_name, repo_path)


   if __name__ == "__main__":

       main()
