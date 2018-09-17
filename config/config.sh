# the path where the monitor consoles are being created
MONITOR_CONSOLE_PATH=/run/qemu

# the unix user that runs the qemu process
VM_USER_RUN=acreto

VM_USER_ADMIN=admin

VM_USER_ROOT_PASS=root
VM_USER_ADMIN_PASS=admin

VM_HOSTNAME=ubuntu

# the root directory where the VMs are stored
VM_ROOT=$ROOT/vms

# the kernel version of the host
KERNEL_VERSION=$(uname -r)

# the kernel to be used
KERNEL=/boot/vmlinuz-$KERNEL_VERSION

# the init rd to be used
INITRD=/boot/initrd.img-$KERNEL_VERSION

# the number of vCPU for the virtual machines
VM_VCPU=2

# the amount of memory for the machines
VM_MEMORY=4G

# where the vm is reachable by default
VM_PORT_BASE=10000

# the size of the default root hard drive
VM_HDD_ROOT_SIZE=16g

# the default size of the data disk
VM_HDD_DATA_SIZE=0

# the default size for log disks
VM_HDD_LOGS_SIZE=2g
