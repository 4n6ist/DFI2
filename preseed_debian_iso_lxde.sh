#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 debian-<ver>-<arch>-netinst.iso"
    exit 1
fi

filename="$1"
version=$(echo "$filename" | sed -n 's/.*-\([0-9.]\+\)-.*-netinst\.iso/\1/p')

# Check if the version number extraction was successful
if [ -z "$version" ]; then
    echo "Failed to extract the version number. The provided filename may not match the expected format."
else
    echo "Extracted version number: $version"
fi

sudo apt-get install libarchive-tools genisoimage

if [ ! -f "./preseed.cfg" ]; then
  wget https://raw.githubusercontent.com/4n6ist/DFI2/main/preseed.cfg
fi
mkdir isofiles
bsdtar -C ./isofiles -xf ${filename}
chmod +w -R isofiles/install.amd/
gunzip isofiles/install.amd/initrd.gz 
echo preseed.cfg | cpio -H newc -o -A -F isofiles/install.amd/initrd
gzip isofiles/install.amd/initrd 
chmod -w -R isofiles/install.amd/
cd isofiles/
chmod +w md5sum.txt 
find -follow -type f ! -name md5sum.txt -print0 | xargs -0 md5sum > md5sum.txt 
chmod -w md5sum.txt 
cd ..
sudo genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o preseed-${filename} isofiles
sudo rm -rf isofiles preseed.cfg
echo "Completed creating preseed-${filename}"
