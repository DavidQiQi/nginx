#!/bin/bash
TIME=`date +%Y%m%d -d "1 days ago"`
LOGDIR=/home/davis/nginx/log
FILENAME=access.log
DATADIR=/home/davis/opdir/log/analysis_gs/$TIME
Yesterday=`date -d "1 day ago" +%F`
export LC_ALL='zh_CN.UTF-8'
function def_var()
{
    MODULE=''
    MODULE_TIP=''
}
if [ -d $DATADIR ];then
    :
else
    mkdir -p $DATADIR&& cd $DATADIR&& rm -f *
fi
def_var
MODULE=$1
MODULE_TIP=$2
function getdata
{
    for i in $(ifind -t $MODULE)
        do
            {
                scp $i:$DATADIR/$MODULE_TIP.analysis_gs.$TIME  $DATADIR/$MODULE.$i.analysis_gs
                scp $i:$DATADIR/$MODULE_TIP.httpcode_gs.$TIME  $DATADIR/$MODULE.$i.httpcode_gs
            }
        done
}
getdata
cd $DATADIR
cat $MODULE.*.analysis_gs> $MODULE.$TIME.analysis_gs.tmp
cat $MODULE.*.httpcode_gs> $MODULE.$TIME.httpcode_gs.tmp
function count_httpcode_gs()
{
    more $1|awk '{a_array[$1]+=$2}END{for(i in a_array)print i "   " a_array[i]}' |sort -n -r -k 2|grep ^[0-9][0-9][0-9]\ |head -10
}
function count_log()
{
more $1|awk '{a_array[$1]+=$2;b_array[$1]++;c_array[$1]+=$3}END{for(i in a_array) print i"  " a_array[i]/b_array[i]*1000 "  " c_array[i]}' |sort -n -r -k 3|grep -v % |grep -v analysis_gs|grep -v ::::::::::::::| head -20
}
function count_log_gs()
{
    more $1|awk '{a_array[$1]+=$2;b_array[$1]++;c_array[$1]+=$3}END{for(i in a_array) print i"  " a_array[i]/b_array[i]*1000 "  " c_array[i]}' |sort -n -r -k 3|grep -v % 
}
function count_5XX()
{
    total=`cat  /tmp/count|grep -E "^5|^2|^3"|awk '{sum+=$2}END{print sum}'`
    num_5XX=`cat  /tmp/count|grep -E "^5"|awk '{sum+=$2}END{print sum}'`
    if [ AAA$num_5XX = "AAA" ];then
        num_5XX=0
    fi
    pv=`cat  /tmp/count|awk '{sum+=$2}END{print sum}'`
    percent=`echo |awk '{printf "%.6f\n",'$num_5XX'*100/'$total'}'`
    echo "total $pv"
    echo "percent_of_5XX $percent%"
}
function write_html_code ()
{
    while read line
    do
        code=`echo $line|awk '{print $1}'`
        nums=`echo $line|awk '{print $2}'`
        echo "<tr><td>$code</td><td>$nums</td></tr>"
    done<$1
}
function write_html_proctime ()
{
    while read line
    do
          interface=`echo $line|awk '{print $1}'`
          proctime=`echo $line|awk '{print $2}'`
          nums=`echo $line|awk '{print $3}'`
           echo "<tr><td>$interface</td><td>$proctime</td><td>$nums</td></tr>"
    done<$1
}
cat /dev/null > mail.$TIME
cat /dev/null > put.$TIME
count_httpcode_gs  $MODULE.$TIME.httpcode_gs.tmp >mail.$MODULE.httpcode
count_log $MODULE.$TIME.analysis_gs.tmp >mail.$MODULE.proctime
count_log_gs $MODULE.$TIME.analysis_gs.tmp >>put.$TIME
sleep 5
echo '<table style="width:50%;background-color:#00D5FF;" cellpadding="2" cellspacing="0" border="1" bordercolor="#000000"><tbody>'>mail.tmp
echo "<tr><td>$MODULE的nginx状态码</td><td>流量</td></tr>" >> mail.tmp
write_html_code mail.$MODULE.httpcode >> mail.tmp
echo '</tbody></table><br /><br />' >> mail.tmp
echo '<table style="width:50%;background-color:#00D5FF;" cellpadding="2" cellspacing="0" border="1" bordercolor="#000000"><tbody>' >>mail.tmp
echo "<tr><td>$MODULE模块接口</td><td>响应时间（ms)</td><td>流量</td></tr>" >> mail.tmp
write_html_proctime mail.$MODULE.proctime >> mail.tmp
echo '</tbody></table><br /><br />' >>mail.tmp
cp put.$TIME /home/davis/opbin/analysis_gs/put.tmp
cp mail.tmp /home/davis/opbin/analysis_gs/mail.tmp
alltotal=`cat mail.tmp|grep "<tr><td>[0-9][0-9][0-9]"|awk -F'<|>' '{sum+=$9}END{print sum}'` 
echo "$TIME  $alltotal" > /tmp/gs.total
cat mail.tmp |awk -F'<|>' '{if(NF>16)print $5" "$13}' > $TIME.txt
echo >/tmp/import.total
for j in `cat  ~/opbin/analysis_gs/gs.conf|grep -v ^#`
    do
        inter=`echo $j|sed 's/gs-.*-//g'|sed 's/.count//g'`
        num=`grep  -w ^$inter $TIME".txt" |head -1|awk '{print $2}'`
        if [ -z $num ];then
            num=0
        fi
        echo $t" "$j" "$num >> /tmp/import.total
    done
cd  /home/davis/opbin/analysis_gs/ && python mail.py $MODULE
