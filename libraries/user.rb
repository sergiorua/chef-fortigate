require_relative 'helper'

class Chef
  class Resource::FortigateUser < Resource::LWRPBase
    resource_name :fortigate_user

    # Set the resource name
    self.resource_name = :fortigate_user

    default_action :create
    provides :fortigate_user
    actions [:create, :delete]

    attribute :vdom, kind_of: String, default: nil
    attribute :credentials, kind_of: String, default: '/opt/fortigate/creds.yaml'
    attribute :host, kind_of: String, required: true, default: nil

    attribute :type, kind_of: String, default: 'password'
    attribute :email, kind_of: String, default: nil
    attribute :passwd, kind_of: String, default: nil

    attr_writer :exists
  end

  def exists?
    !@exists.nil? && @exists
  end

end

class Chef
  class Provider::FortigateUser < Provider::LWRPBase
    include Fortigate::Helper

    def load_current_resource
      @current_resource ||= Resource::FortigateUser.new(new_resource.name)
      c = get_yaml(new_resource.name)

      @current_resource.exists = !c.nil?

      if not c.nil?
        @current_resource.vdom(c['vdom'])
        @current_resource.host(c['vdom'])
        @current_resource.credentials(c['credentials'])

        @current_resource.type(c['type'])
        @current_resource.email(c['email'])
        @current_resource.passwd(c['passwd'])
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
