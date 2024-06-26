# bashsupport disable=BP5007
# Basic setup information
cdrom
keyboard us
rootpw --lock --iscrypted locked
timezone --isUtc --nontp UTC
selinux --enforcing
firewall --disabled
network --bootproto=dhcp --device=link --activate --onboot=on
shutdown
bootloader --disable
lang en_US

# Disk setup
zerombr
clearpart --all --initlabel
part / --size 2000 --fstype ext4

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
deltarpm
cracklib-dicts
curl
desktop-file-utils
dos2unix
emacs-filesystem
file
glx-utils
iproute
iputils
less
libmodulemd
libzstd
man
man-db
man-pages
mesa-dri-drivers
mesa-libGL
nano
openssh-clients
passwd
pciutils
psmisc
rootfiles
rpm
sed
subscription-manager
sudo
systemd
systemd-container
tar
vim
vim-enhanced
wget
which
yum
yum-plugin-ovl
yum-plugin-versionlock
yum-utils
-firewalld
-firewalld-filesystem
-os-prober
%end

%pre

# Don't add the anaconda build logs to the image
# see /usr/share/anaconda/post-scripts/99-copy-logs.ks
touch /tmp/NOSAVE_LOGS
%end

%post --log=/anaconda-post.log

/usr/sbin/groupadd -g 44 wsl-video

# remove stuff we don't need that anaconda insists on
# kernel needs to be removed by rpm, because of grubby
rpm -e kernel
yum -y remove linux-firmware qemu-guest-agent

#Add WSLU
yum-config-manager --add-repo https://download.opensuse.org/repositories/home:/wslutilities/ScientificLinux_7/home:wslutilities.repo
yum -y update
yum -y install wslu

yum clean all

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

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

%end
