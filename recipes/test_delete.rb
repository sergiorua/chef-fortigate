fortigate_address "Block_UA" do
  host 'sbg-int-lc-fg-03'
  vdom 'internal'
  country "UA"
  action :delete
end

fortigate_address "sergiotst001" do
  host 'sbg-int-lc-fg-03'
  vdom 'internal'
  subnet "192.168.1.1 255.255.255.255"
  interface 'port1'
  action :delete
end

fortigate_address "sergiotst002" do
  host 'sbg-int-lc-fg-03'
  vdom 'internal'
  subnet "192.168.1.2 255.255.255.255"
  action :delete
end

fortigate_addrgrp "testgroup01" do
  host 'sbg-int-lc-fg-03'
  vdom 'internal'
  member ['sergiotst001', 'sergiotst002']
  action :delete
end

fortigate_service "http-8181" do
  host 'sbg-int-lc-fg-03'
  vdom 'internal'
  tcp "8181"
  action :delete
end

fortigate_service "web_ports" do
  host 'sbg-int-lc-fg-03'
  vdom 'internal'
  tcp ["80", "443"]
  action :delete
end

fortigate_policy '666' do
  host      'sbg-int-lc-fg-03'
  vdom      'internal'
  fwaction  'accept'
  nat       'disable'
  dstaddr   'all'
  dstintf   ['port3', 'port4']
  srcaddr   'testgroup01'
  srcintf   'any'
  service   ['web_ports']
  comments  'Tested from the Kitchen'
  action    :delete
end
