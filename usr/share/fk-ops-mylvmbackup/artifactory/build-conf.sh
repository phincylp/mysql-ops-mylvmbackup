#!/bin/bash

#set -x 
#grep -v lftparg /usr/share/fk-ops-mylvmbackup/artifactory/fk-mysql-migrate.conf > /etc/fk-mysql-migrate.conf
#if [ $? == 0 ]
#then
#        TARGET=$1
#        if [ -z $TARGET ]
#        then
#                exit 1
#        else
#                echo "lftparg=set xfer:log off && set ftp:passive-mode on && set ftp:ssl-allow off && set pget:default-n 10 && set mirror:parallel-transfer-count 8 && set mirror:parallel-directories true && set net:connection-limit 8   && open -u ftpsol,ftp123 ftp://$TARGET" >> /etc/fk-mysql-migrate.conf
#                perl -p -i -e "s/\r\n/\n/g" /etc/fk-mysql-migrate.conf
#        fi
#else
#        exit 1
#fi


set -x

cp -p /usr/share/fk-ops-mylvmbackup/artifactory/fk-mysql-migrate.conf /etc/fk-mysql-migrate.conf

if [ $? -eq 0 ]
then
     TMP_TAR=$1
	TARGET=${TMP_TAR//[[:space:]]}

    DATABASES_TO_EXCLUDE=$2

    if [ -z $TARGET ]
    then
            exit 1
    else
    perl -p -i -e "s/mysql-bkp.nm.domain.com/$TARGET/g" /etc/fk-mysql-migrate.conf
	fi

	ipaddr=`mktemp /tmp/IP.XXX`
        ifconfig | grep inet | grep 10. | awk '{print $2}' | cut -d: -f2 > $ipaddr
        grep ^10.3 $ipaddr > /dev/null
        if [ $? -eq 0 ]
        then
                perl -p -i -e "s/vgroot/vgmysql/g" /etc/fk-mysql-migrate.conf
        fi
	grep ^10.4 $ipaddr > /dev/null
        if [ $? -eq 0 ]
        then
                perl -p -i -e "s/vgroot/vgmysql/g" /etc/fk-mysql-migrate.conf
        fi
	grep ^10.5 $ipaddr > /dev/null
        if [ $? -eq 0 ]
        then
                perl -p -i -e "s/vgroot/vgmysql/g" /etc/fk-mysql-migrate.conf
        fi


#rsynchost
echo "rsynchost=$TARGET:/var/lib/mysql/backup/" >> /etc/fk-mysql-migrate.conf
#  
#

    MIRROR_ARG=""
    arr=$(echo $DATABASES_TO_EXCLUDE | tr ":" "\n")
    for x in $arr
    do
        MIRROR_ARG=$MIRROR_ARG" -x '$x\/'"
    done
    perl -p -i -e "s/mirrorarg=.*/mirrorarg=$MIRROR_ARG/g" /etc/fk-mysql-migrate.conf
    
# generate rsync options
   RSYNC_ARGS=""
   for x in $arr
   do
      RSYNC_ARGS=$RSYNC_ARGS" --exclude=$x"
   done

   echo  "rsyncargs=$RSYNC_ARGS" >> /etc/fk-mysql-migrate.conf
## end rsync


else
	exit 1
fi
