yum install -y httpd elinks
[ -d /http ] || mkdir /http
restorecon -R /http
cat << EOF > /etc/httpd/conf.d/custom.conf
<VirtualHost *:80>
  ServerAdmin webmaster@example.com
  DocumentRoot /httpd/
  ServerName example.com
  ErrorLog logs/example.com-error_log
  CustomLog logs/example.com-access_log common
</VirtualHost>
EOF
systemctl enable httpd
systemctl start httpd
