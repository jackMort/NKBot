#!/bin/bash
#
# Copyright (C) 2009 Lech Twarog <lech.twaro@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# Changelog
# 	* 2008-08-03 22:13:02
# 		- updated getTicket
#
# 	* 2008-08-04 11:06:09
# 		- updated invite ( debug nk notification )
#
# 	* 2008-08-04 23:32:12
# 		- updated getTicket
#
# Last Modified: 2010-02-12 08:57:57

source configuration
source stdlib
source nk_lib

trap 'createReaport;exit 0' SIGINT SIGTERM

start_time=`date +"%Y-%m-%d %H:%M:%S"`
all_profiles=0

createReaport() 
{
	now=`date +"%Y-%m-%d %H:%M:%S"`
	
	start_stamp=`date2stamp "$start_time"`
	now_stamp=`date2stamp "$now"`
	date_diff=$[ ( $now_stamp - $start_stamp )]
	date_diff=`echo "scale=2; $date_diff/60" | bc`
	profiles_p_m=0
	if [ $all_profiles -gt 0 ]
	then
		profiles_p_m=`echo "scale=2; $all_profiles/$date_diff"|bc`
	fi
	
	echo -e " *** REPORT\n-----\n $start_time , stop at $now \n-----\nPROFILES VIEWED: $all_profiles\nPROFILES/MIN   : $profiles_p_m"
	
}

cleanUp()
{

	rm $INDEX_FILE $COOKIES_FILE 2> /dev/null
}

getTicket()
{
	cat $INDEX_FILE | grep add_friend_ticket | sed -e 's/,/\n/g' | awk -F':' '{print $1":"$2}' | grep add_friend_ticket | sed -e 's/".*"://g;s/"//g' > $INVITE_TICKET_FILE
	debug "using invite ticket: $bold`cat $INVITE_TICKET_FILE`$normal"
}

invite() 
{
	if [ -d $PROFILES_TMP/INVITED ] 
	then
		profile=$1
		profile_file=$PROFILES_TMP/INVITED/$profile

		INVITE_TICKET=`cat $INVITE_TICKET_FILE`
		RESPONSE=`$WGET --load-cookies="$COOKIES_FILE" --user-agent="$USER_AGENT" --post-data="t=$INVITE_TICKET" http://nasza-klasa.pl/invite/$profile -O $profile_file 2>&1|egrep "HTTP|Length|saved"`

		message=`cat $profile_file | grep notification_1 -A1 | grep '</div>'| sed -e 's/<[^>]*>//g'`
		s_color=$red

		if [ "$message" == "$SEND_MESSAGE_SUCCESS_PATTERN" ]
		then
			s_color=$green
		fi
		debug "... invite $bold$profile$normal $s_color$message$normal"

		case $RESPONSE in
			*200*) return 2 ;;
			*404*) return 4 ;;
			*500*) return 5 ;;
			*)  return 0
		esac
	else
		mkdir -p $PROFILES_TMP/INVITED
		invite $@
	fi
}

def_colors
cleanUp

login_sleep=0
until isLogged
do	
	debug "${red}cannot login trying again (total sleep $white$bold`format_time $login_sleep`$nobold${red})...$normal"
	sleep $SLEEP
	login_sleep=$[$login_sleep + $SLEEP]
	login
done

debug "Loged as $bold$USER$normal!"
getTicket

LAST_ID=`cat $LAST_ID_FILE`
for i in `seq $LAST_ID $MAX_ID`
do	
	NOT_SUCCESS=true
	while $NOT_SUCCESS
	do
		if [ `date +'%M'` -lt $WORK_TO_MINUTE ]
		then
			stats=( `./getStats $[ $i - 1 ]` )
			friends=${stats[0]}
			mails=${stats[1]}
			if [ $mails -gt 0 ] 
			then
				mail_info=", new emails ${bold}${green}$mails${normal}"
			fi
			

			debug "your friends ${bold}${red}${friends}${normal}$mail_info"
			invite $i
			response=$?
			case $response in
				2) 
				NOT_SUCCESS=false
				;;
				4) 
				debug "... ${bold}404 Not Found$normal"
				NOT_SUCCESS=false
				;;
				5)
				debug "... ${red}${bold}500 KICK $normal"
				debug "KICK" >> error.err
				sleep 10
				;;
				*) debug "OTHER RESPONSE: $response"
			esac
		else
			tofull=$[ 60 - `date +'%M'` ] 
			debug "... waiting to hour, $bold$tofull${bold}m. left"
			sleep 60
		fi
	done
	all_profiles=$[ $all_profiles + 1 ]

	# save last_id
	echo $i > $LAST_ID_FILE
	# get random sleep
	let sl=$RANDOM%$RANDOM_SLEEP+$RANDOM_SLEEP_FROM
	debug "going sleep to $bold$sl${normal}s."
	sleep $sl
done	

# vim: fdm=marker ts=4 sw=4 sts=4
