if(node[:repository][:pgp_data_bag])
  if(node[:repository][:pgp_data_bag] == true)
    pgp_bag = data_bag_item(node[:repository][:data_bag], 'pgp')
  else
    pgp_bag = Chef::EncryptedDataBagItem.load(
      node[:repository][:data_bag], 'pgp'
    )
  end
  raise 'Failed to locate PGP information' unless pgp_bag
#  pgp_bag = Mash.new(pgp_bag.raw_data)
  key_path = File.join(node[:repository][:base], "#{pgp_bag[:email]}.gpg.key")

  node.set[:repository][:pgp][:email] = pgp_bag[:email]

  ruby_block 'Repository: import packaging key' do
    block do
      require 'tempfile'
      Tempfile.open('/tmp/') do |file|
        file.write pgp_bag[:private]
        file.close
        cmd = Chef::Resource::Execute.new("sudo -u #{node[:gpg][:user]} -i gpg --import #{file.path}", node.run_context)
        cmd.action :nothing
        cmd.cwd '/root'
        cmd.environment 'GNUPGHOME' => node[:repository][:gnupg_home]
        cmd.run_action(:run)
      end
    end
    not_if "sudo -u #{node[:gpg][:user]} -i GNUPGHOME=\"#{node[:repository][:gnupg_home]}\" gpg --list-secret-keys --fingerprint #{pgp_bag[:email]} | egrep -qx '.*Key fingerprint = #{pgp_bag[:fingerprint]}'"
  end

  file key_path do
    mode 0644
    owner 'nobody'
    group 'nogroup'
    content pgp_bag[:public]
  end
else
  include_recipe 'gpg'
  
  key_path = File.join(node[:repository][:base], "#{node[:gpg][:name][:email]}.gpg.key")
  node.set[:repository][:pgp][:email] = node[:gpg][:name][:email]

  execute "sudo -u #{node[:gpg][:user]} -i gpg --armor --export #{node[:gpg][:name][:real]} > #{key_path}" do
    creates key_path
  end

  file key_path do
    mode 0644
    owner 'nobody'
    group 'nogroup'
  end
end
