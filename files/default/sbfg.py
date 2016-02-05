#!/usr/bin/env python

from pyFG import FortiOS, FortiConfig
import pyFG
from pprint import pprint
import time
import yaml
import json
import sys
import os

colorJson = True
try:
  from pygments import highlight, lexers, formatters
except:
  colorJson = False

def print_color(data, ft='json'):
  if type(data) == dict or type(data) == list:
    if 'json' in ft:
      data = json.dumps(data, sort_keys=True, indent=4)
    elif 'yaml' in ft:
      data = yaml.dump(data, default_flow_style=False)

  if colorJson:
    try:
      colorful_json = highlight(unicode(data, 'UTF-8'), lexers.JsonLexer(), formatters.TerminalFormatter())
      print(colorful_json)
    except:
      print data
  else:
    print data

def quote(st):
  if '"' in st: return st
  if type(st) is list:
    st = ' '.join(st)
  st = st.replace(' ', '" "')
  return "\"%s\"" % (st)

def ftype(fname):
  if fname.endswith('yaml') or fname.endswith('yml'):
    return 'yaml'
  elif fname.endswith('json'):
    return 'json'

  return None

def read_from_file(filename):
  if "~" in filename:
    filename = os.path.expanduser(filename)
  f = open(filename)

  if 'yaml' in ftype(filename):
    data = yaml.load(f)
  else:
    data = json.load(f)
  f.close()

  return data

def read_creds_file(filename):
  data = read_from_file(filename)
  if 'username' in data and 'password' in data:
    return data['username'], data['password']
  return None, None

class SkyBetFG:
  verbose = True
  fg = None
  username = None
  password=None
  dry_run=None
  d = None
  vdom = None
  current_config = None
  candidate_config = None
  running_config = {}

  def __init__(self, hostname=None, username=None, password=None, vdom=None, verbose=True, dry_run=False):
    self.fg = hostname
    self.username = username
    self.password = password
    self.verbose = verbose
    self.dry_run = dry_run
    self.vdom = vdom

    if verbose: print "Connecting to %s on vdom %s" % (hostname, vdom)
    self.d = FortiOS(self.fg, username=self.username, password=self.password, vdom=vdom)
    self.d.open()
    self.current_config = self.d.running_config.to_text()

