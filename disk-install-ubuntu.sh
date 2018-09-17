#!/usr/bin/env bash

set -e

# btain the script root
ROOT=$(dirname $(readlink -f "$0"))

# include the configuration
source $ROOT/config/config.sh

# default components to be installed
COMPONENTS=main,universe

# default packages to be installed
PACKAGES=openssh-server,ssh,curl,\
language-pack-en-base,\
apt-transport-https,\
ca-certificates,\
software-properties-common,\
ufw,git,zsh,fail2ban,\
gpg-agent,vim,\
net-tools,lshw,\
unattended-upgrades,\
apparmor,wget,unzip


# for ubuntu 18.04
SUITE=bionic

# default mirror of the distribution
MIRROR=http://archive.ubuntu.com/ubuntu


# ----------------------------------------------------------------------------
# Dependency checks
# ----------------------------------------------------------------------------

which debootstrap > /dev/null
if [ $? -ne 0 ]; then
  echo "debootstrap not installed"
  echo "sudo apt-get install debootstrap"
  exit 1
fi

which qemu-img > /dev/null
if [ $? -ne 0 ]; then
  echo "qemu-utils not installed"
  echo "sudo apt-get install qemu-utils"
  exit 1
fi


# ----------------------------------------------------------------------------
# Argument checks
# ----------------------------------------------------------------------------

if [ $# -ne 3 ]; then
  echo "usage $0 <path> <datadisk>"
  exit 1
fi

IMGPATH=$1
VM_PATH=$2
HAS_DATA_DISK=$3


# ----------------------------------------------------------------------------
# Check if disk exists
# ----------------------------------------------------------------------------
if [ ! -f $IMGPATH ]; then
  echo "disk image not found '$IMGPATH'. Exiting."
  exit 1
fi


# ----------------------------------------------------------------------------
# Mount and populate
# ----------------------------------------------------------------------------

# the mount path for mounting the disk
MOUNTPATH=$(mktemp -d)

# mount mount the image in the qemu-nbd
echo "mounting it using qemu-ndb on /dev/nbd0"
sudo modprobe nbd max_part=1
sudo qemu-nbd -c /dev/nbd0 $IMGPATH

# mount the image in the temporary mount point
echo "mounting disk at '$MOUNTPATH'"
sudo mount /dev/nbd0 $MOUNTPATH

# create the debian image
sudo debootstrap --include $PACKAGES \
                 --components $COMPONENTS \
                 $SUITE $MOUNTPATH $MIRROR


# set the u  pdate sources
echo "deb $MIRROR $SUITE ${COMPONENTS//,/ }" | sudo tee $MOUNTPATH/etc/apt/sources.list
echo "deb $MIRROR $SUITE-updates ${COMPONENTS//,/ }" | sudo tee -a $MOUNTPATH/etc/apt/sources.list
echo "deb $MIRROR $SUITE-security ${COMPONENTS//,/ }" | sudo tee -a $MOUNTPATH/etc/apt/sources.list


# mount the procfs for the chroot
echo "Mounting procfs in ''$MOUNTPATH/proc'"
sudo mount -t proc /proc $MOUNTPATH/proc
sudo mount -t sysfs /sys $MOUNTPATH/sys

# prepare docker
echo "prepare docker installation"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo chroot $MOUNTPATH apt-key add -
sudo chroot $MOUNTPATH  add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

echo "updating packages and upgrading distribution"
sudo chroot $MOUNTPATH apt-get update
sudo chroot $MOUNTPATH apt-get dist-upgrade -y

echo "install docker and upgrade all packages"
sudo chroot $MOUNTPATH apt-get install docker-ce  docker-compose -y
sudo chroot $MOUNTPATH apt-get upgrade -y

# set the password for root
echo "change root password"
echo -e "$VM_USER_ROOT_PASS\n$VM_USER_ROOT_PASS" | sudo chroot $MOUNTPATH passwd


# adding the usermod
echo "create user '$VM_USER_ADMIN'"
sudo chroot $MOUNTPATH useradd -m $VM_USER_ADMIN

echo "change user '$VM_USER_ADMIN' password"
echo -e "$VM_USER_ADMIN_PASS\n$VM_USER_ADMIN_PASS" | sudo chroot $MOUNTPATH passwd $VM_USER_ADMIN
sudo chroot $MOUNTPATH usermod -aG sudo $VM_USER_ADMIN
sudo chroot $MOUNTPATH usermod -aG docker $VM_USER_ADMIN

echo "generating ssh keys"
sudo mkdir -p $MOUNTPATH/home/$VM_USER_ADMIN/.ssh
ssh-keygen -q -f "$VM_PATH/sshkey" -t ed25519 -a 256 -N ""
cat $VM_PATH/sshkey.pub | sudo tee $MOUNTPATH/home/$VM_USER_ADMIN/.ssh/authorized_keys


echo "setting up firewall to block all but ssh and https"
sudo chroot $MOUNTPATH ufw enable
sudo chroot $MOUNTPATH ufw default deny incoming
sudo chroot $MOUNTPATH ufw default allow outgoing
sudo chroot $MOUNTPATH ufw allow 2222
sudo chroot $MOUNTPATH ufw allow 443

echo "copy sshd configuration"
sudo cp $ROOT/config/default_sshd_config $MOUNTPATH/etc/ssh/sshd_config
sudo cp $ROOT/config/sysctl.conf $MOUNTPATH/etc/ssh/sysctl.conf

echo "applying netplan settings"
sudo cp $ROOT/config/netplan.yaml  $MOUNTPATH/etc/netplan/config.yaml
sudo chroot $MOUNTPATH netplan apply


echo "" | sudo tee -a  $MOUNTPATH/etc/fstab
echo "# mount the data and log disds" | sudo tee -a  $MOUNTPATH/etc/fstab
echo "/dev/sdb /var/log ext4 defaults 0 2" | sudo tee -a  $MOUNTPATH/etc/fstab


if [ $HAS_DATA_DISK != 0 ]; then
  echo "create data partition mount"
  sudo mkdir -p $MOUNTPATH/mnt/data
  echo "/dev/sdc /mnt/data ext4 defaults 0 2" | sudo tee -a  $MOUNTPATH/etc/fstab
fi

echo "copy linux kernel modules"
sudo mkdir -p $MOUNTPATH/lib/modules
sudo rsync -av /lib/modules/$KERNEL_VERSION $MOUNTPATH/lib/modules


# unmount the procfs
echo "unmounting /proc and /sys"
sudo umount $MOUNTPATH/proc
sudo umount $MOUNTPATH/sys

# unmount the disk
echo "unmounting disk"
sudo umount $MOUNTPATH

# remote the mount path
echo "delete mount path"
rm -rf $MOUNTPATH

# close ndb disk
echo "disconnecting disk image"
sudo qemu-nbd -d /dev/nbd0
sudo modprobe -r nbd
