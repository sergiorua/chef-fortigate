require_relative 'helper'

class Chef
  class Resource::FortigateVip < Resource::LWRPBase
    resource_name :fortigate_vip

    # Set the resource name
    self.resource_name = :fortigate_vip
    provides :fortigate_vip

    default_action :create
    provides :fortigate_vip
    actions [:create, :delete]

    attribute :vdom, kind_of: String, default: nil
    attribute :credentials, kind_of: String, default: '/opt/fortigate/creds.yaml'
    attribute :host, kind_of: String, required: true, default: nil

    attribute :extip, kind_of: String, default: nil
    attribute :extintf, kind_of: [String, Array], default: nil
    attribute :portforward, kind_of: [String, Array], default: nil
    attribute :mappedip, kind_of: String, required: true, default: nil
    attribute :extport, kind_of: [Integer, String]
    attribute :mappedport, kind_of: [Integer, String]
    attribute :protocol, kind_of: String, default: nil
    attribute :comment, kind_of: String, default: ''

    attr_writer :exists, :update, :type
  end

  def exists?
    !@exists.nil? && @exists
  end

end

class Chef
  class Provider::FortigateVip < Provider::LWRPBase
    include Fortigate::Helper

    def load_current_resource
      @current_resource ||= Resource::FortigateVip.new(new_resource.name)
      c = get_yaml(new_resource.name)

      @current_resource.exists = !c.nil?

      if not c.nil?
        @current_resource.vdom(c['vdom'])
        @current_resource.host(c['vdom'])
        @current_resource.credentials(c['credentials'])

        @current_resource.extip(c['extip'])
        @current_resource.extintf(c['extintf'])
        @current_resource.portforward(c['portforward'])
        @current_resource.mappedip(c['mappedip'])
        @current_resource.extport(c['extport'])
        @current_resource.mappedport(c['mappedport'])
        @current_resource.comment(c['comment'])
        @current_resource.protocol(c['protocol'])
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
        command "/opt/fortigate/add_fortigate.py -f #{file_path} -V #{@whyrun} || ( logger -t error 'Fortigate ERROR: VIP #{new_resource.name} failed to be added'; /bin/rm -f #{file_path} )"
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
