def load_current_resource
  new_resource.codename new_resource.name unless new_resource.codename
end

action :create do

  repository_files new_resource.codename do
    action :nothing
  end

  f = file ::File.join(node[:repository][:base], 'conf', "#{new_resource.codename}.json") do
    mode 0644
    content JSON.pretty_generate(node.run_state[:repository_db][new_resource.codename])
    notifies :build, "repository_files[#{new_resource.codename}]", :immediately
  end

  new_resource.updated_by_last_action(f.updated_by_last_action?)
end

action :delete do
  path = ::File.join(node[:repository][:base], 'conf', "#{new_resource.codename}.json")
  if(::File.exists?(path))
    file path do
      action :delete
    end
    new_resource.updated_by_last_action(true)
  end
end
