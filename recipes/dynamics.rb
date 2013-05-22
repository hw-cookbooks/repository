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

valid_attributes = %w(
  type component codename architecture
  label description component_label
   component_description multi_version
)

repos.each do |rc|
  repository rc[:name] do
    rc.each do |key, value|
      next unless valid_attributes.include?(key.to_s)
      self.send(key, value)
    end
  end
  local_repos << rc[:name] if rc[:enable_locally]
end

node.set[:repository][:install_local_repos] = node[:repository][:install_local_repos] | local_repos
