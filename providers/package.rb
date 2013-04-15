def load_current_resource
  new_resource.path new_resource.name unless new_resource.path
  @repo = new_resource.run_context.resource_collection.lookup("repository[#{new_resource.repository}]")
  @architecture = %x{dpkg-deb -f #{new_resource.path} Architecture}.strip
end

action :add do
  p_arch = @architecture
  archs = @repo.architecture
  codename = @repo.codename
  component = @repo.component
  pool_dir = ::File.join(node[:repository][:base], 'pool', codename)
  conf_path = ::File.join(node[:repository][:base], 'conf', "#{codename}.json")

  directory pool_dir do
    recursive true
  end
  pool_file = ::File.join(pool_dir, ::File.basename(new_resource.path))
  unless(::File.exists?(pool_file))
    FileUtils.cp(new_resource.path, pool_file)
    unless(node[:repository][:do_not_sign])
      begin
        cmd = Mixlib::ShellOut.new(
          "sudo -i debsigs --sign=origin #{pool_file}",
          user: 'root',
          cwd: '/root',
          environment: {
            'GNUPGHOME' => node[:repository][:gnupg_home]
          }
        )
        cmd.run_command
        cmd.error!
      rescue Errno::EACCESS, Errno::ENOENT, Mixlib::ShellOut::CommandTimeout
        raise "Failed to sign package: #{pool_file}"
      end
    end
  end
  (p_arch == 'all' ? archs : (archs & Array(p_arch))).each do |arch|
    unless(node.run_state[:repository_db][codename][:components][component][:architectures][arch].include?(pool_file))
      node.run_state[:repository_db][codename][:components][component][:architectures][arch] << pool_file
      node.run_state[:repository_db][codename][:components][component][:architectures][arch].sort!
      new_resource.updated_by_last_action(true)
    end
  end
end

action :remove do
  path = ::File.join(node[:repository][:base], 'pool', codename, ::File.basename(resource.path))
  if(::File.exists?(path))
    file path do
      action :delete
    end
    new_resource.updated_by_last_action(true)
  end
end
