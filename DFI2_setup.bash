#!/bin/bash
# DFI2 (Digital Forensics & Incident Investigation) setup
# bash DFI2_setup.bash

tools_dir="${HOME}/tools"
sleuthkit_ver="4.12.0"
sleuthkit_file="sleuthkit-java_${sleuthkit_ver}-1_amd64.deb"
sleuthkit_dl="https://github.com/sleuthkit/sleuthkit/releases/download/sleuthkit-${sleuthkit_ver}/${sleuthkit_file}"
autopsy_ver="4.20.0"
autopsy_file="autopsy-${autopsy_ver}.zip"
autopsy_dl="https://github.com/sleuthkit/autopsy/releases/download/autopsy-${autopsy_ver}/${autopsy_file}"
autopsy_dir="${HOME}/tools/autopsy-${autopsy_ver}"
drawio_ver="21.6.5"
drawio_file="drawio-amd64-${drawio_ver}.deb"
drawio_dl="https://github.com/jgraph/drawio-desktop/releases/download/v${drawio_ver}/${drawio_file}"
timeline_ver="2.8.0"
timeline_file="timeline-${timeline_ver}.zip"
timeline_dl="http://sourceforge.net/projects/thetimelineproj/files/thetimelineproj/${timeline_ver}/${timeline_file}/download"
cyberchef_ver="v10.5.2"
cyberchef_file="CyberChef_${cyberchef_ver}.zip"
cyberchef_dl="https://gchq.github.io/CyberChef/${cyberchef_file}"
diskeditor_file="DiskEditor.tar.gz"
diskeditor_install="DiskEditor_Linux_Installer.run"
diskeditor_dl="https://www.disk-editor.org/download/DiskEditor.tar.gz"

cd ${HOME}
mkdir -p ${tools_dir}

source /etc/os-release

if [ $DISPLAY ] && [ $ID == "ubuntu" ] && [ ${VERSION_ID:0:1} == "2" ]; then
    echo "Supported. Continue..."
elif [ $DISPLAY ] && [ $ID == "debian" ] && [ ${VERSION_ID} -gt  10 ]; then
    echo "Supported. Continue..."
else
    echo "The script doesn't support in the machine."
	exit 1
fi

echo "Installing forensic utilities..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ext4magic extundelete git john libewf-dev libewf2 mg netcat-traditional openssh-server python3-libewf ripgrep ssdeep strace sysstat wireshark xxd zip
sudo systemctl disable ssh
sudo systemctl stop ssh

echo "Installing dependencies for Autopsy..."
sudo apt-get update
sudo apt-get install -y build-essential autoconf libtool automake ant libde265-dev libheif-dev libpq-dev \
    testdisk libafflib-dev libewf-dev libvhdi-dev libvmdk-dev \
    libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x \
    gstreamer1.0-alsa gstreamer1.0-gl gstreamer1.0-gtk3 gstreamer1.0-qt5 gstreamer1.0-pulseaudio flatpak

if [[ $? -ne 0 ]]; then
    echo "Failed to install dependencies for Autopsy" >>/dev/stderr
    exit 1
fi

echo "Installing bellsoft Java 8..."
wget -q -O - https://download.bell-sw.com/pki/GPG-KEY-bellsoft | sudo apt-key add - &&
echo "deb [arch=amd64] https://apt.bell-sw.com/ stable main" | sudo tee /etc/apt/sources.list.d/bellsoft.list &&
sudo apt-get update && sudo apt-get install -y bellsoft-java8-full bellsoft-java8-runtime-full

if [[ $? -ne 0 ]]; then
    echo "Failed to install bellsoft Java 8" >>/dev/stderr
    exit 1
fi

export JAVA_HOME="/usr/lib/jvm/bellsoft-java8-full-amd64"
export JDK_HOME="${JAVA_HOME}"
export PATH="${JAVA_HOME}/bin:${PATH}"
sudo echo "JAVA_HOME='/usr/lib/jvm/bellsoft-java8-full-amd64'" >> ${HOME}/.bashrc

echo "Installing SleuthKit..."
sudo dpkg --configure -a
cd $HOME
wget ${sleuthkit_dl}
sudo dpkg -i ${sleuthkit_file}
sudo apt-get -y install -f

