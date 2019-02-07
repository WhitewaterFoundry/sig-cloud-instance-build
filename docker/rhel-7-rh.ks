
# Use network installation
url --url=""
install
# Firewall configuration
firewall --disabled
firstboot --disable
ignoredisk --only-use=vda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts=''
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Shutdown after installation
shutdown
# Root password
rootpw --iscrypted --lock locked
# System services
# services --disabled="chronyd"
# Do not configure the X Window System
# skipx
# System timezone
timezone UTC --isUtc --nontp
# user --name=none
# System bootloader configuration
bootloader --disabled
autopart --type=plain
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all

%post --logfile=/var/log/anaconda/anaconda-post.log

#RCM-18944 - forcibly remove qemu-guest-agent if still present
#https://bugzilla.redhat.com/show_bug.cgi?id=1475781
# yum --assumeyes erase qemu-guest-agent

#https://bugzilla.redhat.com/show_bug.cgi?id=1536174
# yum --assumeyes erase blktrace ethtool fuse-libs groff-base hostname initscripts iproute iptables iputils libaio libmnl libnetfilter_conntrack libnfnetlink libsysfs lsscsi mariadb-libs perl perl-Carp perl-Data-Dumper perl-Encode perl-Exporter perl-File-Path perl-File-Temp perl-Filter perl-Getopt-Long perl-HTTP-Tiny perl-PathTools perl-Pod-Escapes perl-Pod-Perldoc perl-Pod-Simple perl-Pod-Usage perl-Scalar-List-Utils perl-Socket perl-Storable perl-Text-ParseWords perl-Time-HiRes perl-Time-Local perl-constant perl-libs perl-macros perl-parent perl-podlators perl-threads perl-threads-shared psmisc rsync s390utils s390utils-base s390utils-cmsfs s390utils-cpuplugd s390utils-iucvterm s390utils-mon_statd s390utils-osasnmpd s390utils-ziomon sg3_utils sg3_utils-libs sysfsutils systemd-sysv sysvinit-tools tcp_wrappers-libs device-mapper-multipath device-mapper-multipath-libs net-snmp net-snmp-agent-libs net-snmp-libs

# remove the user anaconda forces us to make
# userdel -r none

# Support for subscription-manager secrets
ln -s /run/secrets/etc-pki-entitlement /etc/pki/entitlement-host
ln -s /run/secrets/rhsm /etc/rhsm-host

# Set the language rpm nodocs transaction flag persistently in the
# image yum.conf and rpm macros

LANG="en_US"
echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

awk '(NF==0&&!done){print "override_install_langs='$LANG'\ntsflags=nodocs";done=1}{print}' \
    < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf

#systemd wrongly expects "unpopulated /etc" when /etc/machine-id does not exist
#let's leave machine-id empty
cat /dev/null > /etc/machine-id

#https://bugzilla.redhat.com/show_bug.cgi?id=1235969
#rm -f /etc/fstab
#this is not possible, guestmount needs fstab => brew build crashes without it
#fstab is removed in TDL when tar-ing files

rm -f /usr/lib/locale/locale-archive
#setup at least some locale, https://bugzilla.redhat.com/show_bug.cgi?id=1129697
localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

#https://bugzilla.redhat.com/show_bug.cgi?id=1201663
rm -f /etc/systemd/system/multi-user.target.wants/rhsmcertd.service

#Mask mount units and getty service so that we don't get login prompt
#https://bugzilla.redhat.com/show_bug.cgi?id=1418327
systemctl mask systemd-logind.service getty.target console-getty.service sys-fs-fuse-connections.mount
#systemd-remount-fs.service dev-hugepages.mount  ?

#content of /run can not be prepared if /run is tmpfs (disappears on reboot)
umount /run
systemd-tmpfiles --create

#fips mode
# secrets patch creates /run/secrets/system-fips if /etc/system-fips exists on the host
#in turn, openssl in the container checks /etc/system-fips but dangling symlink counts as nonexistent
ln -s /run/secrets/system-fips /etc/system-fips

#udev hardware database not needed in a container
rm -f /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/*
rm -rf /var/cache/yum/*
rm -f /tmp/ks-script*

%end

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

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end