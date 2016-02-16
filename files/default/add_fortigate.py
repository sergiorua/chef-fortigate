#!/usr/bin/env python

import sys
import os
import getopt
import glob
from sbfg import *

def usage():
  print "Usage: %s <options>" % (sys.argv[0])
  print ""
  print "   -h                     Fortigate IP or Hostname"
  print "   -d                     Read all the files on this directory"
  print "   -r                     Recursive search in directory"
  print "   -f                     Read this file only"
  print "   -u                     Fortigate Username"
  print "   -v                     Fortigate VDom (def root)"
  print "   -t                     Fortigate config section (def firewall policy)"
  print "   -c                     Yaml file with Fortigate username and password"
  print ""
  sys.exit(0)


def read_options(argv):
  options={}
  try:
    opts, args = getopt.getopt(argv,"Vh:d:f:u:v:t:p:c:rx",["verbose","host=", "directory=", "file=", "username=", "vdom=", "type=", "password=", "creds-file=", "recursive", "dry-run"])
  except getopt.GetoptError, e:
    print e
    usage()
    sys.exit(2)

  options['vdom'] = None
  options['creds'] = None
  options['type'] = 'firewall policy'
  options['username'] = 'admin'
  options['password'] = ''
  options['directory'] = os.getcwd()
  options['verbose'] = False
  options['recursive'] = False
  options['dry_run'] = False
  for opt, arg in opts:
    if opt == '-d':
      options['directory'] = arg
    elif opt == '-f':
      options['file'] = arg
    elif opt == '-h':
      options['host'] = arg
    elif opt == '-v':
      options['vdom'] = arg
    elif opt == '-u':
      options['username'] = arg
    elif opt == '-t':
      options['type'] = arg
    elif opt == '-p':
      options['password'] = arg
    elif opt == '-V':
      options['verbose'] = True
    elif opt == '-r':
      options['recursive'] = True
    elif opt == '-x':
      options['dry_run'] = True
    elif opt == '-c':
      if os.path.exists(arg):
        options['username'], options['password'] = read_creds_file(arg)

  return options

class FgEntry:
  con = None
  address=[]
  addrgrp=[]
  service=[]
  policy=[]
  interface=[]
  vip=[]
  static=[]
  user=[]
  usergroup=[]

  def __init__(self, options):
    self.con = SkyBetFG(hostname=options['host'], username=options['username'], password=options['password'],
                      vdom=options['vdom'], verbose=options['verbose'],
                      dry_run=options['dry_run'])

if __name__ == '__main__':
  options = read_options(sys.argv[1:])
  section = options['type']

  # managing multiple end devices
  fgs={}

  if 'file' in options:
    files = [options['file']]
  else:
    files = []
    if options['recursive']:
      for root, subdirs, fss in os.walk(options['directory']):
        for f in fss:
          files.append(os.path.join(root, f))
    else:
      files = glob.glob(os.path.join(options['directory'], '*.yaml')) + glob.glob(os.path.join(options['directory'], '*.json'))

  for fi in files:
    data = read_from_file(fi)
    if 'subnet' in data or 'country' in data:
      section = 'firewall address'
    elif 'group_members' in data:
      section = 'user group'
    elif 'member' in data:
      section = 'firewall addrgrp'
    elif 'port' in data or 'category' in data:
      section = 'firewall service'
    elif 'extintf' in data:
      section = 'firewall vip'
    elif 'fwaction' in data:
      section = 'firewall policy'
      data['action'] = data['fwaction']
      del data['fwaction']
    elif 'gateway' in data:
      section = 'router static'
    elif 'passwd' in data:
      section = 'user local'
    else:
      print "Invalid data file: ", fi
      continue

    if 'vdom' in data:
      options['vdom'] = data['vdom']

    if not 'host' in data and 'host' in options:
      save_str = "%s-%s" % (options['host'], options['vdom'])
      if options['host'] in fgs:
        fg = fgs[options['host']]
      else:
        fg = FgEntry(options)
      fgs[save_str] = fg
    elif 'credentials' in data and 'host' in data:
      save_str = "%s-%s" % (data['host'], data['vdom'])
      if save_str in fgs:
        fg = fgs[save_str]
      else:
        options['username'], options['password'] = read_creds_file(data['credentials'])
        options['host'] = data['host']
        fgs[save_str] = FgEntry(options)
    else:
      print "I don't know how to connect"
      sys.exit(1)

    del data['host']
    del data['credentials']

    if 'firewall policy' in section:
      fgs[save_str].policy.append(data)
    elif 'firewall addrgrp' in section:
      fgs[save_str].addrgrp.append(data)
    elif 'firewall address' in section:
      fgs[save_str].address.append(data)
    elif 'system interface' in section:
      fgs[save_str].interface.append(data)
    elif 'firewall service' in section:
      fgs[save_str].service.append(data)
    elif 'firewall vip' in section:
      fgs[save_str].vip.append(data)
    elif 'router static' in section:
      fgs[save_str].static.append(data)
    elif 'user local' in section:
      fgs[save_str].user.append(data)
    elif 'user group' in section:
      fgs[save_str].usergroup.append(data)


for fg in fgs:
  for data in fgs[fg].interface:
    if data: fgs[fg].con.add_interface(**data)
  for data in fgs[fg].address:
    if data: fgs[fg].con.add_address(**data)
  for data in fgs[fg].addrgrp:
    if data: fgs[fg].con.add_address(**data)
  for data in fgs[fg].service:
    if data: fgs[fg].con.add_service(**data)
  for data in fgs[fg].service:
    if data: fgs[fg].con.add_service(**data)
  for data in fgs[fg].policy:
    if data: fgs[fg].con.add_fw_entry(**data)
  for data in fgs[fg].vip:
    if data: fgs[fg].con.add_fw_vip(**data)
  for data in fgs[fg].static:
    if data: fgs[fg].con.add_static_route(**data)
  for data in fgs[fg].user:
    if data: fgs[fg].con.add_user(**data)
  for data in fgs[fg].usergroup:
    if data: fgs[fg].con.add_group(**data)


  fgs[fg].con.commit()
