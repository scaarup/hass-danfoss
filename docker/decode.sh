#!/bin/bash
#
# CONFIGURATION
#
homeid=e771af41
token='fffffffffffffffffffffffffffffff'

# Patterns in payload which defines multiplier:
declare -A multipliers=(
["4720202021030020102011030f031703280318032f0330"]="1"
["8e40404042060040204022061e062e06500630065e0660"]="2"
["8e404040420600804080440c3c0c5c0ca00c600cbc0cc0"]="4"
)
declare -A ids=(
["1"]="controller"
["2"]="Livingroom1"
["3"]="Livingroom2"
["4"]="Livingroom3"
["5"]="Livingroom4"
["6"]="Bedroom"
["7"]="1st_floor1"
["8"]="1st_floor2"
["11"]="Livingroom_thermostat"
["12"]="1st_floor_thermostat"
["13"]="Emilie"
["14"]="Rasmus"
["15"]="Guestroom"
["16"]="Basement1"
["17"]="Basement2"
)
#
# END CONFIGURATION

declare -a COLORS=(
'\033[0;49;31m'
'\033[0;49;32m'
'\033[0;49;33m'
'\033[0;49;34m'
'\033[0;49;35m'
'\033[0;49;36m'
'\033[0;49;91m'
'\033[0;49;92m'
'\033[0;49;93m'
'\033[0;49;94m'
'\033[0;49;95m'
'\033[0;49;96m')
for id in ${ids[*]}; do
        id=$(echo $id|cut -f1 -d":")
        randomcolor["${id#0}"]=${COLORS[$RANDOM % ${#COLORS[@]} ]}
        randomcolor=("${randomcolor[@]}" "${randomcolor["${id#0}"]}")
done


while read input; do
	echo $input | grep "HomeId: $homeid" &>/dev/null || continue
	#echo $input
	# Map from to name
	from=$(echo $input | egrep -o 'SourceNodeId: [a-f0-9]{1,2}' | cut -f2 -d ' ')
	length=$(echo $input | egrep -o 'Length: [0-9]+' | cut -f2 -d ' ')
	if [[ "$from" == "1" ]]; then
		continue
	fi
	payload=$(echo $input | egrep -o 'Payload: ([a-f0-9]{2}\s)+' | sed 's/Payload: //'|sed 's/ //g')
	fromname=${ids[$((16#$from))]}
	# Determine type of device: radiator, thermostat, controller
	if [[ "$length" == "57" ]]; then # Radiator thermostat
	#	echo "source is radiator thermostat"
		mpattern=${payload:14:46}
		multiplier=${multipliers[$mpattern]}
#		echo "mpat $mpattern $multiplier"

		htemp=${payload:68:4}
		temp_=$(expr $((16#${payload:68:4})) / $multiplier)
		temp="${temp_:0:2}.${temp_:2:2}"
		target_temp_=$(expr $((16#${payload:72:4})) / $multiplier)
		target_temp="${target_temp_:0:2}.${target_temp_:2:2}"
#		bat=$(expr $((16#${payload:78:2})) / $multiplier)
	else
		continue
	fi
#	echo $fromname
	echo $input
#	echo "p $payload"
	#echo "JOKUM $temp $bat"
	echo "$fromname $multiplier" >> /entrypoint/log.log
	printf "$(date +"%H:%M:%S") source: $fromname ($((16#$from))), temperature: $temp ($htemp), target_temperature: $target_temp, battery: $bat, multiplier: $multiplier\n"
	echo "###########################"
#	echo "###########################"


	# Print
	#COLUMNS=$(tput cols)

	#${randomcolor[${from#0}]}%*s${defcolor} \
        #-> %*s%*s%*s%*s\n" $(((${#title}+$COLUMNS)/10)) "$from/$fromname" \
        #$(((${#title}+$COLUMNS)/8)) "$to/$toname" $(((${#title}+$COLUMNS)/8)) " Current temp.: $target_temp1" $(((${#title}+$COLUMNS)/8)) "Unknown temp.: $current_temp1" $(((${#title}+$COLUMNS)/8)) "State: $heating $bat"

done < "${1:-/dev/stdin}"
