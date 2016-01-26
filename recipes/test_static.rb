fortigate_static "10" do
  host 'sbg-int-mx-fg-01'
  vdom 'internal'

  gateway '10.254.1.1'
  dst '8.8.8.8 255.255.255.255'
  device 'vlink01'
end
