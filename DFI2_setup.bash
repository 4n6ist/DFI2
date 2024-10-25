#!/usr/bin/env bash
# https://www.oreilly.com/library/view/learning-modern-linux/9781098108939/
set -o errexit
set -o nounset
set -o pipefail
# DFI2 (Digital Forensics & Incident Investigation) setup
# bash DFI2_setup.bash

tools_dir="${HOME}/tools"
sleuthkit_ver="4.12.1"
sleuthkit_file="sleuthkit-java_${sleuthkit_ver}-1_amd64.deb"
sleuthkit_dl="https://github.com/sleuthkit/sleuthkit/releases/download/sleuthkit-${sleuthkit_ver}/${sleuthkit_file}"
autopsy_ver="4.21.0"
autopsy_file="autopsy-${autopsy_ver}.zip"
autopsy_dl="https://github.com/sleuthkit/autopsy/releases/download/autopsy-${autopsy_ver}/${autopsy_file}"
autopsy_dir="${tools_dir}/autopsy"
drawio_ver="24.7.17"
drawio_file="drawio-amd64-${drawio_ver}.deb"
drawio_dl="https://github.com/jgraph/drawio-desktop/releases/download/v${drawio_ver}/${drawio_file}"
timeline_ver="2.9.0"
timeline_file="timeline-${timeline_ver}.zip"
timeline_dl="http://sourceforge.net/projects/thetimelineproj/files/thetimelineproj/${timeline_ver}/${timeline_file}/download"
timeline_dir="${tools_dir}/timeline"
memprocfs_ver="v5.12.2"
memprocfs_file="MemProcFS_files_and_binaries_${memprocfs_ver}-linux_x64-20241020.tar.gz"
memprocfs_dl=https://github.com/ufrisk/MemProcFS/releases/download/v5.12/${memprocfs_file}
memprocfs_dir="${tools_dir}/memprocfs"
cyberchef_ver="v10.19.2"
cyberchef_file="CyberChef_${cyberchef_ver}.zip"
cyberchef_dl="https://gchq.github.io/CyberChef/${cyberchef_file}"
cyberchef_dir="${tools_dir}/cyberchef"
diskeditor_file="DiskEditor.tar.gz"
diskeditor_install="DiskEditor_Linux_Installer.run"
diskeditor_dl="https://www.disk-editor.org/download/DiskEditor.tar.gz"

cd "${HOME}"
mkdir -p "${tools_dir}"

source /etc/os-release

if [ "$DISPLAY" ] && [ "$ID" == "ubuntu" ] && [ "${VERSION_ID:0:1}" == "2" ]; then
    echo "Supported. Continue..."
elif [ "$DISPLAY" ] && [ "$ID" == "debian" ] && [ "${VERSION_ID}" -gt  10 ]; then
    echo "Supported. Continue..."
else
    echo "The script doesn't support in the machine."
	exit 1
fi

echo "Installing forensic utilities..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y auditd cifs-utils ext4magic extundelete dnsutils \
    ewf-tools git john jq libewf-dev libewf2 mg netcat-traditional openssh-server python3-libewf \
    ripgrep ssdeep strace sysstat wireshark xxd zip wget
sudo systemctl disable ssh
sudo systemctl stop ssh

echo "Installing dependencies for Autopsy..."
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk openjdk-17-jre \
    build-essential autoconf libtool automake ant libde265-dev libheif-dev libpq-dev \
    testdisk libafflib-dev libewf-dev libvhdi-dev libvmdk-dev libsqlite3-dev libc3p0-java \
    libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x \
    gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio

if [[ $? -ne 0 ]]; then
    echo "Failed to install dependencies for Autopsy" >>/dev/stderr
    exit 1
fi

export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export JDK_HOME="${JAVA_HOME}"
export PATH="${JAVA_HOME}/bin:${PATH}"
echo "JAVA_HOME='/usr/lib/jvm/java-17-openjdk-amd64'" >> "${HOME}"/.bashrc

echo "Installing SleuthKit..."
sudo dpkg --configure -a
cd "${HOME}"
wget ${sleuthkit_dl}
sudo dpkg -i ${sleuthkit_file}
sudo apt-get -y install -f

echo "Installing Autopsy..."
cd "${HOME}"
wget ${autopsy_dl}
unzip ${autopsy_file} -d "${tools_dir}"
echo "jdkhome=/usr/lib/jvm/java-17-openjdk-amd64" >> "${autopsy_dir}"/etc/autopsy.conf
echo "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> "${autopsy_dir}"/etc/autopsy.conf
echo "JDK=/usr/lib/jvm/java-17-openjdk-amd64" >> "${autopsy_dir}"/etc/autopsy.conf

