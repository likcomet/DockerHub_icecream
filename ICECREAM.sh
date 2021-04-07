#!/bin/bash
# color variables
txtblk='\e[1;30m' # Black - Regular
txtred='\e[1;31m' # Red
txtgrn='\e[1;32m' # Green
txtylw='\e[1;33m' # Yellow
txtblu='\e[1;34m' # Blue
txtpur='\e[1;35m' # Purple
txtcyn='\e[1;36m' # Cyan
txtrst='\e[0m'    # Text Reset

DOCKER_VERSION="likcomet/icecream-compiler:release-1.4_build_v3"

LIST="10.30.20.222
10.30.20.171
10.30.20.172
10.30.20.173
10.30.20.174
10.30.20.175
10.30.20.176
10.30.20.177
10.30.20.178
10.30.20.179
10.30.20.180
10.30.20.182
10.30.20.183
10.30.20.184
10.30.20.185
10.30.20.186
10.30.20.187
10.30.20.188
10.30.20.189
10.30.20.190
10.30.20.191
10.30.20.192
10.30.20.193
10.30.20.194
10.30.20.195
10.30.20.196"

usage () {
clear
        cat <<EOF

##################################################################################
#                                                                                #
#   Neople Icecream Compile Farm Operation Tool                                  #
#                                                                                #
#   Usage   : ./ICECREAM.sh [test|live] [run|start|stop|ps|rm|ss]                #
#                                                                                #
#   example : ./ICECREAM.sh test run      // Download and Run                    #
#             ./ICECREAM.sh test stop     // Stop                                #
#             ./ICECREAM.sh test start    // Start                               #
#             ./ICECREAM.sh test rm       // Destroy Icecream container          #
#             ./ICECREAM.sh test ps       // Process Check                       #
#             ./ICECREAM.sh test ss       // Service Status Check (ESTABLISHED)  #
#             ./ICECREAM.sh sundae        // Icecream Monitor (Sundae)           #
#             ./ICECREAM.sh cli "Command" // send Command To all servers         #
#                                                                                #
##################################################################################
EOF
exit 1
}



# check argument 
if [ $1 == "sundae" ];then
        docker exec -it `docker ps -qa -f name=live-scheduler` icecream-sundae -s icecream-live.neople.co.kr -n live
        elif [ $1 == "cli" ];then
                for j in $LIST
                        do 
                        echo -e "${txtylw}${j}${txtrst}\n`ssh $j ${2}`\n\n\n"
                        done
                        exit;
        elif [ $# -lt 2 ];then
                usage
fi


case $1 in
        live) scheduler=icecream-live.neople.co.kr
              scheduler_IP=`dig +short $scheduler`
              scheduler_port=8765
              iceccd_port=10245
              netname=$1
        ;;
        test) scheduler=icecream-test.neople.co.kr
              scheduler_IP=`dig +short $scheduler`
              scheduler_port=28765
              iceccd_port=20245
              netname=$1
        ;;
        *) usage
           exit 1;
        ;;
esac
clear

for i in $LIST
do
        #컴파일팜이 물리인지 가상인지 판단 / CPU는 몇개인지 판단
        PLATFORM=`ssh $i dmidecode -s system-product-name | awk '{print $1}'`
        ALLCPUS=`ssh $i lscpu  | grep "^CPU(s)" | awk  '{print $NF}'`

        #CPU 코어수 판단하여 iceccd에 할당하는 로직
        case $1 in
                live) if [ "$PLATFORM" == "VMware" ]
                                then cpus=`expr $ALLCPUS - 2`
                                else cpus=`expr $ALLCPUS - 9`
                      fi
        #               echo $cpus
        #               exit;
                ;;
                test) cpus=2
                ;;
        esac

        # 도메인 질의하여 스케쥴러인지 자동 판단
        if [ $i == $scheduler_IP ];
                then YN=yes;daemon=scheduler;cpus=8
                else YN=no;daemon=iceccd
        fi

        case $2 in
                run) ssh $i docker run --name $1-$daemon --net=host -d -e MODE=$1 -e ENABLE_SCHEDULER=$YN -e SCHEDULER_IP=$scheduler:$scheduler_port -e CPUS=$cpus -e CACHE_SIZE=10240 $DOCKER_VERSION
                     echo -e "${txtylw}ssh $i docker run --name $1-$daemon --net=host -d -e MODE=$1 -e ENABLE_SCHEDULER=$YN -e SCHEDULER_IP=$scheduler:$scheduler_port -e CPUS=$cpus -e CACHE_SIZE=10240 $DOCKER_VERSION${txtrst}"
                #run) echo "ssh $i docker run --name $1-$daemon --net=host -d -e MODE=$1 -e ENABLE_SCHEDULER=$YN -e SCHEDULER_IP=$scheduler:$scheduler_port -e CPUS=$cpus $DOCKER_VERSION"
                echo -e "$i\t`ssh $i docker ps -a | grep -i $netname`"
                ;;

                stop) ssh $i docker ps -qa --filter name=$1* > /tmp/docker-status
                ssh $i docker stop `cat /tmp/docker-status`
                echo -e "$i\t`ssh $i docker ps -a | grep -i $netname`"
                ;;

                start) ssh $i docker ps -qa --filter name=$1* > /tmp/docker-status
                ssh $i docker start `cat /tmp/docker-status`
                echo -e "$i\t`ssh $i docker ps -a | grep -i $netname`"
                ;;

                rm) ssh $i docker ps -qa --filter name=$1* > /tmp/docker-status
                ssh $i docker rm -f `cat /tmp/docker-status`
                echo -e "$i\t`ssh $i docker ps -a | grep -i $netname`"
                ;;

                ps) echo -e "$i\t`ssh $i docker ps -a | grep -i $netname`"
                ;;


                ss) echo $i;ssh $i netstat -ant | sort | grep ESTABLISHED | egrep --color=auto "$iceccd_port";echo -e "\n" 
                ;;


                *) usage
                ;;
esac
#sleep 0.2
done
