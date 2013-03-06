include_recipe 'repository::default'

directory node[:repository][:incoming][:directory] do
  recursive true
end

repository node[:repository][:incoming][:name] do
  codename node[:repository][:incoming][:codename]
  architecture node[:repository][:incoming][:architecture]
  label node[:repository][:incoming][:label]
  description node[:repository][:incoming][:description]
  multi_version node[:repository][:incoming][:multi_version]
end

if(node[:repository][:incoming][:enable_locally])
  node.set[:repository][:install_local_repos] = node[:repository][:install_local_repos] | [node[:repository][:incoming][:name]]
end

# NOTE: Use delayed notifier pattern to move auto package
#       installation to end of run so packages added after
#       this point in the resource collection are picked
#       up (unless packages are added via some delayed notification
#       and at that point we just don't care. converge the 
#       node again.)
ruby_block 'Repository - Incoming package notifier' do
  block{ true }
  notifies :create, 'ruby_block[Repository - Process incoming]', :delayed
end

ruby_block 'Repository - Process incoming' do
  action :nothing
  block do
    Dir.glob(File.join(node[:repository][:incoming][:directory], '*.deb')).each do |deb_file|
      r = Chef::Resource::Repository.new(deb_file, run_context)
      r.action :nothing
      r.repository node[:repository][:incoming][:name]
      r.run_action(:add)
    end
  end
  only_if do
    File.directory?(node[:repository][:incoming][:directory])
  end
end
