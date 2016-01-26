fortigate_vip "sergiovip001" do
  host 'sbg-int-lc-fg-01'
  vdom 'root'
  extip '172.16.159.84'
  extintf "any"
  portforward 'enable'
  mappedip "10.254.10.6"
  extport 443
  mappedport 443
end
