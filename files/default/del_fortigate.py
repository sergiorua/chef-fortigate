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
  print "   -n                     Name of entry to delete"
  print "   -u                     Fortigate Username"
  print "   -v                     Fortigate VDom (def root)"
  print "   -t                     Fortigate config section (def firewall policy)"
  print "   -c                     Yaml file with Fortigate username and password"
  print ""
  sys.exit(0)

def read_options(argv):
  options={}
  try:
    opts, args = getopt.getopt(argv,"VDh:u:v:t:p:c:n:f:x",["verbose", "dry-run", "host=", "username=", "vdom=", "type=", "password=", "creds-file=", "name=", "file="])
  except getopt.GetoptError, e:
    print e
    usage()
    sys.exit(2)

  options['vdom'] = None
  options['creds'] = None
  options['type'] = 'firewall policy'
  options['username'] = 'admin'
  options['password'] = ''
  options['verbose'] = False
  options['dry_run'] = False
  options['file'] = None
  for opt, arg in opts:
    if opt == '-D':
      options['dry_run'] = True
    elif opt == '-n':
      options['name'] = arg
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
    elif opt == '-f':
      options['file'] = arg
    elif opt == '-x':
      options['dry_run'] = True
    elif opt == '-c':
      if os.path.exists(arg):
        options['username'], options['password'] = read_creds_file(arg)

  return options

if __name__ == '__main__':
  options = read_options(sys.argv[1:])

  if options['file']:
    data = read_from_file(options['file'])
    if 'subnet' in data:
      section = 'firewall address'
    elif 'member' in data:
      section = 'firewall addrgrp'
    elif 'port' in data or 'category' in data:
      section = 'firewall service'
    elif 'fwaction' in data:
      section = 'firewall policy'
      data['action'] = data['fwaction']
      del data['fwaction']
    else:
      print "Invalid data file"
      sys.exit(1)
    name = data['name']
    options['host'] = data['host']
    options['vdom'] = data['vdom']
    options['username'], options['password'] = read_creds_file(data['credentials'])
  elif options['name'] and options['type']:
    name = options['name']
    section = options['type']
  else:
    print "Usage: ..."
    sys.exit(1)
    

  fg = SkyBetFG(hostname=options['host'], username=options['username'], 
    password=options['password'], verbose=options['verbose'],
    vdom=options['vdom'],
    dry_run=options['dry_run'])


  fg.del_entry(name, section)
