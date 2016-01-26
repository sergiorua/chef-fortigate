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
  print "   -v                     Fortigate vDOM"
  print "   -f                     Write to this file only"
  print "   -u                     Fortigate Username"
  print "   -c                     Yaml file with Fortigate username and password"
  print "   -u                     Username (if no creds file)"
  print "   -p                     Password (if no creds file)"
  print ""
  sys.exit(0)

def read_options(argv):
  options={}
  try:
    opts, args = getopt.getopt(argv,"Vh:v:u:p:c:s:",["verbose","host=", "vdom=","username=", "password=", "creds-file=", "section="])
  except getopt.GetoptError:
    usage()
    sys.exit(2)

  options['creds'] = None
  options['username'] = 'admin'
  options['password'] = ''
  options['verbose'] = False
  options['vdom'] = None
  options['section'] = 'firewall policy'
  options['credentials'] = None
  for opt, arg in opts:
    if opt == '-h':
      options['host'] = arg
    elif opt == '-u':
      options['username'] = arg
    elif opt == '-p':
      options['password'] = arg
    elif opt == '-V':
      options['verbose'] = True
    elif opt == '-v':
      options['vdom'] = arg
    elif opt == '-s':
      options['section'] = arg
    elif opt == '-c':
      if os.path.exists(arg):
        options['credentials'] = arg
        options['username'], options['password'] = read_creds_file(arg)

  if not 'host' in options:
    print "Hostname missing"
    usage()
    sys.exit(1)

  return options

def convert_to_chef_policy(entries, options):
  for n in entries:
    if 'ippool' in entries[n]: continue
    print "fortigate_policy '%s' do" % (n)
    for k in entries[n]:
      print "  host    '%s'\n  credentials    '%s'" % (options['host'], options['credentials'])
      if k in ['dstaddr', 'dstintf', 'srcaddr', 'srcintf', 'service']:
        print "  %s     %s" % (k, entries[n][k].replace('"','').split())
      elif k == 'action':
        print "  fwaction     '%s'" % (entries[n][k])
      elif k == 'nat':
        print "  nat          '%s'" % (entries[n][k])
      else:
        print "  %s     %s" % (k, entries[n][k])
    print "end\n"

def convert_to_chef_address(entries, options):
  for n in entries:
    if not 'subnet' in entries[n]: continue
    print "fortigate_address '%s' do" % (n)
    print "  host    '%s'\n  credentials    '%s'" % (options['host'], options['credentials'])
    for k in entries[n]:
      print "  %s     '%s'" % (k, entries[n][k])
    print "end\n"

def convert_to_chef_addrgrp(entries, options):
  for n in entries:
    print "fortigate_addrgrp '%s' do" % (n)
    print "  host    '%s'\n  credentials    '%s'" % (options['host'], options['credentials'])
    print "  member     '%s'" % (entries[n]['member'].replace('"','').split())
    print "end\n"

def convert_to_chef_service(entries, options):
  for n in entries:
    print "fortigate_service '%s' do" % (n)
    print "  host    '%s'\n  credentials    '%s'" % (options['host'], options['credentials'])
    for k in entries[n]:
      if 'tcp' in k:
        print "  tcp     %s" % (entries[n][k].replace('"','').split())
      elif 'udp' in k:
        print "  udp     %s" % (entries[n][k].replace('"','').split())
      else:
        if '"' in entries[n][k]:
          print "  %s     %s" % (k, entries[n][k])
        else:
          print "  %s     '%s'" % (k, entries[n][k])
    print "end\n"

if __name__ == '__main__':
  options = read_options(sys.argv[1:])
  fg = SkyBetFG(hostname=options['host'], username=options['username'], password=options['password'], verbose=options['verbose'])
  sect = fg.get_section(options['section'], vdom=options['vdom'])

  fw_entry = {}
  for i,b in sect.iterblocks():
    fw_entry[i] = {}
    for key,value in b.iterparams():
      fw_entry[i][key] = value

  if options['section'] == 'firewall policy':
    convert_to_chef_policy(fw_entry, options)
  elif options['section'] == 'firewall address':
    convert_to_chef_address(fw_entry, options)
  elif options['section'] == 'firewall addrgrp':
    convert_to_chef_addrgrp(fw_entry, options)
  elif options['section'] == 'firewall service custom':
    convert_to_chef_service(fw_entry, options)

