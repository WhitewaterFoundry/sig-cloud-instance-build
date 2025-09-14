# bashsupport disable=BP5007
# Basic setup information
cdrom
keyboard us
rootpw --lock --iscrypted locked
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --disabled
network --bootproto=dhcp --device=link --activate --onboot=on --noipv6
shutdown
bootloader --location=none
lang en_US.UTF-8

# Disk setup
zerombr
clearpart --all --initlabel
part / --size 5000 --fstype ext4 --grow

#-*firmware
#-firewalld-filesystem

#-os-prober
#-gettext*
#-GeoIP
#-bind-license
#-freetype
#-libteam
#-teamd

# Package setup
%packages --nocore --ignoremissing --instLangs=en
@^minimal-environment
bash
bash-completion
bc
bind-utils
cracklib-dicts
curl
dbus-tools
desktop-file-utils
dialog
dnf
dos2unix
emacs-filesystem
file
glx-utils
iproute
iputils
less
llvm-libs-19.1.7
libglvnd-egl
libmodulemd
libva
libwayland-server
libzstd
man
man-db
man-pages
mesa-dri-drivers
mesa-libEGL
mesa-libGL
mesa-libgbm
mesa-libxatracker
mesa-vulkan-drivers
nano
ncurses
openssh-clients
passwd
pciutils
python3-dnf-plugin-versionlock
rootfiles
rpm
sed
subscription-manager
sudo
systemd
systemd-container
tar
vim-minimal
vim
vim-enhanced
wget
which
yum
yum-utils
-firewalld
-firewalld-filesystem
%end

%pre

# Don't add the anaconda build logs to the image
# see /usr/share/anaconda/post-scripts/99-copy-logs.ks
touch /tmp/NOSAVE_LOGS
%end

%post --log=/anaconda-post.log --interpreter=/usr/bin/bash

# set DNF infra variable to container for compatibility with CentOS
echo 'container' > /etc/dnf/vars/infra

#Add WWF repo
curl -s https://packagecloud.io/install/repositories/whitewaterfoundry/pengwin-enterprise/script.rpm.sh | bash

#Install WSL MESA
declare -a mesa_version=('23.1.4-2_wsl' '24.2.8-2_wsl_2')
declare -a llvm_version=('17.0.6' '19.1.7')
declare -a target_version=('8' '9')
declare -i i=1

dnf -y install --allowerasing --nogpgcheck llvm-libs-"${llvm_version[i]}" mesa-dri-drivers-"${mesa_version[i]}".el"${target_version[i]}" mesa-libGL-"${mesa_version[i]}".el"${target_version[i]}" mesa-vdpau-drivers-"${mesa_version[i]}".el"${target_version[i]}" mesa-libEGL-"${mesa_version[i]}".el"${target_version[i]}" mesa-libgbm-"${mesa_version[i]}".el"${target_version[i]}" mesa-libxatracker-"${mesa_version[i]}".el"${target_version[i]}" mesa-vulkan-drivers-"${mesa_version[i]}".el"${target_version[i]}" glx-utils
dnf versionlock add llvm-libs mesa-dri-drivers mesa-libGL mesa-filesystem mesa-libglapi mesa-vdpau-drivers mesa-libEGL mesa-libgbm mesa-libxatracker mesa-vulkan-drivers

/usr/sbin/groupadd -g 44 wsl-video

#Add WSLU
yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/wslutilities/CentOS_8/home:wslutilities.repo

dnf -y update
dnf -y install wslu

# remove stuff we don't need that anaconda insists on
# kernel needs to be removed by rpm, because of grubby
rpm -e kernel
dnf -y remove linux-firmware qemu-guest-agent

dnf clean all

#clean up unused directories
rm -rf /boot
rm -rf /etc/firewalld

# Lock roots account, keep roots account password-less.
passwd -l root

LANG="en_US"
echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

## Remove some things we don't need
rm -rf /var/cache/yum/x86_64
rm -f /tmp/ks-script*
rm -rf /etc/sysconfig/network-scripts/ifcfg-*
# do we really need a hardware database in a container?
rm -rf /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/*

## Systemd fixes
# no machine-id by default.
:> /etc/machine-id
# Fix /run/lock breakage since it's not tmpfs in docker
umount /run
systemd-tmpfiles --create --boot
# Make sure login works
rm /var/run/nologin

# Some shell tweaks
echo "source /etc/vimrc" > /etc/skel/.vimrc
echo "set background=dark" >> /etc/skel/.vimrc
echo "set visualbell" >> /etc/skel/.vimrc
echo "set noerrorbells" >> /etc/skel/.vimrc

echo "\$include /etc/inputrc" > /etc/skel/.inputrc
echo "set bell-style none" >> /etc/skel/.inputrc
echo "set show-all-if-ambiguous on" >> /etc/skel/.inputrc
echo "set show-all-if-unmodified on" >> /etc/skel/.inputrc

#Fix ping
chmod u+s /usr/bin/ping

# Masking conflicting services"
ln -sf /dev/null /etc/systemd/system/systemd-resolved.service
ln -sf /dev/null /etc/systemd/system/systemd-networkd.service
ln -sf /dev/null /etc/systemd/system/NetworkManager.service
ln -sf /dev/null /etc/systemd/system/NetworkManager-wait-online.service
ln -sf /dev/null /etc/systemd/system/systemd-tmpfiles-setup.service
ln -sf /dev/null /etc/systemd/system/systemd-tmpfiles-clean.service
ln -sf /dev/null /etc/systemd/system/systemd-tmpfiles-clean.timer
ln -sf /dev/null /etc/systemd/system/systemd-tmpfiles-setup-dev-early.service
ln -sf /dev/null /etc/systemd/system/systemd-tmpfiles-setup-dev.service
ln -sf /dev/null /etc/systemd/system/tmp.mount

#Upgrade to the latest
dnf -y upgrade

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

%end
