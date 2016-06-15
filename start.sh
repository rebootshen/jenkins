#!/bin/bash
# Starts up jenkins svn mail server  within the container.

# Stop on error
set -e

#ln -s /jenkins-data/ /svn

/etc/init.d/jenkins start
/opt/sonar/bin/linux-x86-64/sonar.sh start
/usr/sbin/httpd -k start
/usr/sbin/postfix start
/usr/sbin/sshd

touch /var/log/jenkins/jenkins.log
chown -R jenkins.jenkins /var/log/jenkins/jenkins.log
tail -f /var/log/jenkins/jenkins.log
