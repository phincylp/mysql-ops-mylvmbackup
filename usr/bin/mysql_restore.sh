#!/bin/bash

function usage()
{
     echo "
    Usage: $0 -s <src_dir> -d <dst_dir>

       Eg: $0 -s /flo-acct-db-2/2013/09/2013-09-04   -d /var/lib/mysql

     "  >&2
exit 1;
}

while getopts "s:d:h" flag
do
#  echo $flag $OPTIND $OPTARG
   case $flag in
   s) src=$OPTARG
   ;;
   d) dst=$OPTARG
   ;;
   h) usage
   ;;
   *) usage
   ;;
   esac
done

if [ -z $src ] || [ -z $dst ];then
usage
fi

echo "Restoring $src -> $dst. Pls wait......"
echo 

 /usr/bin/lftp -e "set mirror:include-regex && set xfer:log off && set ftp:passive-mode on && set ftp:ssl-allow off && set pget:default-n 30 && set mirror:parallel-transfer-count 30 && set mirror:parallel-directories true && set net:connection-limit 30   && open -u ftpsol,ftp123 ftp://mysql-bkp.nm.domain.com  && mirror   $src $dst/   && bye"
if [ $? -eq 0 ];
then
echo "Restore success"
/bin/chown -R mysql:mysql $dst/
if [ -f /var/lib/mysql/auto.cnf ]; then
    mv /var/lib/mysql/auto.cnf /root/
fi
else
echo "Restore fail...."
fi
echo
echo
