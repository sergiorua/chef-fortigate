require 'yaml'

module Fortigate
  module Helper

    def get_yaml(name)
      fpath=::File.join(node['fortigate']['store_path'], name)

      if not ::File.exists?(fpath)
        return nil
      end

      return YAML.load_file(fpath)
    end

    # /opt/fortigate/entries.d/<host>/<vdom>/<address>/name.yaml
    def save_path(new_resource)
      if new_resource.class.name.include? 'FortigateAddress'
        type = 'address'
      elsif new_resource.class.name.include? 'FortigateAddrgrp'
        type = 'addrgrp'
      elsif new_resource.class.name.include? 'FortigateService'
        type = 'service'
      elsif new_resource.class.name.include? 'FortigatePolicy'
        type = 'policy'
      elsif new_resource.class.name.include? 'FortigateVip'
        type = 'vip'
      elsif new_resource.class.name.include? 'FortigateStatic'
        type = 'static'
      else
        fail "Unknown class"
      end
      vdom=new_resource.vdom.nil? ? 'global' : new_resource.vdom
      fname = "#{new_resource.name}.yaml"
    
      fpath = ::File.join(node['fortigate']['store_path'], new_resource.host, vdom, type, fname)
      return fpath
    end

    def to_yaml(r)
      if r.class.name.include? 'FortigateAddress'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials, 'comment' => r.comment, 'interface' => r.interface}
        if r.country != ''
          s["country"] = r.country
          s['type'] = 'geography'
        else
          s['subnet'] = r.subnet
        end
      elsif r.class.name.include? 'FortigateAddrgrp'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "member" => r.member, "credentials" => r.credentials, 'comment' => r.comment}
      elsif r.class.name.include? 'FortigateService'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "tcp_portrange" => r.tcp, "udp_portrange" => r.udp, "credentials" => r.credentials, "category" => r.category, 'comment' => r.comment}
      elsif r.class.name.include? 'FortigatePolicy'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
             "srcintf"  => r.srcintf, 
             "dstintf"  => r.dstintf, 
             "srcaddr"  => r.srcaddr, 
             "dstaddr"  => r.dstaddr, 
             "service"  => r.service, 
             "nat"      => r.nat, 
             "schedule" => r.schedule,
             "ippool"   => r.ippool,
             "fwaction" => r.fwaction, 
             "logtraffic" => r.logtraffic, 
             "comments" => r.comments}
      elsif r.class.name.include? 'FortigateVip'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
              "extip"   => r.extip,
              "extintf" => r.extintf,
              "mappedip" => r.mappedip,
              "portforward" => r.portforward,
              "extport"   => r.extport,
              "mappedport"  => r.mappedport,
              "protocol"  => r.protocol,
              "comment" => r.comment }
      elsif r.class.name.include? 'FortigateStatic'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
              "device" => r.device,
              "dst" => r.dst,
              "gateway" => r.gateway,
              "comment" => r.comment }
            
      end
      return YAML.dump(s)
    end

  end
end