#    for section in ['system interface', 'firewall policy', 'firewall address', 'firewall addrgrp']:
#      if section in dev.running_config[section]:
#        self.running_config[section] = dev.running_config[section]

  def _fg(self):
    return self.d

  def commit(self):
    d = self.d

    changes = d.compare_config(text=True)
    if self.verbose or self.dry_run: print changes
    if self.dry_run: return True
    try:
      d.commit()
    except pyFG.exceptions.FailedCommit, e:
      pprint(e)

    d.close()


  def get_running_config(self, text=False):
    if text is False:
      return self.running_config
    else:
      return self.current_config


  def get_fg_section(self, section, vdom=None):
    if section in self.running_config:
      return self.running_config[section]
    return None

  def add_interface(self, **cfg):
    section='system interface'
    new_int = FortiConfig(config_type='edit', name=cfg['name'])
    name = cfg['name']
    del cfg['name']

    for e in cfg:
      new_int.set_param(e, cfg[e])

    self.d.candidate_config[section][name] = new_int

  def add_static_route(self, name=None, gateway = None, dst = None, device = None, vdom=None, comment = None):
    section = 'router static'
    new_r = FortiConfig(config_type='edit', name=name)

    if gateway: new_r.set_param('gateway', gateway)
    if comment: new_r.set_param('comment', comment)
    new_r.set_param('device', device)
    new_r.set_param('dst', dst)

    self.d.load_config(section)
    self.d.candidate_config[section][name] = new_r

  def add_service(self, name=None, tcp_portrange=None, udp_portrange=None, vdom=None, comment=None, 
      visibility=None, category='General'):

    section = 'firewall service custom'
    new_ser = FortiConfig(config_type='edit', name=name)

    new_ser.set_param('category', '"%s"' % category)

    if comment:
      new_ser.set_param('comment', '"%s"' % comment)
    if tcp_portrange:
      new_ser.set_param('tcp-portrange', quote(tcp_portrange))
    if udp_portrange:
      new_ser.set_param('udp-portrange', quote(udp_portrange))
    if visibility:
      new_ser.set_param('visibility', visibility)

    self.d.load_config(section)
    self.d.candidate_config[section][name] = new_ser

  # no type = subnet
  def add_address(self, name=None, subnet=None, fqdn=None, country=None, type=None, vdom=None, member=None, interface=None, comment=None):
    section = 'firewall address'

    new_addr = FortiConfig(config_type='edit', name=name)
    if comment:
      new_addr.set_param('comment', '"%s"' % comment)
    if country:
      type = 'geography'
      new_addr.set_param('country', country)
    if type:
      new_addr.set_param('type', type)
    if subnet:
      new_addr.set_param('subnet', subnet)
    if fqdn:
      new_addr.set_param('fqdn', fqdn)
    if member:
      new_addr.set_param('member', quote(member))
      section = 'firewall addrgrp'
    if interface:
      new_addr.set_param('associated-interface', quote(interface))

    self.d.load_config(section)
    self.d.candidate_config[section][name] = new_addr

  def add_fw_entry(self,
      vdom=None,
      name=None, srcintf=None, dstintf=None, srcaddr=None,
      dstaddr=None, service=None, nat="disable",
      action="accept", schedule='always', ippool=None, logtraffic=None, comments=""):

    section = 'firewall policy'
    new_fw = FortiConfig(config_type='edit', name=name)
    new_fw.set_param('srcintf', quote(srcintf))
    new_fw.set_param('dstintf', quote(dstintf))
    new_fw.set_param('srcaddr', quote(srcaddr))
    new_fw.set_param('dstaddr', quote(dstaddr))
    new_fw.set_param('service', quote(service))
    new_fw.set_param('schedule', quote(schedule))
    new_fw.set_param('nat', nat)
    new_fw.set_param('action', action)

    if logtraffic:
      new_fw.set_param('logtraffic', '"%s"' % logtraffic)
    if comments:
      new_fw.set_param('comments', '"%s"' % comments)

    self.d.load_config(section)
    self.d.candidate_config['firewall policy'][name] = new_fw

  def add_fw_vip(self, name = None, vdom='root', extip = None, 
      protocol = None,
      extintf = 'any', portforward=None, mappedip = None, 
      extport = None, mappedport = None, comment = None):

    if not name: return None
    section = 'firewall vip'
    new_vip = FortiConfig(config_type='edit', name=name)
    new_vip.set_param('extip', extip)
    new_vip.set_param('extintf', extintf)
    new_vip.set_param('mappedip', mappedip)
    if portforward == 'enable':
      new_vip.set_param('portforward', portforward)
      new_vip.set_param('extport', extport)
      new_vip.set_param('mappedport', mappedport)
    if protocol:
      new_vip.set_param('protocol', protocol)

    if comment:
      new_vip.set_param('comment', '"%s"' % comment)

    self.d.load_config(section)
    self.d.candidate_config['firewall vip'][name] = new_vip


  def del_entry(self, name, section):
    self.d.load_config(section)
    self.d.candidate_config[section].del_block(name)
    self.commit()
    

  def get_section(self, section):
    self.d.load_config(self.current_config)
    return self.d.candidate_config[section]

  def tftp_backup(self, tftpserver, filename=None, encrypt_password=None):
    if filename is None:
      filename="%s-%s.backup" % (self.fg, time.strftime("%d-%m-%Y_%H%M%S"))

    backup_cmd = "config global\nexecute backup full-config tftp %s %s" % (filename, tftpserver)
    if encrypt_password:
      backup_cmd="%s %s" % (backup_cmd, encrypt_password)

    self.d.execute_command(backup_cmd)
    self.d.close()
