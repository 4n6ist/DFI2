#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <device_file> <mount_point>"
  echo "Example: $0 /dev/sdb /mnt/exfat"
  exit 1
fi

DEVICE=$1
MOUNT_POINT=$2
USER_UID=$(id -u)
USER_GID=$(id -g)

# Specified device check
if [ ! -b "$DEVICE" ]; then
  echo "Error: $DEVICE does not exist."
  exit 1
fi

echo "Creating mount point $MOUNT_POINT..."
if [ ! -d "$MOUNT_POINT" ]; then
  if ! sudo mkdir -p "$MOUNT_POINT"; then
    echo "Error: Failed to create mount point $MOUNT_POINT. Check permissions."
    exit 1
  fi
fi

echo "Creating partition on $DEVICE..."
sudo parted $DEVICE --script mklabel gpt
sudo parted $DEVICE --script mkpart primary 0% 100%
sleep 1

PARTITION="${DEVICE}1"
if [ ! -b "$PARTITION" ]; then
  echo "Error: Partition $PARTITION was not created."
  exit 1
fi

echo "Formatting $PARTITION with exFAT..."
sudo mkfs.exfat $PARTITION

echo "Mounting $PARTITION to $MOUNT_POINT..."
sudo mount $PARTITION $MOUNT_POINT

UUID=$(sudo blkid -s UUID -o value $PARTITION)

echo "Updating /etc/fstab..."
FSTAB_ENTRY="UUID=$UUID $MOUNT_POINT exfat defaults,uid=$USER_UID,gid=$USER_GID 0 0"
if ! grep -q "$FSTAB_ENTRY" /etc/fstab; then
  echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
  echo "Added $PARTITION to /etc/fstab with uid=$USER_UID and gid=$USER_GID."
else
  echo "Entry already exists in /etc/fstab."
fi

echo "Unmounting $PARTITION..."
sudo umount $MOUNT_POINT

echo "Mounting all filesystems to verify /etc/fstab..."
sudo mount -a

echo "All done. $PARTITION is now set to auto-mount on startup at $MOUNT_POINT."
