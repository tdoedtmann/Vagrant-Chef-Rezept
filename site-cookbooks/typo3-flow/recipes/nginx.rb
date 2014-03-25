group node[:app][:group] do
  append true
  gid 80
  members 'vagrant'
end

user node[:app][:user] do
  uid 80
  gid 80
  system true
  home '/www'
  shell '/bin/bash'
  supports :manage_home=>false
end

user 'vagrant' do
  gid 80
  action :manage
end


# /var/www - make sure it exists and has correct permissions
directory node[:system][:www_root] do
  owner node[:app][:user]
  group node[:app][:group]
  mode 00775
  recursive true
  not_if "test -d #{node[:system][:www_root]}"
end


#
# Nginx
#
include_recipe 'nginx'
include_recipe 'nginx::http_realip_module'
include_recipe 'nginx::http_gzip_static_module'
include_recipe 'nginx::http_spdy_module'

# prepare generic configs to include inside vhost configurations
%w{ common security static }.each do |conf|
  template "#{node['nginx']['dir']}/include-#{conf}.conf" do
    source "nginx/include-#{conf}.conf.erb"
    notifies :reload, 'service[nginx]'
  end
end

# disable default.conf from nginx/conf.d/default.conf
nginx_default_vhost = "#{node['nginx']['dir']}/conf.d/default.conf"
nginx_default_vhost_disabled = "#{node['nginx']['dir']}/conf.d/default.conf.disabled"
execute "disable_nginx_default.conf_vhost" do
  command "mv #{nginx_default_vhost} #{nginx_default_vhost_disabled}"
  user 'root'
  creates nginx_default_vhost_disabled
  notifies :reload, 'service[nginx]'
end
