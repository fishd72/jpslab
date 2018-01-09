Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-16.04"
  config.vm.hostname = "jpslab"
  config.vm.provider "vmware_fusion" do |vmware|
    vmware.vmx["memsize"] = "3072"
    vmware.vmx["numvcpus"] = "2"
    vmware.gui = false
  end
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 3072
    vb.cpus = 2
    vb.gui = false
  end
  config.vm.network :forwarded_port, guest: 8080, host: 8080, auto_correct: true
  config.vm.provision :shell, :path => "scripts/jpslabSetup.sh"
  config.ssh.forward_agent = true
end
