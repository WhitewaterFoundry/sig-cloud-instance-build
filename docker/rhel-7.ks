# Basic setup information
url --url=""
install
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
part / --size 1500 --fstype ext4

# Package setup
%packages --nobase --nocore --instLangs=en
bind-utils
bash
yum
vim
subscription-manager
less
-kernel*
-*firmware
-firewalld-filesystem
-os-prober
-gettext*
-GeoIP
-bind-license
-freetype
iputils
iproute
systemd
rootfiles
-libteam
-teamd
tar
passwd
yum-utils
yum-plugin-ovl
man-pages
man-db
man
bash-completion
wget

%end

%pre
touch /tmp/NOSAVE_LOGS
%end

%post --log=/anaconda-post.log

rpm -e kernel
yum -y remove linux-firmware qemu-guest-agent
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
rm -rf /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/*

## Systemd fixes
:> /etc/machine-id
umount /run
systemd-tmpfiles --create --boot
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
