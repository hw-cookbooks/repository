require 'tmpdir'
require 'time'

def load_current_resource
  new_resource.codename new_resource.name unless new_resource.codename
end

action :build do
  apache2 = new_resource.run_context.resource_collection.lookup('service[apache2]')
  stopper = service 'repository-apache-stopper' do
    service_name apache2.service_name
    action :nothing
  end
  stopper.run_action(:stop)

  conf_file = ::File.join(node[:repository][:base], 'conf', "#{new_resource.codename}.json")  
  pool_dir = ::File.join(node[:repository][:base], 'pool', new_resource.codename)
  dist_dir = ::File.join(node[:repository][:base], 'dists', new_resource.codename)

  config = Mash.new(JSON.load(::File.read(conf_file)))
  processed_archs = []

  # Generate package files
  config[:components].each do |component, component_vals|
    component_dir = ::File.join(dist_dir, component)
    component_config = component_vals[:meta]
    component_vals[:architectures].each do |arch, files_deb|
      processed_archs << arch
      arch_dir = ::File.join(component_dir, "binary-#{arch}")
      Dir.mktmpdir do |t_dir|
        t_arch_dir = ::File.join(t_dir, 'dists', new_resource.codename, component, "binary-#{arch}")
        t_pool_dir = ::File.join(t_dir, 'pool', new_resource.codename)
        deb_path = "pool/#{new_resource.codename}"
        # create stub dirs
        FileUtils.mkdir_p(t_arch_dir)
        FileUtils.mkdir_p(t_pool_dir)
        # link required debs
        files_deb.each do |deb_file|
          ::File.link(deb_file, ::File.join(t_pool_dir, ::File.basename(deb_file)))
        end
        # make package files!
        if(component_config[:multi_version])
          multi = ' -m'
        end
        pack = execute "create Package file for #{new_resource.codename} - #{component} - #{arch}" do
          command "dpkg-scanpackages#{multi} #{deb_path} > Packages"
          cwd t_dir
          action :nothing
        end
        pack.run_action(:run)
        FileUtils.mv(::File.join(t_dir, 'Packages'), ::File.join(arch_dir, 'Packages'))
      end

      # Make compressed Package
      execute "compress Package file for #{new_resource.codename} - #{component} - #{arch}" do
        command "gzip -c Packages > Packages.gz"
        cwd arch_dir
      end

      # Arch release file
      template ::File.join(arch_dir, 'Release') do
        source 'release.erb'
        cookbook 'repository'
        mode 0644
        variables(
          :component => component,
          :codename => new_resource.codename,
          :arch => arch,
          :label => component_config[:label],
          :description => component_config[:description]
        )
      end
    end
  end

  # Component release file
  template ::File.join(dist_dir, 'Release') do
    source 'release.erb'
    cookbook 'repository'
    mode 0644
    # TODO: Replace files with #lazy for chef11 and add delayed evaluator cookbook
    # for chef10
    variables(
      :components => config[:components].keys,
      :codename => new_resource.codename,
      :archs => processed_archs.uniq,
      :files => lambda{ RepositoryHelper.generate_checksums(dist_dir) },
      :label => config[:meta][:label],
      :description => config[:meta][:description]
    )
    notifies :run, "execute[Release.gpg - #{new_resource.codename}]", :immediately
    notifies :run, "execute[InRelease - #{new_resource.codename}]", :immediately
  end
  
  execute "Release.gpg - #{new_resource.codename}" do
    command "sudo -i gpg -ba #{::File.join(dist_dir, 'Release')} && mv #{::File.join(dist_dir, 'Release.asc')} #{::File.join(dist_dir, 'Release.gpg')}"
    action :nothing
    user "root"
    cwd "/root"
    environment "GNUPGHOME" => node['repository']['gnupg_home']
    not_if do
      node[:repository][:do_not_sign]
    end
  end

  execute "InRelease - #{new_resource.codename}" do
    command "sudo -i gpg --clearsign #{::File.join(dist_dir, 'Release')} && mv #{::File.join(dist_dir, 'Release.asc')} #{::File.join(dist_dir, 'InRelease')}"
    action :nothing
    user "root"
    cwd "/root"
    environment "GNUPGHOME" => node['repository']['gnupg_home']
    not_if do
      node[:repository][:do_not_sign]
    end
  end

  service 'repository-apache-starter' do
    service_name apache2.service_name
    action :start
  end
end
