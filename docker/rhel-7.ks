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
part / --size 3000 --fstype ext4

%packages --excludedocs --nobase --nocore --instLangs=en
bash
findutils
gdb-gdbserver
kexec-tools
python-rhsm
rootfiles
subscription-manager
systemd
vim-minimal
yum
yum-plugin-ovl
yum-utils
-e2fsprogs
-firewalld
-kernel
-kexec-tools
-xfsprogs
%end

%pre
touch /tmp/NOSAVE_LOGS
%end

%post --log=/anaconda-post.log

#rpm -e kernel
yum -y remove linux-firmware
yum -y reinstall sudo 
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

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

%end