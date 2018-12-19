#!/bin/sh
set -e
CPUCOUNT=`nproc`
case $ICECREAM_SCHEDULER in
	yes) icecc-scheduler -d -n neople -l /var/log/icecc-scheduler -vvvv
             iceccd -d -s $ICECREAM_SCHEDULER_HOST -m `expr ${CPUCOUNT} / 2` -n neople -l /var/log/icecc.log && tail -f /var/log/icecc*.log
	;;
	no)  iceccd -d -s $ICECREAM_SCHEDULER_HOST -m `expr ${CPUCOUNT} - 4` -n neople -l /var/log/icecc.log && tail -f /var/log/icecc*.log
	;;
	*)   echo "Null"
	;;
esac
#iceccd -d -s $ICECREAM_SCHEDULER_HOST -m 35 -n neople -l /var/log/icecc.log && tail -f /var/log/icecc.log
