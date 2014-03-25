# -*- mode: ruby -*-
# vi: set ft=ruby :
require './variables'
include ProjectVars

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.username    = 'vagrant'
  config.vm.boot_timeout = 120

  config.vm.hostname = VHOST

  config.vm.box = "centos-6.5"
  config.vm.box_url = "https://dl.dropboxusercontent.com/s/3qlxyqdtrf4b6a3/centos-6.5.box"
  
  config.vm.network "private_network", ip: IP

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.customize ["modifyvm", :id, "--memory", MEMORY]
    vb.customize ["modifyvm", :id, "--cpus", CPUS]
    vb.name = VM_NAME
  end
  
  config.omnibus.chef_version = '11.10.0'

  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = ["cookbooks", "site-cookbooks"]
    chef.add_recipe "typo3-flow"
    chef.json = {
      "project" => {
        "vhost" => VHOST,
        "git" => GIT,
        "branch" => BRANCH,
        "ip" => IP,
        "db" => {
          "project" => {
            "user" => DB_USER,
            "password" => DB_PASSWORD,
            "dbname" => DB_NAME
          },
          "root" => {
            "password" => DB_ROOT_PASSWORD,
          }
        }
      }
    }
  end
end
