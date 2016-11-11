#!/bin/bash
# Starts up jenkins svn mail server  within the container.

# Stop on error
set -e

touch /var/log/jenkins/jenkins.log
chown -R jenkins.jenkins /var/log/jenkins/jenkins.log

/etc/init.d/jenkins start
/opt/sonar/bin/linux-x86-64/sonar.sh start
/usr/sbin/httpd -k start
/usr/sbin/postfix start
/usr/sbin/sshd
rm -rf /backup/key/id_rsa*
/usr/bin/ssh-keygen -q -t rsa -N '' -f /backup/key/id_rsa

tail -f /var/log/jenkins/jenkins.log
