#!/usr/bin/env bash

set -e

# btain the script root
ROOT=$(dirname $(readlink -f "$0"))

# include the configuration
source $ROOT/config/config.sh

# ----------------------------------------------------------------------------
# Dependency checks
# ----------------------------------------------------------------------------

which qemu-img > /dev/null
if [ $? -ne 0 ]; then
  echo "qemu-utils not installed"
  echo "sudo apt-get install qemu-utils"
  exit 1
fi


# ----------------------------------------------------------------------------
# Argument checks
# ----------------------------------------------------------------------------

if [ $# -ne 2 ]; then
  echo "usage $0 <base> <path>"
  exit 1
fi

IMGBASE=$1
IMGPATH=$2


# ----------------------------------------------------------------------------
# Check if disk exists
# ----------------------------------------------------------------------------
if [ -f $IMGPATH ]; then
  echo "disk image already exists. delete first"
  exit 1
fi

if [ ! -f $IMGBASE ]; then
  echo "base disk image does not exist."
  exit 1
fi

# ----------------------------------------------------------------------------
# Create the disk and populate it with the image
# ----------------------------------------------------------------------------

# create the disk image
echo "create qcow2 disk image of size $IMGSIZE in '$IMGPATH'..."
qemu-img create -f qcow2,cluster_size=2M -b $IMGBASE $IMGPATH

# mount mount the image in the qemu-nbd
echo "mounting it using qemu-ndb on /dev/nbd0"
sudo modprobe nbd max_part=1
sudo qemu-nbd -c /dev/nbd0 $IMGPATH

# close ndb disk
echo "disconnecting disk image"
sudo qemu-nbd -d /dev/nbd0
sudo modprobe -r nbd
