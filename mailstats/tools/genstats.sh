#!/bin/bash

## PY
## Date: 2015-Apr-01

STATIC_DEST="/opt/production/mailstats/"
CONFIG_DIR="/etc/awstats/"
OUTPUT_DIR="${STATIC_DEST}/../statsweb/"

function generateStat()
{
	REP_YEAR=$( date '+%Y' )
	REP_MONTH=$( date '+%m' )
	if [[ ${#@} -eq 2 ]]; then
		REP_YEAR=$1; shift;
		REP_MONTH=$1
	fi

	for conf in $( ls "$CONFIG_DIR" | grep "^awstats\..*\.conf\$" | sed "s/^awstats\.\(.*\).conf\$/\1/" ); do

		dataDir=$( grep "^DirData" "$CONFIG_DIR/awstats.${conf}.conf" | sed "s/^.*=\(.*\)$/\1/" | sed "s/\"//g" )
                if [ ! -e "${dataDir}" ]; then
                         mkdir -p "${dataDir}"
                fi

		echo "Generating static pages for $conf for ${REP_YEAR}${REP_MONTH} ..."
		if [ ! -e "${OUTPUT_DIR}/${REP_YEAR}${REP_MONTH}" ]; then
			mkdir -p "${OUTPUT_DIR}/${conf}/${REP_YEAR}${REP_MONTH}"
                        chcon -R -t httpd_sys_content_t "${OUTPUT_DIR}/${conf}"
		fi
	
                perl ${STATIC_DEST}/tools/awstats_buildstaticpages.pl \
                        -awstatsprog=${STATIC_DEST}/wwwroot/cgi-bin/awstats.pl \
                        -update \
                        -config="$conf" \
                        -dir="${OUTPUT_DIR}/${conf}/${REP_YEAR}${REP_MONTH}" \
			-year=${REP_YEAR} \
                        -month=${REP_MONTH} \
                        2>&1 \
                | sed "s/^/  /" > /tmp/stats_${conf}.log

	done
}

## Generate for last month record if today is first day of month
if [[ "$( date +'%d' )" -eq "01" ]]; then
	generateStat $( date --date='-1 month' '+%Y' ) $( date --date='-1 month' '+%m' )
fi

## Generate for this month record
if [[ -z $(ls -Z ${OUTPUT_DIR}/index.html | grep httpd_sys_content_t) ]]; then
        chcon -R -t httpd_sys_content_t "${OUTPUT_DIR}"
fi

generateStat

cat > "${OUTPUT_DIR}/index.html" << EOF
<html><head><title>Mail - Static</title></head><body>
<h1>Mail - Static Statistics</h1>
<ul>
EOF

	for conf in $( ls "$CONFIG_DIR" | grep "^awstats\..*\.conf\$" | sed "s/^awstats\.\(.*\).conf\$/\1/" ); do
		echo "<b>Statistics for $conf</b>" >> "${OUTPUT_DIR}/index.html"
		for dir_conf in $( ls -lt ${OUTPUT_DIR}/${conf} | egrep '^d' | awk '{print $9}' ); do
			echo "<li><a href='${conf}/${dir_conf}/awstats.${conf}.html'>${dir_conf}</a></li>" \
			>> "${OUTPUT_DIR}/index.html"
		done
	done

cat >> "${OUTPUT_DIR}/index.html" << EOF
</ul>
<hr />
<div><em>Last update: $( date +"%F %T" )</em></div>
</body></html>
EOF
