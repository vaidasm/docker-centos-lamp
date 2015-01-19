# Docker LAMP image
Based on centos7. 
## Building and running
Building this container:

    docker build -t lamp .
    
To run this container:

    docker run \
        -p 80:80 \
        -p 3306:3306 \
        -p 2020:22 \
        -v $DIR:/var/www \
        -v $DIR/storage/db:/var/lib/mysql \
        -v $DIR/storage/logs:/var/log/shared \
        -h mxize \
        -i -t \
        lamp
    
## Use it with Vagrant
Sample Vagrant file:
```
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.provider "docker" do |d|
    d.build_dir = "docker"
    d.create_args = ["-ti"]
    d.has_ssh = true
    d.ports = ["80:80", "3306:3306"]
    d.remains_running = true
  end

  config.vm.define 'default' do |default|
    default.vm.hostname = 'mxize'
  end

  # SSH Configs
  config.ssh.username = "root"
  config.ssh.password = "datadog"

  # Synced folders
  config.vm.synced_folder ".", "/var/www"
  config.vm.synced_folder "storage/logs", "/var/log/shared"
  config.vm.synced_folder "storage/db", "/var/lib/mysql"

  config.vm.provider "virtualbox" do |vb|
     # Do not remove it, leave empty
  end

  # Provision with script
  config.vm.provision "shell", path: "docker/init.sh", privileged: false

end
```

