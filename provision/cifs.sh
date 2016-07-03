yum groupinstall -y "file-server"
yum install -y samba-client samba-winbind
cat << EOF > /etc/samba/smb.conf
workgroup = MYGROUP
server string = Samba Server Version %v
netbios name = MYSERVER
interfaces = lo eth0 192.168.0.0/16
hosts allow = 127., 192.168.
log file = /var/log/samba/log.%m
max log size = 50
security = user
passdb backend = tdbsam
[shared]
comment = Shared directory
browseable = yes
path = /shared
valid users = user01
writable = yes
EOF

mkdir /shared
chmod 777 /shared

yum install -y setroubleshoot-server
semanage fcontext -a -t samba_share_t "/shared(/.*)?"
restorecon -R /shared

firewall-cmd --permanent --add-service=samba
firewall-cmd --reload

systemctl enable smb
systemctl enable nmb
systemctl enable winbind
systemctl start smb
systemctl start nmb
systemctl start winbind

useradd -s /sbin/nologin user01
printf "user01\nuser01\n" | smbpasswd -a -s user01

