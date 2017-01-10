#!/bin/bash

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
	elif [[ "$size" == *T* ]]; then
		size=$(df -h |grep /var/cache/mylvmbackup/mnt/ | awk '{print $2}' | sed 's/T//')
		multiply=1024
		size=$(echo "scale=4; $size*$multiply" | bc) #multiply by 1024
		size=$(echo $size | awk '{printf("%d\n",$0+=$0<0?0:0.999)}' ) #roundoff to next int
	size1=$((size+10)) #add 10G additional space
	else
		size=$(echo $size | awk '{printf("%d\n",$0+=$0<0?0:0.999)}' )
		size1=$((size+5))
	fi
	echo "creating logical volume .. lv partition of $size1 G being created"
	/sbin/lvcreate -L $size1"G" -nmysql_backup vgroot
	mkfs.xfs /dev/mapper/vgroot-mysql_backup 
	avail=$(df -hP /dev/mapper/vgroot-mysql_backup | tail -1 | awk '{print $4}' | sed 's/G//')
	echo "Post filesystem create - available space of partition is $avail"
	mkdir -p /var/cache/mylvmbackup/backup/
	mount /dev/mapper/vgroot-mysql_backup /var/cache/mylvmbackup/backup/
	avail=$(df -hP /dev/mapper/vgroot-mysql_backup | tail -1 | awk '{print $4}' | sed 's/G//')
	echo "Post mounting  - available space of partition is $avail"
	rm -rf /var/cache/mylvmbackup/backup/ftp
	mkdir /var/cache/mylvmbackup/backup/ftp
	avail=$(df -hP /dev/mapper/vgroot-mysql_backup | tail -1 | awk '{print $4}' | sed 's/G//')
	echo "var avail has the value - $avail"
	if [[ "$avail" == *M* ]];
	then
		echo "inside *M* section"
		avail=2
	elif [[ "$avail" == *T* ]]; then
		echo "inside *T* section"
		multiply=1024
		avail=$( echo $avail | sed 's/T//')
		avail=$(echo "scale=4; $avail*$multiply" | bc) #multiply by 1024
		avail=$(echo $avail | awk '{printf("%d\n",$0+=$0<0?0:0.999)}' ) #roundoff to next int
	fi
	ceil_val=${avail/.*}
	echo "var ceil_val has value - $ceil_val "
	ceil_val=$((ceil_val+1))
	echo "var ceil_val has value - $ceil_val "

	echo $size $size1 $ceil_val
	if [ "$ceil_val" -gt "$size" ];
	then
		echo "cp here"
#		/usr/bin/ionice -c 3 cp -pr /var/cache/mylvmbackup/mnt/* /var/cache/mylvmbackup/backup/ftp/
		echo "explicitly disabling local copy and proceeding with the remote copy" # comment this line and uncomment the above line to reactivate local copy
		if  [ "$?" == 0 ];
		then
			echo "cp pass"
			exit 0
		else
#			echo "cp fail"
#			exit 2
# Uncomment the above two lines and comment the below two lines if you actually want to check the local copy status
			echo "cp was not done as explicitly skipped"
			exit 0
		fi
	else
		echo "no cp"
		echo "explicitly sending a retun code of 0 as local copy is being eplictly disabled"
		exit 0
# comment the above two lines and enable the below line to enable tar backup
#		exit 2
	
	fi
else
	echo "cp pass"
	exit 0;
fi
