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

if(File.directory?(node[:repository][:incoming][:directory]))
  Dir.glob(File.join(node[:repository][:incoming][:directory], '*.deb')).each do |deb_file|
    repository_package deb_file do
      repository node[:repository][:incoming][:name]
    end
  end
end

if(node[:repository][:incoming][:enable_locally])
  node.set[:repository][:install_local_repos] = node[:repository][:install_local_repos] | [node[:repository][:incoming][:name]]
end
