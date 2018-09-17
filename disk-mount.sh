#!/usr/bin/env bash

set -e


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
echo "mounting '$IMGPATH' using qemu-ndb on /dev/nbd0"
sudo modprobe nbd max_part=1
sudo qemu-nbd -c /dev/nbd0 $IMGPATH

echo "mounting disk at '$MOUNTPATH'"
sudo mount /dev/nbd0 $MOUNTPATH

# mount the procfs for the chroot
sudo mount -t proc /proc $MOUNTPATH/proc

# install docker
sudo chroot $MOUNTPATH /bin/bash

# unmount the procfs
sudo umount $MOUNTPATH/proc

# unmount the disk
echo "unmounting disk image.."
sudo umount $MOUNTPATH

# remote the mount path
rm -rf $MOUNTPATH

# close ndb disk
echo "unmounting qemu-ndb on /dev/nbd0"
sudo qemu-nbd -d /dev/nbd0
sudo killall qemu-nbd
sudo modprobe -r nbd
