#!/bin/bash
# Variables CLIENT_NAME and INSTANCE_PORT should be coming from Docker ENV

#USERID=9009
#GROUPID=9009

#Finish install
if [[ ! -d /home/entermedia ]]; then
	groupadd -g $GROUPID entermedia
	useradd -ms /bin/bash entermedia -g entermedia -u $USERID
	mkdir /home/entermedia/.ffmpeg
	wget -O /home/entermedia/.ffmpeg/libx264-normal.ffpreset https://raw.githubusercontent.com/entermedia-community/entermediadb-installers/master/linux/usr/share/entermediadb/conf/ffmpeg/libx264-normal.ffpreset?reload=true
	chown -R entermedia. /home/entermedia/.ffmpeg
	/usr/bin/wget -O /etc/ImageMagick-6/delegates.xml https://raw.githubusercontent.com/entermedia-community/entermediadb-installers/master/linux/usr/share/entermediadb/conf/im/delegates.xml?reload=true
	ln -s /opt/libreoffice5.0/program/soffice /usr/bin/soffice
fi
#Copy the starting data
if [[ ! -d /opt/entermediadb/webapp/assets/emshare ]]; then
	mkdir -p /opt/entermediadb/
	# This includes the internal data directory 
	rsync -ar /usr/share/entermediadb/webapp/assets /opt/entermediadb/
	#rsync -ar /usr/share/entermediadb/webapp/media /opt/entermediadb/
	cp -rp /usr/share/entermediadb/webapp/*.* /opt/entermediadb/
fi
##TODO: Always replace the base and lib folders on new container
rsync -ar --exclude data* --exclude elastic*  /usr/share/entermediadb/webapp/WEB-INF /opt/entermediadb/webapp/



if [[ ! -d /opt/entermediadb/tomcat/conf ]]; then
	# make links and copy stuff
	mkdir -p "/opt/entermediadb/tomcat"/{logs,temp}
        cp -rp "/usr/share/entermediadb/tomcat/conf" "/opt/entermediadb/tomcat"
        cp -rp "/usr/share/entermediadb/tomcat/bin" "/opt/entermediadb/tomcat"
	echo "export CATALINA_BASE=\"/opt/entermediadb/tomcat\"" >> "/opt/entermediadb/tomcat/bin/setenv.sh"
	sed "s/%PORT%/${INSTANCE_PORT}/g;s/%NODE_ID%/${CLIENT_NAME}${INSTANCE_PORT}/g" <"/usr/share/entermediadb/tomcat/conf/server.xml.cluster" >"/opt/entermediadb/tomcat/conf/server.xml"
	sed "s/%CLUSTER_NAME%/${CLIENT_NAME}-cluster/g" <"/usr/share/entermediadb/conf/node.xml.cluster" >"/opt/entermediadb/webapp/WEB-INF/node.xml"
        chmod 755 "/opt/entermediadb/tomcat/bin/tomcat"
	chown -R entermedia. /opt/entermediadb/
fi

#Run command
echo Starting EnterMedia ...
sudo -u entermedia sh -c "/opt/entermediadb/tomcat/bin/catalina.sh run"