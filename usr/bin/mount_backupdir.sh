#!/bin/bash
/usr/bin/lsof /var/cache/mylvmbackup/backup  2> /dev/null |grep -v grep |grep -v PID |awk '{print $2}' |xargs kill -9
/bin/umount -f /var/cache/mylvmbackup/backup
/sbin/lvremove -f /dev/mapper/vgroot-mysql_backup
/bin/df -h | grep mysql_snapshot 
if  [ "$?" == 0 ];
then
/sbin/lvdisplay /dev/mapper/vgroot-mysql_backup
if [ "$?" == 0 ];
then
umount /dev/mapper/vgroot-mysql_backup 
/sbin/lvremove -f /dev/mapper/vgroot-mysql_backup
fi
size=$(df -h |grep /var/cache/mylvmbackup/mnt/ | awk '{print $2}' | sed 's/G//')
if [[ "$size" == *M* ]];
then
size=1
size1=1
else
size=$(echo $size | awk '{printf("%d\n",$0+=$0<0?0:0.999)}' )
size1=$((size+5))
fi
size2=$((size1/2))
echo "backup partition size: $size2"
/sbin/lvcreate -L $size2"G" -nmysql_backup vgroot
if  [ "$?" != 0 ];
then
	echo "Failed to create lvm.Might be,not enough space of device."
        exit 2
fi
mkfs.xfs /dev/mapper/vgroot-mysql_backup 
mkdir -p /var/cache/mylvmbackup/backup/
mount /dev/mapper/vgroot-mysql_backup /var/cache/mylvmbackup/backup/
rm -rf /var/cache/mylvmbackup/backup/ftp
#mkdir /var/cache/mylvmbackup/backup/ftp
	if  [ "$?" == 0 ];
	then
		echo "mount pass"
		exit 0
	else
		echo "mount  fail"
		exit 2
	fi
else
echo "no snap"
exit 2;
fi
exit 0;
