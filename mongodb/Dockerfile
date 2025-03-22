FROM mongo:6.0.21

USER root

RUN umask 644

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
RUN apt-get update && apt-get install -y --allow-unauthenticated --no-install-recommends software-properties-common unzip sudo inetutils-ping vim wget curl apt-utils
RUN echo "deb http://repo.mongodb.org/apt/ubuntu $(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d= -f2)/mongodb-org/3.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.2.list
RUN apt-get update && apt-get install -y --allow-unauthenticated --allow-change-held-packages mongodb-org=3.2.13 mongodb-org-server=3.2.13 mongodb-org-shell=3.2.13 mongodb-org-> mongos=3.2.13 mongodb-org-tools=3.2.13
RUN mkdir -p /data/db
EXPOSE 27017
ENTRYPOINT ["/usr/bin/mongod"]
CMD ["--dbpath=/var/lib/mongodbdata"]
