#!/bin/bash
/bin/ps auxw |grep "cp -pr /var/cache/mylvmbackup/mnt/backup"|grep -v grep |awk '{print $2}' | xargs kill -9
/bin/ps auxw |grep tar | grep backup |grep -v grep |awk '{print $2}' | xargs kill -9
/bin/ps auxw |grep fk-mylvmbackup |grep -v grep |awk '{print $2}' | xargs kill -9
/bin/ps auxw |grep lftp|grep -v grep |awk '{print $2}' | xargs kill -9
set -- $(/bin/df -h /var/lib/mysql/ | awk '{print $1}' |grep dev | awk -F/ '{print $NF}' | awk -F- '{print $1,$2}')
vg=$1
lv=$2
/bin/umount /dev/$vg/"$lv"_snapshot
/sbin/lvremove -f /dev/$vg/"$lv"_snapshot
