FROM centos:centos7
MAINTAINER "Reboot Shen<reboot.shen@gmail.com>"

ENV JAVA_VERSION 8u92
ENV BUILD_VERSION b14

WORKDIR /opt/

#helpful utils, but only sudo is required
#RUN yum -y install nc
RUN yum -y update && \
	yum -y install wget tar sudo vim initscripts subversion mod_dav_svn git postfix unzip && \
	adduser git

###### JENKINS2.8

RUN wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo && \
	rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key && \
	yum -y install jenkins
ADD settings.xml /var/lib/jenkins/
RUN sed -ri "s/8080/8090/g" /etc/sysconfig/jenkins && \
	sed -ri "s/8009/8019/g" /etc/sysconfig/jenkins && \
	chown -R jenkins.jenkins /var/lib/jenkins/settings.xml

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

###### SONAR
RUN wget https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-4.5.7.zip && \
	wget https://sonarsource.bintray.com/Distribution/sonar-scanner-cli/sonar-scanner-2.6.1.zip && \
	wget https://sonarsource.bintray.com/Distribution/sonar-java-plugin/sonar-java-plugin-3.13.1.jar && \
	wget https://sonarsource.bintray.com/Distribution/sonar-javascript-plugin/sonar-javascript-plugin-2.12.jar && \
	wget http://central.maven.org/maven2/org/codehaus/sonar/plugins/sonar-findbugs-plugin/3.3.2/sonar-findbugs-plugin-3.3.2.jar && \
	unzip sonarqube-4.5.7.zip && \
	unzip sonar-scanner-2.6.1.zip && \
	ln -s sonarqube-4.5.7 sonar && \
	mv *jar /opt/sonar/extensions/plugins/ && \
	rm -rf *zip



ADD 10-subversion.conf /etc/httpd/conf.modules.d/

# Expose our jenkins data and log directories log.
VOLUME ["/jenkins-data", "/var/log","/var/lib/jenkins","/svn"]
EXPOSE 8090 8019 80
###CMD ["/etc/init.d/jenkins","start"]
ADD start.sh /opt/scripts/
RUN chmod +x /opt/scripts/start.sh && \

	mv /etc/localtime /root/old.timezoned && \
	ln -s /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime && \
	su git && \
	cd && \
	mkdir .ssh && chmod 700 .ssh && \
	touch .ssh/authorized_keys && chmod 600 .ssh/authorized_keys && \

	cd && \
	mkdir project.git && \
	cd project.git && \
	git init --bare



##CMD /opt/scripts/start.sh
ENTRYPOINT ["/opt/scripts/start.sh"]
