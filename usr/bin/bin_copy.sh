#!/bin/bash


RSYNC_SERVER="mysql-log.nm.domain.com";

/bin/rm -rf /tmp/`hostname` 2> /dev/null
/bin/mkdir -p /tmp/`hostname`/app/var/log/mysql;
/usr/bin/rsync -rvz --no-p --chmod=ugo=rwx /tmp/`hostname` $RSYNC_SERVER::fk-mybin/
size=`du -sh /var/log/mysql | awk '{print $1}'`
logfile=/var/log/fk-ops-bkp-client/`hostname`_`date +%s`.yaml
/usr/bin/rsync -havz  --chmod=Fo+r,Do+x  /var/log/mysql/* $RSYNC_SERVER::fk-mybin/`hostname`/app/var/log/mysql/
if [ $? == 0 ]
then
	echo "/var/log/mysql:">>$logfile 
	echo "  action: Bkp" >>$logfile
	echo "  size: $size" >>$logfile
	echo "  status: OK" >>$logfile
else
	echo "/var/log/mysql:">>$logfile 
        echo "  action: Bkp" >>$logfile
        echo "  size: $size" >>$logfile
        echo "  status: FAIL" >>$logfile
fi

