#!/bin/bash
TIME=`date +%Y%m%d -d "1 days ago"`
LOGDIR=/home/davis/nginx/log
FILENAME=access.log
DATADIR=/home/davis/opdir/log/analysis_gs/$TIME
if [ -d $DATADIR ];then
    :
else
    mkdir -p $DATADIR&& cd $DATADIR&& rm -f *
fi
function pdo {
for i in $(ifind -t $1)
    do
        {
            scp client.sh $i:/home/davis/opbin/
            ssh -n $i "nohup sh /home/davis/opbin/client.sh $1 $2 >/dev/null 2>&1 & "
        }
    done
}
cat ./gs.module|grep -v ^#|while read module module_ip
do
    pdo $module $module_ip
done
