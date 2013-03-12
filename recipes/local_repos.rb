
ruby_block 'repository[locals]' do
  block do
    key_file = File.join(node[:repository][:base], "#{node[:repository][:pgp][:email]}.gpg.key")
    e_key = Chef::Resource::Execute.new('Add local repository key', run_context)
    e_key.action :nothing
    e_key.command "apt-key add #{key_file}"
    e_key.not_if do
      installed_ids = %x{apt-key finger}.split("\n").find_all{|s| s.include?('Key finger') }.map(&:strip).sort
      key_ids = %x{sudo -i gpg --with-fingerprint #{key_file}}.split("\n").find_all{|s| s.include?('Key finger') }.map(&:strip).sort
      (installed_ids & key_ids).sort == key_ids.sort
    end
    e_key.run_action(:run)
    node[:repository][:install_local_repos].each do |name|
      Chef::Log.info "Adding local repository: #{name}"
      repo = run_context.resource_collection.lookup("repository[#{name}]")
      a_repo = Chef::Resource::AptRepository.new(name, run_context)
      a_repo.action :nothing
      a_repo.uri "file://#{node[:repository][:base]}"
      a_repo.distribution repo.codename
      a_repo.components [repo.component]
      a_repo.run_action(:add)
    end
  end
  action :nothing
end

ruby_block 'repository[locals] notifier' do
  block{ true }
  notifies :create, 'ruby_block[repository[locals]]', :delayed
end
