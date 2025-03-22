FROM ubuntu:22.04

USER root

RUN umask 644
RUN mkdir -p /java/install
RUN mkdir -p /root/alologs

RUN apt update
RUN apt install -y software-properties-common unzip curl wget sudo git vim apt-utils inetutils-ping sysvbanner

RUN add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main"
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt update
RUN apt install -y htop sudo postgresql-client

WORKDIR /java
RUN wget --timeout 3600 --progress=bar:force:noscroll -N -P /java/install -v https://sga-file.s3.sa-east-1.amazonaws.com/sgv/new/install/jdk-8u131-linux-x64.tar.gz && true

RUN tar xvzf ./install/jdk*.tar.gz
RUN mv /java/jdk* /java/jdk
RUN echo "export JAVA_HOME=/java/jdk" >> /etc/bash.bashrc
RUN echo "export PATH=$PATH:$JAVA_HOME/bin" >> /etc/bash.bashrc
RUN wget --timeout 3600 --progress=bar:force:noscroll -N -P /java/install -v https://sga-file.s3.sa-east-1.amazonaws.com/sgv/new/install/apache-tomcat-8.5.15.zip

RUN unzip -o ./install/apache-tomcat-*.zip
RUN mv apache-tomcat-* tomcat

RUN rm -f /java/tomcat/lib/postgres*.jar
RUN rm -f /java/tomcat/lib/javax.faces*.jar
RUN wget --timeout 3600 --progress=bar:force:noscroll -N -P /java/tomcat/lib https://repo1.maven.org/maven2/org/postgresql/postgresql/42.2.2/postgresql-42.2.2.jar
RUN wget --timeout 3600 --progress=bar:force:noscroll -N -P /java/tomcat/lib https://repo1.maven.org/maven2/org/glassfish/javax.faces/2.2.14/javax.faces-2.2.14.jar

RUN chmod 775 -Rf tomcat
RUN ln -s tomcat/webapps tomcat/deploy
EXPOSE 8080

ADD ./scripts/* ./scripts/
ADD ./cfg/* ./tomcat/conf/

RUN mkdir bkps
ADD ./scripts/sgv/* ./scripts/sgv/
RUN chmod 777 -Rf bkps
RUN chmod 775 -Rf scripts

ENV JAVA_HOME "/java/jdk"

ENV JAVA_OPTS "-server -Xmx10g -Xms512m -XX:+UseConcMarkSweepGC -XX:+CMSParallelRemarkEnabled -XX:+UseCompressedOops -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 -XX:+ScavengeBeforeFullGC -XX:+CMSScavengeBeforeRemark -Dalo.env=P -DmongoHost=mongodb:27017 -Dalo.hibernate.hbm2ddl.auto=none -Dlog.path=/java/logs -Duser.timezone=Brazil/East" 

CMD ["/java/tomcat/bin/catalina.sh", "run"] 


