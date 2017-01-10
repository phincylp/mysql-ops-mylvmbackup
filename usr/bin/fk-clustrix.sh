#!/bin/bash
db=(  "cms" )
today=$(/bin/date "+%Y-%m-%d")
date_field=(${today//-/ }) 
base="cms-clustrix104""/"${date_field[0]}"/"${date_field[1]}"/"$today"/app/mysql/"
file=$(/bin/date "+%Y%m%d").sql
mkdir -p /tmp/$base
rsync -rvz --no-p --chmod=ugo=rwx /tmp/cms-clustrix104 ops-storage::fk-storage/
rm -rf /tmp/$base
for i in ${db[@]}
do
echo `date` "Start dump " >> /var/log/domain/dump.log
/bin/mysqldump --databases $i --single-transaction  --flush-logs --master-data=2 > /clustrix/dbdump/"$i"_$file 2>>  /var/log/domain/dump.log
if [ "$?" == 0 ];
then
/bin/rsync -hav /clustrix/dbdump/"$i"_$file ops-storage::fk-storage/$base/
else
echo `date` "Dump failed " >> /var/log/domain/dump.log
fi
rm /clustrix/dbdump/"$i"_$file
done
