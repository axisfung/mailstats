#!/bin/bash

##### Thie script copy and process the maillog file, it always sleep 10 seconds before process the file ####
##### If the script run by the logrotate daemon, it does not sleep and occupies the flag file to process the log asap. ####

PROG_PATH="/opt/production/mailstats/mailtools"

. $PROG_PATH/mailstates.conf

FLAG_LOCK_FILE="/tmp/mailstats.lock"

ACTION_CURRENT=""
pid=$$

func_Init()
{
        if [[ ! -f ${RSYNC_LOG} ]]; then
                exec su -l opm -c "touch ${RSYNC_LOG}"
        fi
        echo -n > ${RSYNC_LOG}


	if [[ -f ${FLAG_LOCK_FILE} ]]; then
		# If file older than 30 mins
		local filetime=$(cat ${FLAG_LOCK_FILE})
		if [[ $(( $(date +'%s') - ${filetime} )) -gt 1800 ]]; then
			func_sysLogger "mailstats[$pid]: FLAG_LOCK_FILE timestamp is too old ($(date --date=@$filetime)). Timestamp truncate."
			rm ${FLAG_LOCK_FILE}
		fi
        fi

        if [[ ! -d ${MAIL_PROCESS_PATH} ]]; then
                mkdir -p ${MAIL_PROCESS_PATH}
        fi
}

func_Exit()
{
	if [[ -f ${FLAG_LOCK_FILE} ]]; then
		rm ${FLAG_LOCK_FILE}
	fi
        sleep 0
}

func_sysLogger()
{
	#logger -t "MailLogStats" "$1" 
	echo "$(date +"%F %T"): $1" >> ${RSYNC_LOG}
}

function copyMailLog
{
	if [[ ! -f ${FLAG_LOCK_FILE} ]]; then
        	echo "$(date +'%s')" > ${FLAG_LOCK_FILE}
	else
		func_sysLogger "mailstats[$pid]: Other process exists. Thread exit."
		exit 2
	fi

        func_sysLogger "Rsync file (${MAIL_SYSFILE})"
        starttime=$(date +%s)
        rsync -rtu ${MAIL_SYSFILE} "${MAIL_PROCESSING}"
	statusCode=$#
        stoptime=$(date +%s)
        func_sysLogger "Rsync exit in $((stoptime-starttime)) seconds with code($statusCode)"
}

#### Main body
trap 'func_Exit' 0 

func_Init
copyMailLog

exit 0

