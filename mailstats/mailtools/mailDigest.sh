#!/bin/bash

##### Thie script copy and process the maillog file, it always sleep 10 seconds before process the file ####
##### If the script run by the logrotate daemon, it does not sleep and occupies the flag file to process the log asap. ####

progpath=$(
cd -P -- "$(dirname -- "$0")" &&
pwd -P
)

. ${progpath}/mailstates.conf

MAIL_HOUSEKEEPING_DAYS=60

pid=$$

func_Init()
{
	if [[ ! -d ${MAIL_OUTPUT_PATH} ]]; then
		mkdir -p ${MAIL_OUTPUT_PATH}
	fi

        if [[ ! -d ${MAIL_BACKUP_PATH} ]]; then
                mkdir -p ${MAIL_BACKUP_PATH}
        fi

	# Copy back root own log to process log
	cat ${RSYNC_LOG} >> ${LOGFILE}
}

func_Exit()
{
	sleep 0
}

func_sysLogger()
{
	#logger -t "MailLogStats" "$1" 
        echo "$(date +"%F %T"): $1" >> ${LOGFILE}

}

## HouseKeep and process log file
function parseMailLog
{
        func_sysLogger "Convert Mail Log <Start>"
        perl ${PROG_PATH}/maillogconvert.pl standard < "${MAIL_PROCESSING}" > "${MAIL_PROCESSING}${MAIL_FILE_PROCESSING_EXTENSION}"

        #if [[ ${ACTION_CURRENT} -eq "rotate" ]]; then
	#	find ${MAIL_BACKUP_PATH} -mtime $((${MAIL_HOUSEKEEPING_DAYS:-30}*1)) -type f -exec rm {} \;
                #mv -f "${MAIL_TO_PATH}/${MAIL_TO_FILE}" "${MAIL_BACKUP_PATH}/${MAIL_TO_FILE}.$(date +'%Y%m%d')"
        #fi

	# Rename file after digestion complete
        mv "${MAIL_PROCESSING}${MAIL_FILE_PROCESSING_EXTENSION}" "${MAIL_PROCESSING}${MAIL_FILE_DIGESTED_EXTENSION}"

	# Move file to working directory of other program
	mv -f "${MAIL_PROCESSING}${MAIL_FILE_DIGESTED_EXTENSION}" "${MAIL_OUTPUT_PATH}"
        func_sysLogger "Convert Mail Log <End>"
}

function genStats
{
        func_sysLogger "Process Mail Log <Start>"
        bash ${PROG_PATH}/genstats.sh
        func_sysLogger "Process Mail Log <End>"
}

#### Main body
trap 'func_Exit' 0 1 2 3 9 15

ARGV=("$@")
while [ $# != 0 ]
do
	case "$1" in
		--rotate)
			ACTION_CURRENT="rotate"
			shift
			;;

		--cron)
			ACTION_CURRENT="cron"
			shift
			;;
		*)
			shift
			;;
	esac
done

func_Init

parseMailLog
genStats

exit 0

