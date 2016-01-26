%w{zlib-devel patch gcc gcc-c++ python-pip python-devel PyYAML python-paramiko}.each do |pkg|
  package pkg do
    action :install
  end
end

execute "install-pyfg" do
  command "pip install pyfg"
  not_if { ::File.exists?("/usr/lib/python2.6/site-packages/pyFG") or ::File.exists?("/usr/lib/python2.7/site-packages/pyFG") }
end

directory "/opt/fortigate" do
  mode 0700
  owner "root"
  group "root"
end

directory node['fortigate']['store_path'] do
  mode 0700
  owner "root"
  group "root"
  recursive true
end

%W{del_fortigate.py add_fortigate.py sbfg.py}.each do |x|
  cookbook_file "/opt/fortigate/#{x}" do
    source x
    mode 0700
    owner "root"
    group "root"
  end
end
