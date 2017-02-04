Vagrant machine to use SELinux with Arch Linux
==============================================

Build an Arch Linux virtual machine with SELinux set up.

Basic usage
-----------

First Vagrant needs to be installed (cf. https://wiki.archlinux.org/index.php/Vagrant) and a box named "``archlinux``" needs to be added.
There are several ways to achieve this:

* Use a base image from [Arch Linux wiki](https://wiki.archlinux.org/index.php/Vagrant#Base_Boxes_for_Vagrant), for example:

        vagrant box add --name archlinux terrywang/archlinux

* or use [Packer Arch](https://github.com/elasticdog/packer-arch):

        git clone https://github.com/elasticdog/packer-arch
        cd packer-arch
        ./wrapacker -p virtualbox
        vagrant box add --name archlinux output/packer_arch_virtualbox.box

It is also possible to use libvirt instead of VirtualBox as Vagrant backend. The boxes can be mutated using vagrant mutate plugin:

    vagrant plugin install migrate
    vagrant mutate archlinux libvirt

Once there is an ``archlinux`` box in vagrant storage, these commands clone the git repository and build a new vagrant virtual machine.

    git clone https://github.com/archlinuxhardened/selinux
    cd selinux/_vagrant
    vagrant up
    vagrant ssh

The ``vagrant up`` command takes some time because all packages related to SELinux are built in the provisioning phase.
Once ``vagrant up`` completed, you can enjoy SELinux by connecting to the virtual machine with ``vagrant ssh``.

When you want to destroy the virtual machine, simply run ``vagrant destroy``.