echo "Installing Autopsy..."
cd $HOME
wget ${autopsy_dl}
unzip ${autopsy_file} -d ${tools_dir}
echo "jdkhome=/usr/lib/jvm/bellsoft-java8-full-amd64" >> ${autopsy_dir}/etc/autopsy.conf
echo "JAVA_HOME=/usr/lib/jvm/bellsoft-java8-full-amd64" >> ${autopsy_dir}/etc/autopsy.conf
echo "JDK=/usr/lib/jvm/bellsoft-java8-full-amd64" >> ${autopsy_dir}/etc/autopsy.conf

jdkhome=$JAVA_PATH
cd ${autopsy_dir}
chmod u+x unix_setup.sh
bash ./unix_setup.sh -j /usr/lib/jvm/bellsoft-java8-full-amd64
echo "Launching Autopsy...push OK, close, then exit the app"
${autopsy_dir}/bin/autopsy --nosplash
find ${autopsy_dir} -name "*.exe" -type f -exec rm {} \;
find ${autopsy_dir} -name "*.dll" -type f -exec rm {} \;
rm -rf ${autopsy_dir}/autopsy/plaso/*

echo "Installing Bulk Extractor..."
cd $HOME
git clone --recurse-submodules https://github.com/simsong/bulk_extractor.git 
MPKGS="flex gcc md5deep openssl patch g[+][+] libssl-dev libexpat1-dev libewf-dev libewf2 python3-libewf zlib1g-dev libxml2-dev libjson-c-dev"
sudo apt-get install -y $MPKGS
cd ${HOME}/bulk_extractor
./bootstrap.sh
./configure
make
sudo make install
if [[ $? -ne 0 ]]; then
    echo "Failed to install Bulk Extractor" >>/dev/stderr
    exit 1
fi

echo "Installing drawio..."
cd $HOME
wget ${drawio_dl}
sudo dpkg -i ${drawio_file}

echo "Installing Timeline..."
cd ${HOME}
wget ${timeline_dl} -O ${timeline_file}
unzip ${timeline_file} -d ${tools_dir}
cd ${tools_dir}/timeline-${timeline_ver}
sudo apt-get install -y python3-pip python3-wxgtk4.0 python3-icalendar python3-markdown
if [ $ID == "debian" ] && [ ${VERSION_ID} == 12 ]; then
    pip install --break-system-packages --user git+https://github.com/thetimelineproj/humblewx.git
else
    pip install --user git+https://github.com/thetimelineproj/humblewx.git
fi
if [[ $? -ne 0 ]]; then
    echo "Failed to install Timeline" >>/dev/stderr
    exit 1
fi

echo "Installing SARchart..."
cd ${tools_dir}
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
cd ${HOME}
wget ${cyberchef_dl}
unzip ${cyberchef_file} -d ${tools_dir}/cyberchef_${cyberchef_ver}

echo "Installing Active Disk Editor..."
cd ${HOME}
wget ${diskeditor_dl}
tar xvzf ${diskeditor_file}
sudo ${HOME}/${diskeditor_install}

echo "Config and clean-up..."
cd $HOME
mkdir $HOME/cases
mkdir $HOME/evidence
rm -rf bulk_extractor ${autopsy_file} ${sleuthkit_file} ${drawio_file} ${timeline_file} ${cyberchef_file} ${diskeditor_file} ${diskeditor_install}

if [ ${XDG_CURRENT_DESKTOP^^} != "LXDE" ]; then
    echo "No LXDE...skip desktop/menu config. DFI setup - done"
    exit 0
fi

echo "Desktop entries..."
cat <<EOF > ${HOME}/Desktop/lxterminal.desktop
[Desktop Entry]
Type=Link
Name=LXTerminal
Icon=lxterminal
URL=/usr/share/applications/lxterminal.desktop
EOF

cat <<EOF > ${HOME}/Desktop/pcmanfm.desktop
[Desktop Entry]
Type=Link
Name=File Manager
Icon=system-file-manager
URL=/usr/share/applications/pcmanfm.desktop
EOF

cat <<EOF > ${HOME}/Desktop/firefox-esr.desktop
[Desktop Entry]
Type=Link
Name=Firefox ESR
Icon=firefox-esr
URL=/usr/share/applications/firefox-esr.desktop
EOF

cat <<EOF > ${HOME}/Desktop/autopsy.desktop
[Desktop Entry]
Type=Link
Name=Autopsy
Icon=${tools_dir}/autopsy-${autopsy_ver}/icon.ico
URL=${HOME}/.local/share/applications/autopsy.desktop
EOF

cat <<EOF > ${HOME}/.local/share/applications/autopsy.desktop
[Desktop Entry]
Name=Autopsy
Exec=${tools_dir}/autopsy-${autopsy_ver}/bin/autopsy
Type=Application
Terminal=false
Icon=${tools_dir}/autopsy-${autopsy_ver}/icon.ico
Categories=Applications;
EOF

cat <<EOF > ${HOME}/Desktop/drawio.desktop
[Desktop Entry]
Type=Link
Name=drawio
Icon=drawio
URL=/usr/share/applications/drawio.desktop
EOF

cat <<EOF > ${HOME}/Desktop/sarchart.desktop
[Desktop Entry]
Type=Link
Name=SARchart
Icon=${tools_dir}/sarchart/SARchart.png
URL=${HOME}/.local/share/applications/sarchart.desktop
EOF

cat <<EOF > ${HOME}/.local/share/applications/sarchart.desktop
[Desktop Entry]
Name=SARchart
Exec=bash -c 'node ${tools_dir}/sarchart/src/index.js & firefox http://localhost:3000'
Type=Application
Terminal=false
Icon=${tools_dir}/sarchart/SARchart.png
Categories=Applications;
EOF

cat <<EOF > ${HOME}/Desktop/timline.desktop
[Desktop Entry]
Type=Link
Name=Timeline
Icon=${tools_dir}/timeline-${timeline_ver}/icons/Timeline.ico
URL=${HOME}/.local/share/applications/timeline.desktop
EOF

cat <<EOF > ${HOME}/.local/share/applications/timeline.desktop
[Desktop Entry]
Name=Timeline
Exec=python3 ${tools_dir}/timeline-${timeline_ver}/source/timeline.py
Type=Application
Terminal=false
Icon=${tools_dir}/timeline-${timeline_ver}/icons/Timeline.ico
Categories=Applications;
EOF

cat <<EOF > ${HOME}/Desktop/bulkextractor.desktop
[Desktop Entry]
Type=Link
Name=Bulk Extractor
Icon=system
URL=${HOME}/.local/share/applications/bulkextractor.desktop
EOF

cat <<EOF > ${HOME}/.local/share/applications/bulkextractor.desktop
[Desktop Entry]
Name=Bulk Extractor
Exec=lxterminal -e 'bash -c "bulk_extractor -h; exec bash"'
Type=Application
Terminal=false
Icon=system
Categories=Applications;
EOF

cat <<EOF > ${HOME}/.local/share/applications/org.wireshark.Wireshark.desktop
[Desktop Entry]
Type=Link
Name=Wireshark
Icon=org.wireshark.Wireshark
URL=/usr/share/applications/org.wireshark.Wireshark.desktop
EOF

cat <<EOF > ${HOME}/Desktop/cyberchef.desktop
[Desktop Entry]
Type=Link
Name=CyberChef
Icon=${tools_dir}/cyberchef_${cyberchef_ver}/images/cyberchef-128x128.png
URL=${HOME}/.local/share/applications/cyberchef.desktop
EOF

cat <<EOF > ${HOME}/.local/share/applications/cyberchef.desktop
[Desktop Entry]
Name=CyberChef
Exec=firefox ${tools_dir}/cyberchef_${cyberchef_ver}/CyberChef_${cyberchef_ver}.html
Icon=${tools_dir}/cyberchef_${cyberchef_ver}/images/cyberchef-128x128.png
Type=Application
Terminal=false
Categories=Applications;
EOF

cat <<EOF > ${HOME}/Desktop/diskeditor.desktop
[Desktop Entry]
Type=Link
Name=Active@ Disk Editor
URL=/usr/share/applications/DiskEditor.desktop
Icon=DiskEditor
EOF

wget https://raw.githubusercontent.com/4n6ist/DFI2/main/.config/lxpanel/LXDE/panels/panel -O ${HOME}/.config/lxpanel/LXDE/panels/panel

echo "DFI setup - done"
