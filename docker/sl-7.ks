# Basic setup information
url --url="http://ftp.scientificlinux.org/linux/scientific/7x/x86_64/os/"
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
repo --name="SL" --baseurl=http://ftp.scientificlinux.org/linux/scientific/7x/x86_64/os/ --cost=100
repo --name="SL Updates" --baseurl=http://ftp.scientificlinux.org/linux/scientific/7x/x86_64/updates/ --cost=100

# Disk setup
zerombr
clearpart --all --initlabel
part / --size 3000 --fstype ext4

# Package setup
%packages --instLangs=en --nocore
bind-utils
bash
yum
sudo
openssh-clients
vim
centos-release
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
yum-plugin-versionlock
man-pages
man-db
man
bash-completion
wget
deltarpm
dos2unix

%end

%pre

# Don't add the anaconda build logs to the image
# see /usr/share/anaconda/post-scripts/99-copy-logs.ks
touch /tmp/NOSAVE_LOGS
%end

%post --log=/anaconda-post.log

# remove stuff we don't need that anaconda insists on
# kernel needs to be removed by rpm, because of grubby
rpm -e kernel
  
yum -y remove bind-libs bind-libs-lite dhclient dhcp-common dhcp-libs \
  dracut-network e2fsprogs e2fsprogs-libs ebtables ethtool file \
  firewalld freetype gettext gettext-libs grub2 grub2-tools \
  grubby initscripts iproute iptables kexec-tools libcroco libgomp \
  libmnl libnetfilter_conntrack libnfnetlink libselinux-python lzo \
  libunistring os-prober python-decorator python-slip python-slip-dbus \
  snappy sysvinit-tools linux-firmware GeoIP firewalld-filesystem \
  qemu-guest-agent

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

#LANG="en_US"
#echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

awk '(NF==0&&!done){print "override_install_langs=en_US.utf8";done=1}{print}' \
    < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf
echo 'container' > /etc/yum/vars/infra

##Setup locale properly
# Commenting out, as this seems to no longer be needed
#rm -f /usr/lib/locale/locale-archive
#localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

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

#Upgrade to the latest
yum -y upgrade

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

%end
