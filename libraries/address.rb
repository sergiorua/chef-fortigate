require_relative 'helper'

class Chef
  class Resource::FortigateAddress < Resource::LWRPBase
    resource_name :fortigate_address

    # Set the resource name
    self.resource_name = :fortigate_address
    provides :fortigate_address

    default_action :create
    provides :fortigate_address
    actions [:create, :delete]

    attribute :subnet, kind_of: String, default: ''
    attribute :start_ip, kind_of: String, default: ''
    attribute :end_ip, kind_of: String, default: ''
    attribute :fqdn, kind_of: String, default: nil
    attribute :comment, kind_of: String, default: ''
    attribute :interface, kind_of: String, default: ''
    attribute :country, kind_of: String, default: ''
    attribute :type, kind_of: String, default: ''
    attribute :vdom, kind_of: String, default: nil
    attribute :host, kind_of: String, required: true, default: nil
    attribute :credentials, kind_of: String, default: '/opt/fortigate/creds.yaml'

    attr_writer :exists, :update, :type
  end

  def exists?
    !@exists.nil? && @exists
  end

end

class Chef
  class Provider::FortigateAddress < Provider::LWRPBase
    include Fortigate::Helper

    def load_current_resource
      @current_resource ||= Resource::FortigateAddress.new(new_resource.name)
      c = get_yaml(new_resource.name)

      @current_resource.exists = !c.nil?

      if not c.nil?
        @current_resource.vdom(c['vdom'])
        @current_resource.host(c['vdom'])
        @current_resource.credentials(c['credentials'])
        @current_resource.comment(c['comment'])
        @current_resource.interface(c['interface'])
        @current_resource.fqdn(c['fqdn'])
        @current_resource.start_ip(c['start_ip'])
        @current_resource.end_ip(c['end_ip'])

        if @new_resource.country != ''
          @new_resource.type('geography')
        elsif @new_resource.start_ip != ''
          @new_resource.type('iprange')
        else
          if @current_resource.subnet != @new_resource.subnet
            @current_resource.update = true
          end
        end

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
