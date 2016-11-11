FROM centos:centos7
MAINTAINER "Reboot Shen<reboot.shen@gmail.com>"

ENV JAVA_VERSION 8u92
ENV BUILD_VERSION b14

WORKDIR /opt/

#helpful utils, but only sudo is required
#RUN yum -y install nc
RUN yum -y update && \
	yum -y install wget tar sudo vim initscripts subversion mod_dav_svn postfix unzip git openssh-server net-tools && \
	adduser git

###### JDK8

# Downloading Java
RUN wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/$JAVA_VERSION-$BUILD_VERSION/jdk-$JAVA_VERSION-linux-x64.rpm" -O /tmp/jdk-8-linux-x64.rpm && \
	yum -y install /tmp/jdk-8-linux-x64.rpm && \
	rm -f /tmp/jdk-8-linux-x64.rpm && \
	yum clean all && \

	alternatives --install /usr/bin/java java /usr/java/latest/bin/java 1 && \
	alternatives --install /usr/bin/jar jar /usr/java/latest/bin/jar 1  && \
	alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 1 && \
	echo "JAVA_HOME=/usr/java/latest" >> /etc/environment

##Note that ADD uncompresses this tarball automatically
##ADD jdk-8u91-linux-x64.tar.gz /opt

###### MAVEN

ADD maven.sh /etc/profile.d/
RUN wget http://apache.communilink.net/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz && \
	tar -xzvf apache-maven-3.3.9-bin.tar.gz && \
	rm -rf apache-maven-3.3.9-bin.tar.gz && \
	ln -s /opt/apache-maven-3.3.9 /opt/maven && \
	ln -s /opt/maven/bin/mvn /usr/bin/mvn && \
	chmod +x /etc/profile.d/maven.sh && \ 
	source /etc/profile.d/maven.sh 

###### GRADLE

ADD gradle-env.sh /etc/profile.d/
RUN wget https://services.gradle.org/distributions/gradle-2.13-bin.zip && \
	unzip gradle-2.13-bin.zip ; rm -rf gradle-2.13-bin.zip && \
	ln -s gradle-2.13 gradle && \
    chmod +x /etc/profile.d/gradle-env.sh && \
    source /etc/profile.d/gradle-env.sh

###### JENKINS2.19

RUN wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo && \
	rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key && \
	wget http://pkg.jenkins.io/redhat-stable/jenkins-2.19.2-1.1.noarch.rpm && \
	yum -y install jenkins-2.19.2-1.1.noarch.rpm && \

    sed -ri "s/8080/8090/g" /etc/sysconfig/jenkins && \
	sed -ri "s/8009/8019/g" /etc/sysconfig/jenkins && \
	mkdir -p /var/lib/jenkins/.ssh && chmod 700 /var/lib/jenkins/.ssh && \
    touch /var/lib/jenkins/.ssh/authorized_keys && chmod 600 /var/lib/jenkins/.ssh/authorized_keys


###### SONAR

RUN wget https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-5.6.1.zip && \
	wget https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-2.6.1.zip && \
	wget https://sonarsource.bintray.com/Distribution/sonar-java-plugin/sonar-java-plugin-4.1.jar && \
	wget https://sonarsource.bintray.com/Distribution/sonar-javascript-plugin/sonar-javascript-plugin-2.14.jar && \
	wget https://sonarsource.bintray.com/Distribution/sonar-csharp-plugin/sonar-csharp-plugin-5.3.2.jar && \

	wget http://central.maven.org/maven2/org/sonarsource/sonar-findbugs-plugin/sonar-findbugs-plugin/3.3/sonar-findbugs-plugin-3.3.jar && \
	wget https://github.com/jmecosta/sonar-cxx/releases/download/test1/sonar-cxx-plugin-0.9.7-SNAPSHOT.jar && \
	unzip sonarqube-5.6.1.zip && \
	unzip sonar-scanner-2.6.1.zip && \
	ln -s sonarqube-5.6.1 sonar && \
	mv *jar /opt/sonar/extensions/plugins/ && \
	rm -rf *zip

### need license
###		wget https://sonarsource.bintray.com/CommercialDistribution/sonar-cpp-plugin/sonar-cpp-plugin-4.0.jar && \
### error need fix:
###	    wget https://github.com/SonarOpenCommunity/sonar-cxx/releases/download/cxx-0.9.6/sonar-cxx-plugin-0.9.6.jar && \

###### GIT & SVN

ADD 10-subversion.conf /etc/httpd/conf.modules.d/
ADD authorized_keys /home/git/.ssh/authorized_keys
ADD ssh_host_rsa_key.pub  /etc/ssh/ssh_host_rsa_key.pub
ADD ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key

ADD start.sh /opt/scripts/

ADD settings.xml /var/lib/jenkins/
COPY slave/config /var/lib/jenkins/.ssh/config
COPY slave/id_rsa /var/lib/jenkins/.ssh/id_rsa
COPY slave/id_rsa.pub /var/lib/jenkins/.ssh/id_rsa.pub


RUN chmod +x /opt/scripts/start.sh && \
    chmod 700 /etc/ssh/ssh_host* && \
	mv /etc/localtime /root/old.timezoned && \
	ln -s /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime && \
	ln -s /tmp /var/www/html/image && \

	chsh -s /bin/bash jenkins && \
    echo 'jenkins:Admin2016' |chpasswd && \
	
	chmod 600 /var/lib/jenkins/.ssh/config && \
	chmod 600 /var/lib/jenkins/.ssh/id_rsa && \
	chown -R jenkins.jenkins /var/lib/jenkins/.ssh && \
	chown -R jenkins.jenkins /var/lib/jenkins && \

	echo 'git:Git@2016' |chpasswd && \
	mkdir -p /home/git/.ssh && chmod 700 /home/git/.ssh && \
	chmod 600 /home/git/.ssh/authorized_keys && \
		
	mkdir -p /git/project.git && \
	cd /git/project.git && \
	git init --bare && \
	chown -R git.git /home/git/.ssh && \
	chown -R git.git /git/project.git && \

	sed -i "s/^PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config && \
	sed -i "s/^#RSAAuthentication.*/RSAAuthentication yes/g" /etc/ssh/sshd_config && \
	sed -i "s/^#PubkeyAuthentication.*/PubkeyAuthentication yes/g" /etc/ssh/sshd_config && \
	sed -i "s/^UsePAM yes/#UsePAM yes/g" /etc/ssh/sshd_config && \
	sed -i "s/^HostKey \/etc\/ssh\/ssh_host_dsa_key/#HostKey \/etc\/ssh\/ssh_host_dsa_key/g" /etc/ssh/sshd_config && \
	sed -i "s/^HostKey \/etc\/ssh\/ssh_host_ecdsa_key/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g" /etc/ssh/sshd_config && \
	sed -i "s/^HostKey \/etc\/ssh\/ssh_host_ed25519_key/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/g" /etc/ssh/sshd_config && \
	sed -i "s/^#AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/g" /etc/ssh/sshd_config


# Expose our jenkins data and log directories log.
VOLUME ["/var/log","/var/lib/jenkins","/svn","/git","/backup/key"]
EXPOSE 8090 8019 80 22

##CMD ["/etc/init.d/jenkins","start"]
##CMD /opt/scripts/start.sh
ENTRYPOINT ["/opt/scripts/start.sh"]
