flow_data = node['app']['flow']

vhost_name = flow_data['vhost_base_name'] # e.g. neos
vhost_dir = "#{node['system']['www_root']}/#{vhost_name}" # e.g. /var/www/neos

service 'nginx' do
  action :nothing
end

# Common include*.conf file(s) used in Neos-related vhosts
template "#{node['nginx']['dir']}/include-flow-rewrites.conf" do
  source 'nginx/include-flow-rewrites.erb'
end

#
# Neos vhost
#
template "#{node['nginx']['dir']}/sites-available/#{vhost_name}" do
  source 'nginx/site-flow.erb'
  cookbook 'typo3-flow'
  variables({
      :vhost_name => vhost_name
  })
  notifies :reload, 'service[nginx]'
end
nginx_site vhost_name

# also add neos hosts to /etc/hosts file, so you can connect to them from localhost
execute "echo #{node['ipaddress']} #{vhost_name} #{vhost_name}.dev #{vhost_name}.test >> /etc/hosts" do
  not_if "cat /etc/hosts | grep #{vhost_name}.test"
end


#
# Neos db
#
mysql_database flow_data['db']['name'] do
  connection    node['app']['mysql_connection_info']
  action :create
end
mysql_database_user flow_data['db']['user'] do
  connection    node['app']['mysql_connection_info']
  password      flow_data['db']['pass']
  database_name flow_data['db']['name']
  host          '%'
  privileges    [:all]
  action        :grant
end

#
# Install TYPO3 Flow
#

# clone git repo
git vhost_dir do
  repository node['project']['git']
  revision node['project']['branch']
  user node['app']['user']
  group node['app']['group']
  action :sync
end

# execute composer install
execute "composer install --dev --no-interaction --no-progress" do
  cwd vhost_dir
  user node['app']['user']
  group node['app']['group']
  environment (node['system']['composer_env'])
  not_if "test -f #{vhost_dir}/composer.lock"
end


# prepare Settings.yaml with database connection info
settings_yaml = "#{vhost_dir}/Configuration/Settings.yaml"
template settings_yaml do
  source 'typo3/Settings.yaml.erb'
  cookbook 'typo3-flow'
  variables({
      :db => flow_data['db']
  })
  user node['app']['user']
  group node['app']['group']
  not_if "test -f #{settings_yaml}"
end

settings_yaml = "#{vhost_dir}/Configuration/Development/Settings.yaml"
template settings_yaml do
  source 'typo3/Settings.yaml.erb'
  cookbook 'typo3-flow'
  variables({
      :db => flow_data['db']
  })
  user node['app']['user']
  group node['app']['group']
  not_if "test -f #{settings_yaml}"
end

settings_yaml = "#{vhost_dir}/Configuration/Production/Settings.yaml"
template settings_yaml do
  source 'typo3/Settings.yaml.erb'
  cookbook 'typo3-flow'
  variables({
      :db => flow_data['db']
  })
  user node['app']['user']
  group node['app']['group']
  not_if "test -f #{settings_yaml}"
end

#
# flow: file permissions
#
execute 'TYPO3 Flow post-installation: file permissions' do
  cwd vhost_dir
  command "
    ./flow core:setfilepermissions #{node[:app][:user]} #{node[:app][:user]} #{node[:app][:group]};
    chmod -R ug+rw .;
  "
end


#
# flow doctrine:migrate
#
mysql_cmd = "mysql -u#{flow_data['db']['user']} -p#{flow_data['db']['pass']} #{flow_data['db']['name']} -sN"

execute 'TYPO3 Flow post-installation: flow doctrine:migrate' do
  cwd vhost_dir
  command './flow doctrine:migrate'
  user node['app']['user']
  group node['app']['group']
  not_if "#{mysql_cmd} -e 'SHOW TABLES' | grep migrationstatus"
end if flow_data['install']['migrate_doctrine'] # only if migrate_doctrine flag is set

#
# flow: cache:warmup
#
execute 'TYPO3 Flow post-installation: cache:warmup' do
  cwd vhost_dir
  command "
    FLOW_CONTEXT=Production  ./flow cache:warmup;
    FLOW_CONTEXT=Development ./flow cache:warmup;
  "
  user node['app']['user']
  group node['app']['group']
end