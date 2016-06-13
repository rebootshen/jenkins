#!/bin/bash
# Starts up jenkins svn mail server  within the container.

# Stop on error
set -e

#ln -s /jenkins-data/ /svn

/etc/init.d/jenkins start
/usr/sbin/httpd -k start
/usr/sbin/postfix start

touch /var/log/jenkins/jenkins.log
chown -R jenkins.jenkins /var/log/jenkins/jenkins.log
tail -f /var/log/jenkins/jenkins.log
