include_recipe 'nfs'

nfs_export "/exports" do
	directory node[:system][:www_root]
	network "#{node[:project][:ip]}/8"
	writeable true 
	sync false
	options ['all_squash','anonuid=80','anongid=80']
end

# Start nfs-server components
service node['nfs']['service']['server'] do
  provider node['nfs']['service_provider']['server']
  action [:start, :enable]
  supports status: true
end