cd "${autopsy_dir}"
chmod u+x unix_setup.sh
bash ./unix_setup.sh -j /usr/lib/jvm/java-17-openjdk-amd64
echo "Launching Autopsy...push OK, close, then exit the app"
"${autopsy_dir}"/bin/autopsy --nosplash
find "${autopsy_dir}" -name "*.exe" -type f -exec rm {} \;
find "${autopsy_dir}" -name "*.dll" -type f -exec rm {} \;
rm -rf "${autopsy_dir}"/autopsy/plaso/*

echo "Installing Bulk Extractor..."
cd "${HOME}"
git clone --recurse-submodules https://github.com/simsong/bulk_extractor.git 
MPKGS="flex gcc md5deep openssl patch g[+][+] pkg-config libpcre2-dev libre2-dev libssl-dev libexpa\
t1-dev libewf-dev libewf2 python3-libewf zlib1g-dev libxml2-dev libjson-c-dev"
sudo apt-get install -y $MPKGS
cd "${HOME}"/bulk_extractor
./bootstrap.sh
./configure
make
sudo make install
if [[ $? -ne 0 ]]; then
    echo "Failed to install Bulk Extractor" >>/dev/stderr
    exit 1
fi

echo "Installing drawio..."
cd "${HOME}"
wget ${drawio_dl}
sudo dpkg -i ${drawio_file}

echo "Installing Timeline..."
cd "${HOME}"
wget ${timeline_dl} -O ${timeline_file}
unzip ${timeline_file} -d "${tools_dir}"
cd "${timeline_dir}"
sudo apt-get install -y python3-pip python3-wxgtk4.0 python3-icalendar python3-markdown
if [ "$ID" == "debian" ] && [ "${VERSION_ID}" == 12 ]; then
    pip install --break-system-packages --user git+https://github.com/thetimelineproj/humblewx.git
else
    pip install --user git+https://github.com/thetimelineproj/humblewx.git
fi
if [[ $? -ne 0 ]]; then
    echo "Failed to install Timeline" >>/dev/stderr
    exit 1
fi

echo "Installing memprocfs..."
cd "${HOME}"
wget ${memprocfs_dl}
sudo apt-get install -y fuse lz4
mkdir ${memprocfs_dir}
cd ${memprocfs_dir}
tar xvzf ${HOME}/${memprocfs_file}

echo "Installing SARchart..."
cd "${tools_dir}"
git clone https://github.com/sargraph/sargraph.github.io.git
mv sargraph.github.io sarchart
cd sarchart
wget https://raw.githubusercontent.com/4n6ist/DFI2/main/images/SARchart.png
sudo apt-get install -y npm
npm install
if [[ $? -ne 0 ]]; then
    echo "Failed to install SARchart" >>/dev/stderr
    exit 1
fi

echo "Installing CyberChef..."
cd "${HOME}"
wget ${cyberchef_dl}
unzip ${cyberchef_file} -d ${cyberchef_dir}

echo "Installing Active Disk Editor..."
cd "${HOME}"
wget ${diskeditor_dl}
tar xvzf ${diskeditor_file}
sudo "${HOME}"/${diskeditor_install}

echo "Clean-up..."
rm -rf bulk_extractor ${autopsy_file} ${sleuthkit_file} ${drawio_file} ${timeline_file} ${cyberchef_file} ${diskeditor_file} ${diskeditor_install} ${memprocfs_file}

echo "System Config..."
sudo sed -i "s/^GRUB_TIMEOUT\=.*/GRUB_TIMEOUT\=3/" /etc/default/grub
sudo update-grub
sudo sh -c 'echo "forensics   ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/forensics'
sudo sed -i "s/^\*mode:.*/\*mode:                  off/" /etc/X11/app-defaults/XScreenSaver
sudo timedatectl set-timezone Etc/UTC
sudo mkdir /mnt/dd
sudo mkdir /mnt/e0
sudo apt-get install -y network-manager-gnome fcitx-mozc

echo "User Config..."
cd "${HOME}"
mkdir "${HOME}"/cases
mkdir "${HOME}"/evidence
echo "complete -cf sudo" >> "${HOME}"/.bashrc

if [ "${XDG_CURRENT_DESKTOP}" != "LXDE" ]; then
    echo "No LXDE...skip desktop, menu config. DFI setup - done"
    exit 0
fi

