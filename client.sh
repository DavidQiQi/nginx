#!/bin/bash
print_log()
{
nowtime=`date +"%F %T"`
if [ $# -eq 0 ];then
    echo -e "\nUsage: print_log content\n"
    exit 1
fi
echo -e "[$nowtime]$*"
}
if [ $# -lt 2 ];then
    print_log "[ERR]Para at least have two"
    exit 1
fi
MODULE=$1
MODULE_TIP=$2
TIME=`date +%Y%m%d -d "1 days ago"`
LOGDIR=/home/davis/nginx/log
FILENAME=access.log
DATADIR=/home/davis/opdir/log/analysis_gs/$TIME
if [ -d $DATADIR ];then
    :
else
    mkdir -p $DATADIR&& cd $DATADIR&& rm -f *
fi
cd $LOGDIR
for log in `ls $FILENAME.$TIME*`
do
    more $log |grep "$MODULE_TIP"|\
    awk '{ gsub("?.*","",$7); gsub(".*/","",$7);time[$7]+=$11;count[$7]++; }END{for(i in time)print i,time[i]/count[i],count[i]}' >>$DATADIR/$MODULE_TIP.analysis_gs.$TIME 
    more $log|grep "$MODULE_TIP"| awk '{a_array[$9]++}END{for(i in a_array)print i "   " a_array[i]}'  >> $DATADIR/$MODULE_TIP.httpcode_gs.$TIME
done
