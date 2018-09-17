#!/usr/bin/env bash

set -e

# obtain the script root
ROOT=$(dirname $(readlink -f "$0"))

# include the configuration
source $ROOT/config/config.sh

# function that executes the monitor command
function exec_monitor_command {

  VMROOT=$1
  VMNAME=$2
  CMD=$3
  STR=$4

  # check if we should suspend all or just the supplied one
  if [[ $VMNAME == '--all' ]]; then
    for VMNAME in $VMROOT/*; do
      if [ ! -e $VMNAME/monitor ]; then
        echo "vm-ctl: virtual machine '$VMNAME' is not running"
      else
        echo "vm-ctl: $STR virtual machine '$VMNAME'..."
        echo $CMD | sudo socat - UNIX-CONNECT:$VMNAME/monitor
      fi
    done
  else
    # only suspend the indicated vm, if it exists
    if [ ! -e $VM_ROOT/$VMNAME ]; then
      echo "virtual machine '$VMNAME' does not exist"
      exit 1
    fi

    if [ ! -e $VM_ROOT/$VMNAME/monitor ]; then
      echo "vm-ctl: virtual machine '$VMNAME' is not running"
    else
      echo "vm-ctl: $STR virtual machine '$VMNAME'..."
      echo $CMD | sudo socat - UNIX-CONNECT:$VM_ROOT/$VMNAME/monitor
    fi
  fi
}

# function that executes the monitor command
function vm_status {

  VMROOT=$1
  VMNAME=$2

  # check if we should suspend all or just the supplied one
  if [[ $VMNAME == '--all' ]]; then
    for VMNAME in $VMROOT/*; do
      if [ ! -e $VMNAME/monitor ]; then
        echo "vm-ctl: virtual machine '$VMNAME' is [offline]"
      else
        echo "vm-ctl: virtual machine '$VMNAME' is [online]"
      fi
    done
  else
    # only suspend the indicated vm, if it exists
    if [ ! -e $VMROOT/$VMNAME ]; then
      echo "vm-ctl: virtual machine '$VMNAME' is [unknown]"
      exit 1
    fi

    if [ ! -e $VMROOT/$VMNAME/monitor ]; then
      echo "vm-ctl: virtual machine '$VMNAME' is [offline]"
    else
      echo "vm-ctl: virtual machine '$VMNAME' is [online]"
    fi
  fi
}


function vm_update {
  VMROOT=$1
  VMNAME=$2

  # check if we should suspend all or just the supplied one
  if [[ $VMNAME == '--all' ]]; then
    for VMNAME in $VMROOT/*; do
      if [ ! -e $VMNAME/monitor ]; then
        echo "vm-ctl: updating virtual machine '$VMNAME'"
        $ROOT/disk-update-ubuntu.sh $VMNAME/hdd-root.qcow2
      else
        echo "vm-ctl: virtual machine '$VMNAME' is running. skip update."
      fi
    done
  else
    # only suspend the indicated vm, if it exists
    if [ ! -e $VMROOT/$VMNAME ]; then
      echo "vm-ctl: virtual machine '$VMNAME' is [unknown]"
      exit 1
    fi

    if [ ! -e $VMROOT/$VMNAME/monitor ]; then
      echo "vm-ctl: updating virtual machine '$VMNAME'"
      $ROOT/disk-update-ubuntu.sh $VMROOT/$VMNAME/hdd-root.qcow2
    else
      echo "vm-ctl: virtual machine '$VMNAME' is running. skip update."
    fi
  fi
}


# check if the root path exists
if [ ! -e $VM_ROOT ]; then
  echo "vm root path '$VM_ROOT' missing"
  exit 1
fi

# check the arguments, must supply an vm name
if [ $# -ne 2 ]; then
  echo "usage $0 [status|suspend|resume|stop] <vmname>"
  exit 1
fi

VMCMD=$1
VMNAME=$2


case $VMCMD in
  status)
    vm_status $VM_ROOT $VMNAME
    exit 0
    ;;
  suspend)
    exec_monitor_command $VM_ROOT $VMNAME stop suspending
    exit 0
    ;;
  resume)
    exec_monitor_command $VM_ROOT $VMNAME cont resuming
    exit 0
    ;;
  stop)
    exec_monitor_command $VM_ROOT $VMNAME system_powerdown stopping
    exit 0
    ;;
  update)
    vm_update $VM_ROOT $VMNAME
    exit 0
    ;;
  *)
    echo "usage $0 [status|suspend|resume|stop] <vmname>"
    exit 1
    ;;
esac
