# DFI2

DFI2 is a forensic analysis toolkit on Linux. 

## Requirement & Setup

Start from clean install of the following ditribution and version with destkop environment (LXDE is recommended).

- Debian 11 or 12
- Ubuntu 20 or 22

Run the following command.

```
wget -O - https://raw.githubusercontent.com/4n6ist/DFI2/main/DFI2_setup.bash | bash
```

## preseed_debian_iso_lxde.sh

preseed_debian_iso_lxde.sh creates a custom Debian Install ISO with the preseed.cfg. It configures hostname as dfi2, user name as forensics, and install LXDE. 

Get an netinst ISO from the official site (https://www.debian.org/download), then run the script on Debian based OS as follows.

`# bash preseed_debian_iso_lxde.sh debian-x.y.z-amd64-netinst.iso`

Select Advanced options > Automated install when you install with the ISO.


