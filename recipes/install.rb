include_recipe "java"

include_recipe "hops::wrap"

my_ip = my_private_ip()

group node.hive2.group do
  action :create
  not_if "getent group #{node.hive2.group}"
end

user node.hive2.user do
  home "/home/#{node.hive2.user}"
  action :create
  system true
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node.hive2.user}"
end

group node.hive2.group do
  action :modify
  members ["#{node.hive2.user}"]
  append true
end


package_url = "#{node.hive2.url}"
base_package_filename = File.basename(package_url)
cached_package_filename = "/tmp/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "#{node.hive2.user}"
  mode "0644"
  action :create_if_missing
end

# Extract Hive
hive_downloaded = "#{node.hive2.home}/.hive_extracted_#{node.hive2.version}"

bash 'extract-hive' do
        user "root"
        group node.hive2.group
        code <<-EOH
                set -e
                tar zxf #{cached_package_filename} -d /tmp
                mv /tmp/hive-server-#{node.hive2.version} #{node.hive2.dir}
                # remove old symbolic link, if any
                rm -f #{node.hive2.base_dir}
                ln -s #{node.hive2.home} #{node.hive2.base_dir}
                chown -R #{node.hive2.user}:#{node.hive2.group} #{node.hive2.home}
                chown -R #{node.hive2.user}:#{node.hive2.group} #{node.hive2.base_dir}
                touch #{hive_downloaded}
                chown -R #{node.hive2.user}:#{node.hive2.group} #{hive_downloaded}
        EOH
     not_if { ::File.exists?( "#{hive_downloaded}" ) }
end




