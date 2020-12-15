# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "ubuntu/xenial64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # NOTE: This will enable public access to the opened port
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", privileged: false, inline: <<-SHELL
    sudo apt-get update
    sudo apt-get install -y rbenv ruby-build
    echo 'eval "$(rbenv init -)"' > /home/vagrant/.bash_profile
    source ~/.bash_profile
    rbenv install 1.8.7-p374

    cd /vagrant

    # Installing the gems by hand here rather than using bundler because
    # bundler can't cope with the SSL certificate which is now on the
    # rubygems API

    gem install coderay --version "1.1.2" --conservative

    gem install multi_json --version "1.13.1" --conservative
    gem install i18n --version "0.6.11" --conservative
    gem install activesupport --version "3.2.22.5" --conservative

    sudo apt-get install -y imagemagick libmagickcore-dev libmagickwand-dev
    gem install rmagick --version "2.16.0" --conservative

    sudo apt-get install -y libmysqlclient-dev
    gem install mysql --version "2.9.1" --conservative

    gem install rake --version "10.5.0" --conservative
    gem install nokogiri --version "1.5.11" --conservative
    gem install mechanize --version '0.9.2' --conservative
    gem install hpricot --version "0.6.164" --conservative
    gem install htmlentities --version "4.3.1" --conservative
    gem install json --version "1.8.6" --conservative
    gem install builder --version '2.1.2' --conservative
    gem install log4r --version "1.1.10" --conservative
    gem install hoe --version "3.18.0" --conservative
    gem install rspec --version "2.11.0" --conservative
    gem install rcov --version "0.9.11" --conservative
    gem install pry --version '0.10.4' --conservative
    gem install bundler --version "1.16.2" --conservative
  SHELL
end
