#!/bin/bash

ISO_FILE=$1
NTFS_IMG=windows-10-ntfs.img

# Create a temporary loopback mount for the ISO
TEMP_MNT=$(mktemp -d)
ISO_LOOP_DEV=$(sudo losetup -f --show ${ISO_FILE})
sudo mount -o ro -t udf ${ISO_LOOP_DEV} ${TEMP_MNT}

# Determine the size of NTFS image we need based on the size of the ISO.
# NTFS allocates a big chunk for metadata
ISO_SIZE=$(</sys/block/loop0/size)
NTFS_SIZE=$((ISO_SIZE * 8 / 7))
echo "Image is $ISO_SIZE blocks."
echo "Creating NTFS image of $NTFS_SIZE blocks."

# Create NTFS image file
dd if=/dev/zero of=${NTFS_IMG} bs=512 count=${NTFS_SIZE}
NTFS_LOOP_DEV=$(sudo losetup -f --show ${NTFS_IMG})
sudo mkntfs -f -L "iso-to-usb" -I \
    -s 512 -c 4096 \
    -p 0 \
    -H 1 \
    -S 32 \
    -z 1 \
    ${NTFS_LOOP_DEV}

# Mount the NTFS image file
NTFS_MNT=$(mktemp -d)
sudo mount -o rw -t ntfs ${NTFS_LOOP_DEV} ${NTFS_MNT}

# Copy files from the ISO to the NTFS image
cp -av ${TEMP_MNT}/* ${NTFS_MNT}

# Clean up the NTFS loopback device and mount
sudo umount ${NTFS_LOOP_DEV}
sudo losetup -d ${NTFS_LOOP_DEV}

# Clean up the ISO loopback mount
sudo umount ${TEMP_MNT}
rmdir ${TEMP_MNT}
sudo losetup -d ${ISO_LOOP_DEV}
