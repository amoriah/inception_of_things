# TEAM_LOGIN = "amoriahTeam"
# DEBIAN_BOX = "bento/debian-13"

# Vagrant.configure("2") do |config|
#   config.vm.box = DEBIAN_BOX

#   config.ssh.insert_key = true

#   config.vm.define "#{TEAM_LOGIN}S" do |server|
#     server.vm.hostname = "#{TEAM_LOGIN}S"

#     server.vm.network "private_network",
#       ip: "192.168.56.110"

#     server.vm.provider "virtualbox" do |vb|
#       vb.name = "#{TEAM_LOGIN}S"
#       vb.cpus = 1
#       vb.memory = 1024
#       vb.gui = false
#     end

#   end

#   config.vm.define "#{TEAM_LOGIN}SW" do |worker|
#     worker.vm.hostname = "#{TEAM_LOGIN}SW"

#     worker.vm.network "private_network",
#       ip: "192.168.56.111"

#     worker.vm.provider "virtualbox" do |vb|
#       vb.name = "#{TEAM_LOGIN}SW"
#       vb.cpus = 1
#       vb.memory = 1024
#       vb.gui = false
#     end

#   end
# end
TEAM_LOGIN = "amoriahTeam"
DEBIAN_BOX = "bento/debian-13"

Vagrant.configure("2") do |config|
  config.vm.box = DEBIAN_BOX

  config.ssh.insert_key = true

  # Общая папка проекта внутри обеих виртуальных машин.
  config.vm.synced_folder ".", "/vagrant"

  config.vm.define "#{TEAM_LOGIN}S" do |server|
    server.vm.hostname = "#{TEAM_LOGIN}S"

    server.vm.network "private_network",
      ip: "192.168.56.110"

    server.vm.provider "virtualbox" do |vb|
      vb.name = "#{TEAM_LOGIN}S"
      vb.cpus = 2
      vb.memory = 2048
      vb.gui = false
    end

    server.vm.provision "shell",
      path: "scripts/install-server.sh",
      privileged: true
  end

  config.vm.define "#{TEAM_LOGIN}SW" do |worker|
    worker.vm.hostname = "#{TEAM_LOGIN}SW"

    worker.vm.network "private_network",
      ip: "192.168.56.111"

    worker.vm.provider "virtualbox" do |vb|

      
      vb.name = "#{TEAM_LOGIN}SW"
      vb.cpus = 1
      vb.memory = 1024
      vb.gui = false
    end

    worker.vm.provision "shell",
      path: "scripts/install-agent.sh",
      privileged: true
  end
end