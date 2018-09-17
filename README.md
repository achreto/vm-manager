# QEMU/KVM Manager

This repository contains a simple QEMU/KVM management utility to create
virtual disk images and run virtual machines using QEMU/KVM.

## Configuration

See the file `config/config.sh` there are a few configuratoin variables that
one can set.

* MONITOR_CONSOLE_PATH: the path where the monitor consoles are being created
* KERNEL: the kernel image to boot the VM with
* INITRD: if set, the initrd to be used for booting
* VM_VCPU: the number of virtual cpus per VM
* VM_MEMORY: the amount of RAM to provision for the VM

## VM Commands

* `vm-start.sh`
* `vm-stop.sh <name>` sends the APCI shutdown signal to the VM

* `vm-suspend.sh <name>` suspends / stops the execution of the VM
* `vm-resume.sh <name>` resumes / continues the execution of the VM


## Disk Commands
