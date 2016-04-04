require_relative 'helper'

class Chef
  class Resource::FortigatePolicy < Resource::LWRPBase
    resource_name :fortigate_policy

    # Set the resource name
    self.resource_name = :fortigate_policy
    provides :fortigate_policy

    default_action :create
    provides :fortigate_policy
    actions [:create, :delete]

    attribute :vdom, kind_of: String, default: nil
    attribute :host, kind_of: String, required: true, default: nil
    attribute :credentials, kind_of: String, default: '/opt/fortigate/creds.yaml'

    attribute :fwaction, kind_of: String, default: 'accept'
    attribute :dstaddr, kind_of: [String, Array], default: 'all'
    attribute :dstintf, kind_of: [String, Array], default: 'any'
    attribute :nat, kind_of: String, default: 'disable'
    attribute :schedule, kind_of: String, default: 'always'
    attribute :service, kind_of: Array, required: true
    attribute :srcaddr, kind_of: [String, Array], default: 'all'
    attribute :srcintf, kind_of: [String, Array], default: 'any'
    attribute :comments, kind_of: String, default: nil
    attribute :ippool, kind_of: String, default: nil
    attribute :logtraffic, kind_of: String, default: nil

    attribute :auth_redirect_addr, kind_of: String, default: nil
    attribute :auth_cert, kind_of: String, default: nil

    attribute :profile_protocol_options, kind_of: String, default: nil
    attribute :ips_sensor, kind_of: String, default: nil
    attribute :utm_status, kind_of: String, default: nil

    attr_writer :exists, :update, :type, :whyrun
  end

  def exists?
    !@exists.nil? && @exists
  end

end

class Chef
  class Provider::FortigatePolicy < Provider::LWRPBase
    include Fortigate::Helper

    def load_current_resource
      @current_resource ||= Resource::FortigatePolicy.new(new_resource.name)
      c = get_yaml(new_resource.name)

      @current_resource.exists = !c.nil?

      if not c.nil?
        @current_resource.vdom(c['vdom'])
        @current_resource.host(c['vdom'])
        @current_resource.credentials(c['credentials'])

        @current_resource.fwaction(c['fwaction'])
        @current_resource.dstaddr(c['dstaddr'])
        @current_resource.dstintf(c['dstintf'])
        @current_resource.nat(c['nat'])
        @current_resource.schedule(c['schedule'])
        @current_resource.service(c['service'])
        @current_resource.srcaddr(c['srcaddr'])
        @current_resource.srcintf(c['srcintf'])
        @current_resource.comments(c['comments'])
        @current_resource.ippool(c['ippool'])
        @current_resource.logtraffic(c['logtraffic'])

        @current_resource.logtraffic(c['auth_redirect_addr'])
        @current_resource.logtraffic(c['auth_cert'])
        @current_resource.logtraffic(c['profile_protocol_options'])
        @current_resource.logtraffic(c['ips_sensor'])
        @current_resource.logtraffic(c['utm_status'])
      end

      if Chef::Config[:why_run] or node.include?('is_docker')
        @whyrun = " -x "
      else
        @whyrun = ""
      end

      @current_resource
    end

    def whyrun_supported?
      true
    end

    action(:create) do
      file_path = save_path(new_resource)

      directory ::File.dirname(file_path) do
        mode 0700
        recursive true
      end

      content = to_yaml(new_resource)

      execute "fortigate-update-#{new_resource.name}" do
        command "/opt/fortigate/add_fortigate.py -f #{file_path} -V #{@whyrun}"
        action :nothing
        not_if { node.include?('is_docker') }
      end

      file file_path do
        content content
        notifies :run, "execute[fortigate-update-#{new_resource.name}]", :delayed
      end
    end

    action(:delete) do
      file_path = save_path(new_resource)

      if ::File.exists?(file_path)
        system("/opt/fortigate/del_fortigate.py -V -f #{file_path} #{@whyrun}")
        ::File.unlink(file_path) if $?.exitstatus == 0
      end
    end

  end
end
