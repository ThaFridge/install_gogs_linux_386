#!/bin/bash
## Install Gogs v0.11.4 + Nginx Webserver + Mysql
## On Debian, Ubuntu 64Bits
## Author: Nilton OS -- www.linuxpro.com.br
## Version: 3.5

### Tested on Ubuntu 16.04 LTS 64Bits
### Tested on Debian 8/9 32Bits

echo 'install_gogs_ubuntu.sh'
echo 'Support Ubuntu/Debian'
echo 'Installs Gogs 0.11.4'
echo 'Requires Ubuntu 16.04+, Debian 8+'


# Check if user has root privileges
if [[ $EUID -ne 0 ]]; then
echo "You must run the script as root or using sudo"
   exit 1
fi

MY_IP=$(ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}' | tr '\n' ' ')

echo -e "Set Server Name Ex: git.domain.com []: \c "
read  SERVER_FQDN

echo -e "Set Server IP Ex: $MY_IP []: \c "
read  SERVER_IP

echo "" >>/etc/hosts
echo "$SERVER_IP  $SERVER_FQDN" >>/etc/hosts
hostnamectl set-hostname $SERVER_FQDN
echo "$SERVER_FQDN" > /proc/sys/kernel/hostname

apt-get update
apt-get install -y wget nginx git-core mysql-client mysql-server
adduser --disabled-login --gecos 'Gogs' git

cd /home/git
wget --no-check-certificate https://dl.gogs.io/0.11.4/linux_386.zip
tar -xvf linux_386.zip && rm -f linux_386.zip

echo -e "Set Password for Gogs in Mysql Ex: gogs_password : \c "
read  GOGS_PASS

echo "Enter Mysql root password"
echo "CREATE USER 'gogs'@'localhost' IDENTIFIED BY $GOGS_PASS;" >>/home/git/gogs/scripts/mysql.sql
echo "GRANT ALL PRIVILEGES ON gogs.* TO 'gogs'@'localhost';" >>/home/git/gogs/scripts/mysql.sql 

echo "--------------------"
mysql -p < /home/git/gogs/scripts/mysql.sql

chmod +x /home/git/gogs/gogs
mkdir -p /home/git/gogs/log

chown -R git:git /home/git/gogs
chown -R git:git /home/git/gogs/*


echo ""
echo "Setup Webserver Nginx"
echo "--------------------"

cp /home/git/gogs/scripts/systemd/gogs.service /etc/systemd/system/
sed -i 's|mysqld.service|mysqld.service mysql.service|' /etc/systemd/system/gogs.service

systemctl daemon-reload
systemctl enable gogs.service
systemctl start gogs.service


echo 'server {
    listen          YOUR_SERVER_IP:80;
    server_name     YOUR_SERVER_FQDN;

    proxy_set_header X-Real-IP  $remote_addr; # pass on real client IP

    location / {
        proxy_pass http://localhost:3000;
    }
}' > /etc/nginx/sites-available/gogs.conf

ln -s /etc/nginx/sites-available/gogs.conf /etc/nginx/sites-enabled/gogs.conf

sed -i "s/YOUR_SERVER_IP/$SERVER_IP/" /etc/nginx/sites-available/gogs.conf
sed -i "s/YOUR_SERVER_FQDN/$SERVER_FQDN/" /etc/nginx/sites-available/gogs.conf

service nginx restart

echo ""
echo "Gogs Server App run on port 3000, Nginx on port 80"
echo "Access http://$SERVER_FQDN to continue the installation"
echo ""

echo "Screencast Install: http://www.linuxpro.com.br/2017/04/instalando-gogs-no-ubuntu/"

## Links
## http://gogs.io/docs/installation/install_from_source.html
## http://gogs.io/
## https://github.com/gogits/gogs/
## https://github.com/gogits/gogs/blob/master/conf/app.ini