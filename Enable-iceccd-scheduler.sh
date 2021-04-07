#!/bin/sh
set -e
CPUCOUNT=`nproc`
touch /var/log/iceccd.log /var/log/icecc-scheduler.log
chown icecc:icecc /var/log/iceccd.log /var/log/icecc-scheduler.log
/etc/init.d/cron start

#MODE="$1"
#ENABLE_SCHEDULER="$2"
#SCHEDULER_IP="$3"
#CPUS="$4"


case $MODE in
	live) scheduler_port=8765
	      iceccd_port=10245
	      netname=$MODE
	;;
	test) scheduler_port=28765
	      iceccd_port=20245
	      netname=$MODE
	;;
	*) echo "select live/test"
	   exit 1;
	;;
esac


case $ENABLE_SCHEDULER in
        yes) icecc-scheduler -d -n $netname -l /var/log/icecc-scheduler.log -p $scheduler_port -vvvv;tail -f /var/log/icecc*.log
             #iceccd -d -s $SCHEDULER_IP -m $CPUS -n $netname -l /var/log/iceccd.log -p $iceccd_port --cache-limit $CACHE_SIZE  --no-remote -vvvv;tail -f /var/log/icecc*.log
        ;;
        no)  iceccd -d -s $SCHEDULER_IP -m $CPUS -n $netname -l /var/log/iceccd.log -p $iceccd_port --cache-limit $CACHE_SIZE -vvvv;tail -f /var/log/icecc*.log
        ;;
        *)   echo "select scheduler enable yes/no"
	     exit 1;
        ;;
esac
