# Basic setup information
url --url="http://rhel.whitewaterfoundry.com/rhel-7-workstation-rpms/"
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

# Repositories to use
repo --name="rhel-7-workstation-rpms" --baseurl=http://rhel.whitewaterfoundry.com/rhel-7-workstation-rpms/ --cost=100
repo --name="rhel-7-optional-rpms" --baseurl=http://rhel.whitewaterfoundry.com/rhel-7-workstation-optional-rpms/ --cost=100
repo --name="rhel-7-extra-rpms" --baseurl=http://rhel.whitewaterfoundry.com/rhel-7-workstation-extra-rpms/ --cost=100

# Disk setup
zerombr
clearpart --all --initlabel
part / --size 1500 --fstype ext4

%packages --excludedocs --nobase --nocore --instLangs=en
bind-utils
bash
yum
vim-minimal
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
%end

%pre
touch /tmp/NOSAVE_LOGS
%end

%post --log=/anaconda-post.log

rpm -e kernel
yum -y remove bind-libs bind-libs-lite dhclient dhcp-common dhcp-libs \
  dracut-network e2fsprogs e2fsprogs-libs ebtables ethtool file \
  firewalld freetype gettext gettext-libs groff-base grub2 grub2-tools \
  grubby initscripts iproute iptables kexec-tools libcroco libgomp \
  libmnl libnetfilter_conntrack libnfnetlink libselinux-python lzo \
  libunistring os-prober python-decorator python-slip python-slip-dbus \
  snappy sysvinit-tools which linux-firmware GeoIP firewalld-filesystem \
  qemu-guest-agent
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