#!/bin/sh

SUFFIX=$(date +"%Y%m%d_%H")
export MAIL=./data/mail_content.$SUFFIX

set -u
function usage()
{
    local SCRIPT_NAME=$(basename $0)
cat <<EOF

        Usage:
        $SCRIPT_NAME hosts.cfg filelist

EOF
}

function print_log()
{
    local NOWTIME=$(date +'%F %T')
    local DESC="[$NOWTIME]"
    if [ "$1" == 'ERROR' ] || [ "$1" == 'error' ]
    then
        DESC="${DESC}[ERROR]"
        echo -ne "$DESC$2"
:<<CUT
    elif [ "$1" == 'DEBUG' ] || [ "$1" == 'debug' ]
    then
        desc="${DESC}[DEBUG]"
        echo -ne "$DESC$2" 
CUT
    elif [ "$1" == 'INFO' ] || [ "$1" == 'info' ]
    then
        DESC="${DESC}[INFO]"
        echo -ne "$DESC$2" 
    fi
}

function def_var()
{
    SMSHEAD=""
    GSIZE='1073741824'
    MODULE='' 
    IP=''
    ONLINE_DIR=''
    HOSTCFG=''
    LC_FILE=''
    RM_FILE=''
    RM_DIR=''
}

function AWK()
{
    awk '{
             count[$2]
             list[$1]=$2
         }
         END{
             if(length(count)==1)
             {
                 print $2
             }
             else
             {
                 for(i in list)
                 {
                     print i,list[i]
                 }
             }
         }'
}

function poll_ip()
{
    local CMD=$*
    local POLL_IP_LIST=$(cat $HOSTCFG | grep -v '#')
    for IP in $POLL_IP_LIST
    do
        local FILEINFO=$(eval $CMD 2> /dev/null | awk '{print "'$IP'",$1,$2}')
        if [ -z "$FILEINFO" ]
        then
            echo "$IP err err err err err err err err err"
        else
            echo "$FILEINFO"
        fi
    done
}

function miss_md5_check()
{   #>./result 
    HOST_COUNT=`cat $HOSTCFG|wc -l`
    SIZE_OK_LIST=tmp_size_ok_list
#    RM_FILE=$(cat $FILE_LIST | xargs)
#    RM_FILE=$(cat $FILE_LIST )
#    local CMD_SSH_INFO="ssh \$IP \"ls -l $RM_FILE\""
    local CMD_SSH_INFO="ssh \$IP find \"\$ONLINE_DIR -name '*.php'\" \|xargs md5sum "
    local ALL_FILE_INFO=$(poll_ip $CMD_SSH_INFO)

    echo "$ALL_FILE_INFO" > zzz.all_file_info
    if [ -s zzz.all_file_info ];then
        cat zzz.all_file_info|awk '{print $3}'|sort|uniq -c |while read exist_num exist_file
        do
        if [ $exist_num -lt $HOST_COUNT ];then
            let num=$HOST_COUNT-$exist_num
            echo "$MODULE  $num of $HOST_COUNT file missing: $exist_file" >>result
        fi
        done
    else 
        echo "$ONLINE_DIR not exist wanted file "
        exit 1
    fi
    if [ ! -s result ];then
        echo "$MODULE file count is correct"
    fi
###md5 check##############################################
    cat zzz.all_file_info|awk '{print $3}'|sort |uniq -c >./md5_tmp_file
    cat md5_tmp_file|while read num file
    do
        if [ $num -lt $HOST_COUNT ];then
            grep -w "$file$" ./zzz.all_file_info>./wrong_num_md5_file
            tmp_num_wrong=`cat ./wrong_num_md5_file|awk '{print $2}'|sort|uniq -c|wc -l`
            if [ $tmp_num_wrong -ne 1 ];then
                cat ./wrong_num_md5_file|awk '{print $2}'|sort|uniq -c|awk '{print $1,$2}'>error_md5
                #grep $file ./wrong_num_md5_file
                cat error_md5|while read err_md5_num err_md5
                do
                    report=`grep $err_md5 zzz.all_file_info|awk '{print $1,$3}'|head -n 1`
                    echo "$MODULE  $err_md5_num of $num  md5  wrong. such as:$report" >>./result
                done
            fi
        elif [ $num -eq $HOST_COUNT ];then
            grep -w "$file$" ./zzz.all_file_info>./true_num_md5_file
            tmp_num_true=`cat ./true_num_md5_file|awk '{print $2}'|sort|uniq -c|wc -l`
            if [ $tmp_num_true -gt 1 ];then
                #cat ./true_num_md5_file
                cat ./true_num_md5_file|awk '{print $2}'|sort|uniq -c|awk '{print $1,$2}'>true_md5
                cat true_md5|while read true_md5_num true_md5
                do
                    report=`grep -w $file zzz.all_file_info|awk '{print $1,$3}'|head -n 1`
                    echo "$MODULE  $true_md5_num of $num  md5  wrong. such as:$report" >>./result
                done
            fi
        fi
    done
}
[ $# -ne 3 ] && usage && exit -1
def_var
HOSTCFG=$1
MODULE=$2
ONLINE_DIR=$3
#check_parms
miss_md5_check
