#!/bin/bash

progpath=$(
cd -P -- "$(dirname -- "$0")" &&
pwd -P
)

. ${progpath}/mailstates.conf

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

## TO allow logroate daemon to run this before the cron daemon
if [[ ! ${ACTION_CURRENT} == ${ACTION_SPECIAL} ]]; then
        sleep 10
fi

${progpath}/copyMailLog.sh && exec su -l opm -c ${progpath}/mailDigest.sh

