yum install -y telnet net-tools openldap openldap-clients openldap-servers migrationtools lsof vim
slappasswd -s redhat -n > /etc/openldap/passwd
NEWPASS=`cat /etc/openldap/passwd`
openssl req -new -x509 -nodes -out /etc/openldap/certs/cert.pem -keyout /etc/openldap/certs/priv.pem -days 365 -subj '/C=DE/ST=Munich/L=Bayern/CN=www.kilduff.de'
chown -R ldap:ldap /etc/openldap/certs/
chmod 600 /etc/openldap/certs/priv.pem 
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap
systemctl enable slapd
systemctl start slapd
netstat -anlp |grep slap
cd /etc/openldap/schema
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -D "cn=config" -f nis.ldif
cat <<EOF > /etc/openldap/changes.ldif
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=example,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=example,dc=com

dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootPW
olcRootPW: $NEWPASS

dn: cn=config
changetype: modify
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/openldap/certs/cert.pem

dn: cn=config
changetype: modify
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/openldap/certs/priv.pem

dn: cn=config
changetype: modify
replace: olcLogLevel
olcLogLevel: -1

dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=example,dc=com" read by * none
EOF
ldapmodify -Y EXTERNAL -H ldapi:/// -f /etc/openldap/changes.ldif
cat <<EOF > /etc/openldap/base.ldif
dn: dc=example,dc=com
dc: example
objectClass: top
objectClass: domain

dn: ou=People,dc=example,dc=com
ou: People
objectClass: top
objectClass: organizationalUnit

dn: ou=Group,dc=example,dc=com
ou: Group
objectClass: top
objectClass: organizationalUnit
EOF
ldapadd -x -w redhat -D cn=Manager,dc=example,dc=com -f /etc/openldap/base.ldif
mkdir /home/guests
useradd -d /home/guests/ldapuser01 ldapuser01
echo -e "user01\nuser01" | (passwd --stdin ldapuser01)
useradd -d /home/guests/ldapuser02 ldapuser02
echo -e "user02\nuser02" | (passwd --stdin ldapuser02)
cd /usr/share/migrationtools
sed -i s/padl/example/g /usr/share/migrationtools/migrate_common.ph
grep ":10[0-9][0-9]" /etc/passwd |grep -v vagrant > passwd
./migrate_passwd.pl passwd users.ldif
ldapadd -x -w redhat -D cn=Manager,dc=example,dc=com -f users.ldif
grep ":10[0-9][0-9]" /etc/group|grep -v vagrant > groups
./migrate_group.pl groups groups.ldif
ldapadd -x -w redhat -D cn=Manager,dc=example,dc=com -f groups.ldif

