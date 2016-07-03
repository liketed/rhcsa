yum install -y vim telnet nc tcpdump net-tools
yum groups mark convert
yum groups mark install 
yum groupinstall -y file-server
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=nfs
firewall-cmd --reload
systemctl enable rpcbind nfs-server
systemctl start rpcbind nfs-server
echo "mkdirs and perms"
mkdir -p /home/tools
chmod 0777 /home/tools
mkdir -p /home/guests
chmod 0777 /home/guests
yum install -y setroubleshoot-server
semanage boolean -l|grep 'nfs\|SELinux'
setsebool -P nfs_export_all_rw on
setsebool -P nfs_export_all_ro on
setsebool -P use_nfs_home_dirs on
semanage boolean -l|grep 'nfs\|SELinux'

semanage fcontext -a -t public_content_rw_t "/home/tools(/.*)?"
semanage fcontext -a -t public_content_rw_t "/home/guests(/.*)?"
restorecon -R /home/tools
restorecon -R /home/guests
echo "echo exports to /etc/exports/"
echo "/home/tools 192.168.0.0/16(rw,no_root_squash)"  >  /etc/exports
echo "/home/guests 192.168.0.0/16(rw,no_root_squash)" >> /etc/exports

systemctl restart rpcbind nfs-server
