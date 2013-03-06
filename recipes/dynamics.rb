include_recipe 'repository::default'

repos = []

if(node[:repository][:data_bag_configs])
  repos += search(node[:repository][:data_bag], 'id:* AND (NOT id:gpg)').map do |dbi|
    Mash.new(dbi.raw_data)
  end
end

if(node[:repository][:repos])
  repos += node[:repository][:repos]
end

local_repos = []

repos.each do |rc|
  repository rc[:name] do
    codename rc[:codename]
    architecture rc[:architecture]
    label rc[:label]
    description rc[:description]
    component_label rc[:component_label]
    component_description rc[:component_description]
    multi_version rc[:multi_version] unless rc[:multi_version].nil?
  end
  local_repos << rc[:name] if rc[:enable_locally]
end

node.set[:repository][:install_local_repos] = node[:repository][:install_local_repos] | local_repos
