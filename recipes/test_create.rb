fortigate_address "Block_UA" do
  host 'fortigate'
  vdom 'internal'
  country "UA"
  action :create
end

fortigate_address "sergiotst001" do
  host 'fortigate'
  vdom 'internal'
  subnet "192.168.1.1 255.255.255.255"
  interface 'port1'
  action :create
end

fortigate_address "sergiotst002" do
  host 'fortigate'
  vdom 'internal'
  subnet "192.168.1.2 255.255.255.255"
  action :create
end

fortigate_addrgrp "testgroup01" do
  host 'fortigate'
  vdom 'internal'
  member ['sergiotst001', 'sergiotst002']
  action :create
end

fortigate_service "http-8181" do
  host 'fortigate'
  vdom 'internal'
  tcp "8181"
  action :create
end

fortigate_service "web_ports" do
  host 'fortigate'
  vdom 'internal'
  tcp ["80", "443"]
  action :create
end

fortigate_policy '666' do
  host      'fortigate'
  vdom      'internal'
  fwaction  'accept'
  nat       'disable'
  dstaddr   'all'
  dstintf   ['port3', 'port4']
  srcaddr   'testgroup01'
  srcintf   'any'
  service   ['web_ports']
  comments  'Tested from the Kitchen'
  action    :create
end
