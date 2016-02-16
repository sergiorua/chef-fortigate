fortigate_static "10" do
  host 'fortigate'
  vdom 'internal'

  gateway '10.254.1.1'
  dst '8.8.8.8 255.255.255.255'
  device 'vlink01'
end