/usr/bin/pcmanfm
wget https://raw.githubusercontent.com/4n6ist/DFI2/main/.config/gtk-3.0/bookmarks -O "${HOME}"/.config/gtk-3.0/bookmarks
wget https://raw.githubusercontent.com/4n6ist/DFI2/main/.config/lxpanel/LXDE/panels/panel -O "${HOME}"/.config/lxpanel/LXDE/panels/panel
wget https://raw.githubusercontent.com/4n6ist/DFI2/main/.config/lxterminal/lxterminal.conf -O "${HOME}"/.config/lxterminal/lxterminal.conf
wget https://raw.githubusercontent.com/4n6ist/DFI2/main/images/DFI2_background.jpg -O "${tools_dir}/DFI2_background.jpg"
sed -i "s/^wallpaper\=.*/wallpaper\=\/home\/forensics\/tools\/DFI2_background.jpg/" "${HOME}"/.config/pcmanfm/LXDE/desktop-items-0.conf 
sed -i "s/^show_full_names\=.*/show_full_names\=1/" "${HOME}"/.config/libfm/libfm.conf
sed -i "s/^quick_exec\=.*/quick_exec\=1/" "${HOME}"/.config/libfm/libfm.conf
sed -i "s/^shadow_hidden\=.*/shadow_hidden\=1/" "${HOME}"/.config/libfm/libfm.conf
sed -i "s/^view_mode\=.*/view_mode\=list/" "${HOME}"/.config/pcmanfm/LXDE/pcmanfm.conf
pkill pcmanfm
mkdir .config/autostart
cat <<EOF > "${HOME}"/.config/autostart/lxrandr-autostart.desktop 
[Desktop Entry]
Type=Application
Name=LXRandR autostart
Comment=Start xrandr with settings done in LXRandR
Exec=sh -c 'xrandr --output Virtual1 --mode 1440x900'
OnlyShowIn=LXDE
EOF
sleep 1

echo "Desktop entries..."

create_link_system() {
  local file_name=$1
  local name=$2
  local icon=$3
  local url="/usr/share/applications/${file_name}.desktop"
  local output_file="${HOME}/Desktop/${file_name}.desktop"

  cat <<EOF > "${output_file}" 
[Desktop Entry]
Type=Link
Name=$name
Icon=$icon
URL=$url
EOF
  sleep 1
}

create_link_user() {
  local file_name=$1
  local name=$2
  local icon=$3
  local url="${HOME}/.local/share/applications/${file_name}.desktop"
  local exec=$4
  local output_file="${HOME}/Desktop/${file_name}.desktop"

  cat <<EOF > "${output_file}" 
[Desktop Entry]
Type=Link
Name=$name
Icon=$icon
URL=$url
EOF

  cat <<EOF > "${url}" 
[Desktop Entry]
Name=$name
Exec=$exec
Type=Application
Terminal=false
Icon=$icon
Categories=Applications;
EOF

  sleep 1
}

create_link_system "lxterminal" "LXTerminal" "lxterminal" 
create_link_system "pcmanfm" "File Manager" "system-file-manager"
create_link_system "firefox-esr" "Firefox ESR" "firefox-esr"
create_link_system "drawio" "draw.io" "drawio"
create_link_system "org.wireshark.Wireshark" "Wireshark" "org.wireshark.Wireshark"
create_link_system "DiskEditor" "Active@ Disk Editor" "DiskEditor"

create_link_user "autopsy" "Autopsy" "${autopsy_dir}/icon.ico" "${autopsy_dir}/bin/autopsy"
create_link_user "sarchart" "SARchart" "${tools_dir}/sarchart/SARchart.png" "bash -c 'node ${tools_dir}/sarchart/src/index.js & firefox http://localhost:3000'"
create_link_user "cyberchef" "CyberChef" "${cyberchef_dir}/images/cyberchef-128x128.png" "firefox ${cyberchef_dir}/CyberChef_${cyberchef_ver}.html"
create_link_user "timeline" "The Timeline Project" "${timeline_dir}/icons/Timeline.ico" "python3 ${timeline_dir}/source/timeline.py"
create_link_user "memprocfs" "MemProcFS" "system" "lxterminal -e 'bash -c \"${memprocfs_dir}/memprocfs; exec bash\"'"
create_link_user "bulkextractor" "Bulk Extractor" "system" "lxterminal -e 'bash -c \"bulk_extractor -h; exec bash\"'"

echo "System clean up..."
sudo apt-get remove -y cups cups-client cups-common xsane xsane-common deluge deluge-common deluge-gtk \
    lynx lynx-common libreoffice-writer libreoffice-math mesa-vulkan-drivers system-config-printer \
    speech-dispatcher audacious mpv
sudo apt-get autoremove -y
sudo apt-get autoclean -y
sudo apt-get clean -y
dpkg --list | grep "^rc" | cut -d " " -f 3 | xargs sudo dpkg --purge

source "${HOME}"/.bashrc

echo "DFI setup done - reboot the system to apply the change"
