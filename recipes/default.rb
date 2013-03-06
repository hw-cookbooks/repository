include_recipe 'apache2'

apache_site '000-default' do
  enable false
end

node[:repository][:packages].each do |pkg|
  package pkg
end

directory node[:repository][:base] do
  recursive true
end

unless(node[:repository][:do_not_sign])
  include_recipe 'repository::keys'
end

%w(dynamics local_repos).each do |recipe|
  include_recipe "repository::#{recipe}"
end

apache_site 'repository.conf'
