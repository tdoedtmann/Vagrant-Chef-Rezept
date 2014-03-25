#
# Yum repositories
# 

include_recipe 'yum'

# add the EPEL repo
r = yum_repository 'epel' do
  description 'Extra Packages for Enterprise Linux'
  mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch'
  gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
  not_if 'test -f /etc/yum.repos.d/epel.repo'
  action :nothing
end
r.run_action(:create)

# add the Remi repo
r = yum_repository 'remi' do
  description 'Les RPM de remi pour Enterprise Linux $releasever - $basearch'
  mirrorlist 'http://rpms.famillecollet.com/enterprise/$releasever/remi/mirror'
  gpgkey 'http://rpms.famillecollet.com/RPM-GPG-KEY-remi'
  not_if 'test -f /etc/yum.repos.d/remi.repo'
  action :nothing
end
r.run_action(:create)

# add the Remi PHP 5.5 repo
r =  yum_repository 'remi-php55' do
  description 'Les RPM de remi de PHP 5.5 pour Enterprise Linux $releasever - $basearch'
  mirrorlist 'http://rpms.famillecollet.com/enterprise/$releasever/php55/mirror'
  gpgkey 'http://rpms.famillecollet.com/RPM-GPG-KEY-remi'
  not_if 'test -f /etc/yum.repos.d/remi-php55.repo'
  action :nothing
end
r.run_action(:create)

# add Nginx repo
r =  yum_repository 'nginx' do
  description 'nginx repo'
  baseurl 'http://nginx.org/packages/centos/6/$basearch/'
  gpgkey 'http://nginx.org/keys/nginx_signing.key'
  not_if 'test -f /etc/yum.repos.d/nginx.repo'
  action :nothing
end
r.run_action(:create)

#
# YUM update + install dev tools
#
execute "yum update -y; yum groupinstall -y 'Development tools';" do
  action :nothing
end.run_action(:run)

# Install extra packages (user software etc)
node[:system][:packages].each do |pkg|
  package pkg do
    action :install
  end
end


#
# Misc CentOS tuning
#

# Switch off not needed services
['abrt-ccpp', 'abrtd', 'atd', 'auditd', 'blk-availability',
  'haldaemon', 'ip6tables','iptables','kdump',
  'lvm2-monitor','mdmonitor','messagebus','postfix',
  'sysstat','udev-post'].each do |sv|
    service sv do
      action [ :disable, :stop ]
    end
end