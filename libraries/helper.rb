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
      type = new_resource.class.name.gsub('Chef::Resource::Fortigate','').downcase
      vdom=new_resource.vdom.nil? ? 'global' : new_resource.vdom
      fname = "#{new_resource.name}.yaml"
    
      fpath = ::File.join(node['fortigate']['store_path'], new_resource.host, vdom, type, fname)
      return fpath
    end

    def to_yaml(r)
      if r.class.name.end_with? 'FortigateAddress'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials, 
            'comment' => r.comment, 
            'interface' => r.interface}
        if r.subnet
          s['subnet'] = r.subnet
        elsif r.country != ''
          s["country"] = r.country
          s['type'] = 'geography'
        elsif r.fqdn != ''
          s['type'] = 'fqdn'
          s['fqdn'] = r.fqdn
        elsif r.start_ip != ''
          s['type'] = 'iprange'
          s['start_ip'] = r.start_ip
          s['end_ip'] = r.end_ip
        else
          Chef::Log.error("Unknown entry for address")
          return
        end
      elsif r.class.name.end_with? 'FortigateAddrgrp'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "member" => r.member, "credentials" => r.credentials, 'comment' => r.comment}
      elsif r.class.name.end_with? 'FortigateService'
        s = {"host" => r.host, 
              "vdom" => r.vdom, 
              "name" => r.name, 
              "tcp_portrange" => r.tcp, 
              "udp_portrange" => r.udp, 
              "credentials" => r.credentials, 
              "category" => r.category, 
              'visibility' => r.visibility,
              'comment' => r.comment}
      elsif r.class.name.end_with? 'FortigatePolicy'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
             "srcintf"  => r.srcintf, 
             "dstintf"  => r.dstintf, 
             "srcaddr"  => r.srcaddr, 
             "dstaddr"  => r.dstaddr, 
             "service"  => r.service, 
             "status"  => r.status, 
             "nat"      => r.nat, 
             "schedule" => r.schedule,
             "ippool"   => r.ippool,
             "fwaction" => r.fwaction, 
             "logtraffic" => r.logtraffic, 
             "logtraffic_start" => r.logtraffic_start, 
             "auth_redirect_addr" => r.auth_redirect_addr, 
             "auth_cert" => r.auth_cert, 
             "profile_protocol_options" => r.profile_protocol_options, 
             "ips_sensor" => r.ips_sensor, 
             "utm_status" => r.utm_status, 
             "groups" => r.groups, 
             "comments" => r.comments}
      elsif r.class.name.end_with? 'FortigateVip'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
              "extip"   => r.extip,
              "extintf" => r.extintf,
              "mappedip" => r.mappedip,
              "portforward" => r.portforward,
              "extport"   => r.extport,
              "mappedport"  => r.mappedport,
              "protocol"  => r.protocol,
              "comment" => r.comment }
      elsif r.class.name.end_with? 'FortigateStatic'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
              "device" => r.device,
              "dst" => r.dst,
              "gateway" => r.gateway,
              "comment" => r.comment }
      elsif r.class.name.end_with? 'FortigateUsergroup'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
              "group_members" => r.member
            }
      elsif r.class.name.end_with? 'FortigateUser'
        s = {"host" => r.host, "vdom" => r.vdom, "name" => r.name, "credentials" => r.credentials,
              "type" => r.type,
              "passwd" => r.passwd,
              "email" => r.email,
              "status" => r.status
        }
      end
      return YAML.dump(s)
    end

  end
end
