# docker image with networking tool and web browse
# it has putty, nmap, ftp, telnetd, tftpd and apache2

FROM gns3/webterm

RUN set -ex \
#
# install needed tools
#
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get -y --no-install-recommends install \
        rsyslog putty nmap tftpd-hpa tftp telnetd ftp proftpd-basic openssh-server apache2 \
#
# start with apache2 configuration
# enable mode "include"
#
    && a2enmod include \
#
# now include the line "ServerName localhost" to avoid the message "apache2: Could not reliably determine the server's fully qualified domain name, using 172.17.0.2. Set the 'ServerName' directive globally to suppress this message"
#
    && sed -i '/ServerRoot \"\/etc\/apache2\"/a ServerName localhost' /etc/apache2/apache2.conf \
#
# Change "AllowOverride None" to "AllowOverride All" in the directory /var/www/ to allow
# processing of the ".htaccess" file
#
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ { s/AllowOverride None/AllowOverride All/ }' /etc/apache2/apache2.conf \ 
#
# add a ".htaccess" file in /var/www/html
#
    && /bin/echo -e '\
\x23 This will make files in this folder answer to system variables \n\
Options +Includes\n\
XBitHack on\n' \
        > /var/www/html/.htaccess \
#
# now we create the index.html page
#
    && /bin/echo -e '\
\x23 \n\
<!DOCTYPE html>\n\
<html>\n\
  <head>\n\
    <title> My home page ! </title>\n\
  </head>\n\
\n\
  <body>\n\
    <p>\n\
    It works !! <br> \n\
    <b>My IP:             <!--#echo var="REMOTE_ADDR"--> </b> <br>\n\
    <b>This server IP is: <!--#echo var="SERVER_ADDR"--> </b> <br>\n\
    </p>\n\
  </body>\n\
</html>\n' \
        > /var/www/html/index.html \
    && chmod 744 /var/www/html/index.html \
#
# Configuration of telnetd to allow "root" access
# and change the root password to a known one
#
    && /bin/echo -e '\
\x23 \n\
pts/0\n\
pts/1\n\
pts/2\n\
pts/3\n\
pts/4\n\
pts/5\n\
pts/6\n\
pts/7\n\
pts/8\n\
pts/9\n' \
        >> /etc/securetty \
    && /bin/echo -e 'pass\npass' | passwd -q \
#
# the next step is to configure proftpd
# starting by uncommenting all lines between <Anonymous ~ftp> and </Anonymous>
# and add a line to allow root login
#
    && sed -i '/# <Anonymous ~ftp>/,/# <\/Anonymous>/ { s/# //;s/^#// }' /etc/proftpd/proftpd.conf \
    && /bin/echo -e '\
\x23 \n\
RootLogin on\n' \
        >> /etc/proftpd/proftpd.conf \
    && sed -i '/root/d' /etc/ftpusers \
#
# openssh configuration to allow root login
#
    && sed -i '{ s/PermitRootLogin without-password/PermitRootLogin yes/ }' /etc/ssh/sshd_config \
#
# tftp configurationto allow the creation of files in the /srv/tftp directory
#
    && chmod -R 777 /srv/tftp \
    && sed -i '{ s/TFTP_OPTIONS="--secure"/TFTP_OPTIONS="--secure --create"/ }' /etc/default/tftpd-hpa \
#
# start everything !!!!!
#
    && sed -i '/^start-firefox/i\/etc\/init.d\/ssh start\n\/etc\/init.d\/openbsd-inetd start\n\/etc\/init.d\/apache2 start\n\/etc\/init.d\/proftpd start\n\/etc\/init.d\/tftpd-hpa start\n\/etc\/init.d\/rsyslog start' /etc/init.sh
