def load_current_resource
  node.run_state[:repository_db] ||= Mash.new
  node.run_state[:repository_meta] ||= Mash.new
  new_resource.type new_resource.type.to_sym
  new_resource.component new_resource.name unless new_resource.component
  new_resource.architecture(
    [new_resource.architecture].flatten.map(&:to_s)
  )
  %w(amd64 i386).each do |arch_check|
    unless(new_resource.architecture.include?(arch_check))
      new_resource.architecture.push(arch_check)
      Chef::Log.warn "Apt repository requires #{arch_check} architecture. Automatically added."
    end
  end
  node.run_state[:repository_db][new_resource.codename] ||= Mash.new
  data = Mash.new(
    :meta => Mash.new(
      :label => new_resource.label,
      :description => new_resource.description
    ),
    :components => Mash.new(
      new_resource.component => Mash.new(
        :architectures => Mash.new,
        :meta => Mash.new(
          :label => new_resource.component_label || new_resource.label,
          :description => new_resource.component_description || new_resource.description,
          :multi_version => new_resource.multi_version
        )
      )
    )
  )
  node.run_state[:repository_db][new_resource.codename] = Chef::Mixin::DeepMerge.merge(
    node.run_state[:repository_db][new_resource.codename], data
  )
  new_resource.architecture.each do |arch|
    node.run_state[:repository_db][new_resource.codename][:components][new_resource.component][:architectures][arch] = []
  end
end

action :create do
  %w(conf dists pool).each do |dir|
    directory ::File.join(node[:repository][:base], dir) do
      recursive true
    end
  end
  new_resource.architecture.each do |arch|
    d = directory ::File.join(node[:repository][:base], 'dists', new_resource.codename, new_resource.component, "binary-#{arch}") do
      recursive true
    end
    new_resource.updated_by_last_action(true) if d.updated_by_last_action?
  end
  directory ::File.join(node[:repository][:base], 'pool', new_resource.codename) do
    recursive true
  end

  # Push our configuration building on the end of the node's run context so we are
  # at least close to the end of the run
  c = Chef::Resource::RepositoryConfiguration.new(new_resource.codename, new_resource.run_context)
  new_resource.run_context.resource_collection << c
end

action :remove do
  if(::File.exists?(::File.join(node[:repository][:base], 'conf', "#{new_resource.codename}.json")))
    directory ::File.join(node[:repository][:base], 'dists', new_resource.codename, new_resource.name) do
      action :delete
      recursive true
    end
    directory ::File.join(node[:repository][:base], 'pool', new_resource.codename) do
      action :delete
      recursive true
      only_if do
        Dir.new(
          ::File.join(node[:repository][:base], 'pool', new_resource.codename)
        ).find_all do |path|
          %w(. ..).include?(path)
        end.empty?
      end
    end
    repository_configuration new_resource.codename do
      action :delete
      only_if do
        Dir.new(
          ::File.join(node[:repository][:base], 'pool', new_resource.codename)
        ).find_all do |path|
          %w(. ..).include?(path)
        end.empty?
      end
    end
    new_resource.updated_by_last_action(true)
  end
end
