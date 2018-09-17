#!/usr/bin/env bash

set -e

# btain the script root
ROOT=$(dirname $(readlink -f "$0"))

# include the configuration
source $ROOT/config/config.sh

# the mount path for mounting the disk
MOUNTPATH=$(mktemp -d)

# ----------------------------------------------------------------------------
# Argument checks
# ----------------------------------------------------------------------------

if [ $# -ne 1 ]; then
  echo "usage $0 <path>"
  exit 1
fi

IMGPATH=$1


# ----------------------------------------------------------------------------
# mount disk and install docker
# ----------------------------------------------------------------------------

# mount the image in the temporary mount point
echo "mounting it using qemu-ndb on /dev/nbd0"
sudo modprobe nbd max_part=16
sudo qemu-nbd -c /dev/nbd0 $IMGPATH

echo "mounting disk at '$MOUNTPATH'"
sudo mount /dev/nbd0 $MOUNTPATH

# mount the procfs for the chroot
sudo mount -t proc /proc $MOUNTPATH/proc


sudo chroot $MOUNTPATH apt-get update
sudo chroot $MOUNTPATH apt-get dist-upgrade -y
sudo chroot $MOUNTPATH apt-get upgrade -y


sudo mkdir -p $MOUNTPATH/lib/modules
sudo rsync -av /lib/modules/$KERNEL_VERSION $MOUNTPATH/lib/modules

# sync the certificates


# unmount the procfs
sudo umount $MOUNTPATH/proc

# unmount the disk
echo "unmounting disk..."
sudo umount $MOUNTPATH

# remote the mount path
rm -rf $MOUNTPATH

# close ndb disk
echo "unmounting qemu-ndb on /dev/nbd0"
sudo qemu-nbd -d /dev/nbd0
sudo modprobe -r nbd
