#!/usr/bin/env bash

set -e

# obtain the script root
ROOT=$(dirname $(readlink -f "$0"))

# include the configuration
source $ROOT/config/config.sh


VM_NAME=""

while getopts ":m:c:r:d:n:p:" opt; do
  case ${opt} in
    n)
      VM_NAME=$OPTARG
      ;;
    m)
      VM_MEMORY=$OPTARG
      ;;
    c)
      VM_VCPU=$OPTARG
      ;;
    r)
      VM_HDD_ROOT_SIZE=$OPTARG
      ;;
    d)
      VM_HDD_DATA_SIZE=$OPTARG
      ;;
    p)
      VM_PORT_BASE=$OPTARG
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

# the name has to be set
if [[ $VM_NAME == "" ]]; then
  echo "no name supplied use the -n argument.  exiting"
  exit 1
fi

VM_PATH=$VM_ROOT/$VM_NAME

# if such a machine already exists, exit
if [ -e $VM_PATH ]; then
  echo "virtual machine '$VM_NAME' already exists"
fi

mkdir -p $VM_PATH

echo $VM_PORT_BASE > $VM_PATH/portbase
echo $VM_MEMORY > $VM_PATH/mem
echo $VM_VCPU > $VM_PATH/vcpu

echo "creating virtual machine $VM_NAME with $VM_VCPU cpus and $VM_MEMORY memory."
echo "using $VM_HDD_ROOT_SIZE root disk, $VM_HDD_LOGS_SIZE for logs and $VM_HDD_DATA_SIZE for data."



echo "creating disks..."

$ROOT/disk-create.sh $VM_HDD_ROOT_SIZE "$VM_PATH/hdd-root.qcow2"
$ROOT/disk-create.sh $VM_HDD_LOGS_SIZE "$VM_PATH/hdd-logs.qcow2"

if [[ $VM_HDD_DATA_SIZE != 0 ]]; then
  $ROOT/disk-create.sh $VM_HDD_DATA_SIZE "$VM_PATH/hdd-data.qcow2"
fi

echo "installing ubuntu on the root disk"
$ROOT/disk-install-ubuntu.sh $VM_PATH/hdd-root.qcow2 $VM_PATH $VM_HDD_DATA_SIZE



echo "virtual machine '$VM_NAME' created."
