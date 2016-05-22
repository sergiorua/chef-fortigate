require_relative 'helper'

class Chef
  class Resource::FortigateAddrgrp < Resource::LWRPBase
    resource_name :fortigate_addrgrp

    # Set the resource name
    self.resource_name = :fortigate_addrgrp
    provides :fortigate_addrgrp

    default_action :create
    provides :fortigate_addrgrp
    actions [:create, :delete]

    attribute :comment, kind_of: String, default: ''
    attribute :member, kind_of: Array, default: []
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
  class Provider::FortigateAddrgrp < Provider::LWRPBase
    include Fortigate::Helper

    def load_current_resource
      @current_resource ||= Resource::FortigateAddrgrp.new(new_resource.name)


      c = get_yaml(new_resource.name)

      @current_resource.exists = !c.nil?

      if not c.nil?
        @current_resource.vdom(c['vdom'])
        @current_resource.host(c['vdom'])
        @current_resource.credentials(c['credentials'])

        if @current_resource.member != @new_resource.member
          @current_resource.update = true
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
        command "/opt/fortigate/add_fortigate.py -f #{file_path} -V #{@whyrun} || ( logger -t error 'Fortigate ERROR: Address Group #{new_resource.name} failed to be added'; /bin/rm -f #{file_path} )"
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
