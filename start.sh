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
/usr/bin/ssh-keygen -q -t rsa -N '' -f /backup/key/id_rsa

mkdir -p /var/lib/jenkins/jenkins_slave && \
mkdir -p /var/lib/jenkins/.ssh && chmod 700 /var/lib/jenkins/.ssh && \
touch /var/lib/jenkins/.ssh/authorized_keys && chmod 600 /var/lib/jenkins/.ssh/authorized_keys && \
chown -R jenkins.jenkins /var/lib/jenkins

touch /var/log/jenkins/jenkins.log
chown -R jenkins.jenkins /var/log/jenkins/jenkins.log
tail -f /var/log/jenkins/jenkins.log
