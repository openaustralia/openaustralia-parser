# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.2.0"

vm_hostname = "local-oa-parser.example.com"

Vagrant.configure("2") do |config|
  # provider-specific config
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048 # in MB
    vb.cpus = 2
    vb.linked_clone = false
    vb.name = vm_hostname
  end

  config.vm.hostname = vm_hostname
  config.vm.box_check_update = true

  # Use most recent Ubuntu LTS
  config.vm.box = "generic/ubuntu2004"

  # guest VM directories
  work_base_dir = "/opt"
  work_source_dir = "#{work_base_dir}/source"
  ansible_venv_dir = "#{work_base_dir}/ansible-venv"

  # synchronised directory
  rsync_exclude = %w[.vagrant/ .vscode/ .idea/]
  config.vm.synced_folder "./", work_source_dir, type: "rsync", rsync__exclude: rsync_exclude, group: "vagrant", owner: "vagrant", create: true

  # Set this to a local ubuntu mirror to speed up the apt package installations.
  # Find your local mirrors here: https://launchpad.net/ubuntu/+archivemirrors
  old_apt_url = "http://us.archive.ubuntu.com/ubuntu"
  new_apt_url = "https://mirror.internet.asn.au/pub/ubuntu/archive"
  ubuntu_release = "focal"
  python_version = "3.9"

  # install ansible
  config.vm.provision "install_ansible", type: "shell", inline: <<-SHELL
    # vagrant might require a /vagrant directory
    if [[ ! -d "/vagrant" ]]; then
      sudo mkdir -p /vagrant
      sudo chown vagrant:vagrant /vagrant
    fi
    # always update apt packages
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update
    # ensure ca-certificates is up to date so that https connections will work
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install ca-certificates
    # update apt source to a local mirror to speed up the first apt update
    if [[ -f /etc/apt/sources.list && $(grep "#{old_apt_url}" /etc/apt/sources.list) ]]; then
      sudo sed -i 's;#{old_apt_url};#{new_apt_url};g' '/etc/apt/sources.list'
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update
    fi
    if [[ -f /etc/apt/sources.list.save && $(grep "#{old_apt_url}" /etc/apt/sources.list.save) ]]; then
      sudo sed -i 's;#{old_apt_url};#{new_apt_url};g' '/etc/apt/sources.list.save'
    fi
    # provide Python 3
    if [ ! -f "/etc/apt/sources.list.d/deadsnakes-ubuntu-ppa-#{ubuntu_release}.list" ]; then
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install software-properties-common python3-apt python-apt-common python3-packaging apt-transport-https
      sudo DEBIAN_FRONTEND=noninteractive add-apt-repository ppa:deadsnakes/ppa
    fi
    # create a Python virtual env for ansible
    if [ ! -d "#{ansible_venv_dir}" ]; then
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install python#{python_version} python#{python_version}-dev python#{python_version}-venv python#{python_version}-distutils
      sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install libxml2-dev libxslt-dev zlib1g-dev libffi-dev
      sudo python#{python_version} -m venv #{ansible_venv_dir}
      sudo chown -R vagrant:vagrant #{ansible_venv_dir}
    fi
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq upgrade
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq autoremove
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq autoclean
    #{ansible_venv_dir}/bin/python -m pip install -U pip
    #{ansible_venv_dir}/bin/pip install -U setuptools wheel
    #{ansible_venv_dir}/bin/pip install -U lxml
    #{ansible_venv_dir}/bin/pip install -U ansible
    #{ansible_venv_dir}/bin/ansible-galaxy collection install --upgrade community.general
  SHELL

  # run ansible
  config.vm.provision "run_ansible", type: "ansible_local" do |ans|
    ans.compatibility_mode = "2.0"
    ans.verbose = false
    ans.install = false
    ans.playbook_command = "#{ansible_venv_dir}/bin/ansible-playbook"
    ans.config_file = "#{work_source_dir}/local_dev/ansible.cfg"
    ans.playbook = "#{work_source_dir}/local_dev/playbook.yml"
    ans.extra_vars = {
      work_base_dir: work_base_dir,
      work_source_dir: work_source_dir,

      # set the time zone
      time_zone: "Australia/Sydney"
    }
  end
end
