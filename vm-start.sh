#!/usr/bin/env bash

set -e

# obtain the script root
ROOT=$(dirname $(readlink -f "$0"))

# include the configuration
source $ROOT/config/config.sh

echo "Using kernel: $KERNEL"

if [ $# -ne 1 ]; then
  echo "usage $0 <name>"
  exit 1
fi

NAME=$1
VMPATH=$VM_ROOT/$NAME
if [ ! -e $VMPATH ]; then
  echo "Path '$VMPATH' does not exist"
  exit 1
fi

if [ -e $VMPATH/monitor ]; then
  echo "VM '$NAME' seems to be running already"
  exit 1
fi


PIDFILE=$VMPATH/pid
HDD_ROOT=$VMPATH/hdd-root.qcow2
HDD_DATA=$VMPATH/hdd-data.qcow2
HDD_LOGS=$VMPATH/hdd-logs.qcow2
VM_PORT_BASE=$(cat $VMPATH/portbase)

if [ -e $VMPATH/mem ]; then
  VM_MEMORY=$(cat $VMPATH/mem)
fi
if [ -e $VMPATH/mem ]; then
  VM_VCPU=$(cat $VMPATH/vcpu)
fi


sudo chown -R $VM_USER_RUN:$VM_USER_RUN $VMPATH

if [ ! -e $HDD_ROOT ]; then
  echo "Root disk '$HDD_ROOT' does not exist"
  exit 1
fi


if [ ! -e $HDD_LOGS ]; then
  echo "logs hdd does not exist, creating..."
  exit 1
fi
ATTACH_HDDS="-hda $HDD_ROOT -hdb $HDD_LOGS"

if [ -e $HDD_DATA ]; then
  ATTACH_HDDS="$ATTACH_HDDS -hdc $HDD_DATA"
fi


PORT_SSH=$(cat $VMPATH/portbase)
PORT_SVC=$((VM_PORT_BASE+1))


echo "using hdds $ATTACH_HDDS"

#-initrd $INITRD \
sudo  qemu-system-x86_64   --enable-kvm \
  -machine ubuntu,accel=kvm -nodefaults \
  -runas $VM_USER_RUN  -serial stdio \
  -monitor unix:$VMPATH/monitor,server,nowait \
  -kernel $KERNEL -append "root=/dev/sda rootfstype=ext4 rw console=ttyS0" \
  -pidfile $PIDFILE -name $NAME \
  $ATTACH_HDDS \
  -device virtio-net-pci,netdev=net0 \
  -netdev user,id=net0,hostfwd=tcp::$PORT_SSH-:2222,hostfwd=tcp::$PORT_SVC-:443 \
  --nographic --vga none \
  -cpu host -m size=$VM_MEMORY -smp $VM_VCPU
