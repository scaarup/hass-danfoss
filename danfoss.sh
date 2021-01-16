#!/bin/bash
defcolor="\033[0m\033[40;38;5;82m"
hon="\033[39;41m"
hoff="\033[42m"
# Bearer token for Home Assistant API
token=''
ids=(
'01:Controller'
'02:Livingroom1'
'03:Livingroom2'
'04:Livingroom3'
'05:Livingroom4'
'06:Bedroom'
'07:1st_floor1'
'08:1st_floor2'
'11:Livingroom_thermostat'
'12:1st_floor_thermostat'
'13:Emilie'
'14:Rasmus'
'15:Guestroom'
'16:Basement1'
'17:Basement2'
)

declare -A BAT
declare -A TARGET

function publish {
	if [[ -z "$2" && -z "$3" ]]; then
		echo returning
		return
	fi
	from=$2
	from=$(echo $2 | sed 's/://g')
	temp=$4
	battery=$4
#	echo "from: $from, temp:$temp, battery:$battery"
	# save states:
	if [[ "$1" == "x" ]]; then
		curl -X POST -H "Authorization: Bearer $token" \
	          -H "Content-Type: application/json" \
		        -d '{"state": "'$temp'", "attributes": {"unit_of_measurement": "°C","battery": "'$battery'","target":"'${TARGET[${from}]}'"}}' \
		        http://$ha:8123/api/states/sensor.${from}_radiator
		echo "from: $from end from"
		echo '{"state": "'$temp'", "attributes": {"unit_of_measurement": "°C","battery": "'$battery'","target":"'${TARGET[${from}]}'"}}'
		BAT[${from}]=$battery
	else
		curl -X POST -H "Authorization: Bearer $token" \
	          -H "Content-Type: application/json" \
		        -d '{"attributes": {"target":"'${TARGET[${from}]}'"}}' \
		        http://$ha:8123/api/states/sensor.${from}_radiator
		TARGET[${from}]=$temp
	fi
}

function colorizeIds {
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
}
colorizeIds

function idToName {
	for id in "${ids[@]}"; do
		echo $id|egrep "^$1" &>/dev/null && echo $id
		echo $id|egrep "^$1" |cut -f2 -d:
	done
}
while read input; do
	unset bat
	unset target_temp1
	unset current_temp1
	from=$(echo $input|egrep -o '[0-9][0-9] \-> [0-9][0-9]'|cut -f1 -d" ")
	fromname=$(idToName $from)
	to=$(echo $input|egrep -o '[0-9][0-9] \-> [0-9][0-9]'|cut -f3 -d" ")
	toname=$(idToName $to)
	data=$(echo $input|egrep -o '0x[0-9A-F]+')
	datalength=$(echo -n $data| wc -c|awk '{print $1}')
	if [[ "$datalength" == "94" ]]; then
		bat=$((16#${data:82:2}))
		x=$((16#${data:70:4}))
		target_temp1="${x:0:2}.${x:2:2}"
		x=$((16#${data:66:4}))
		current_temp1="${x:0:2}.${x:2:2}"
		type="Connect Thermostat"
	elif [[ "$datalength" == "34" ]]; then
		x=$((16#${data:22:4}))
		target_temp1="${x:0:2}.${x:2:2}"
		type="Controller"
	elif [[ "$datalength" == "72" ]]; then
		x=$((16#${data:58:4}))
		target_temp1="${x:0:2}.${x:2:2}"
		type="RS Thermostat"
#	elif [[ "$datalength" == "0" ]]; then
#		sleep 0.1
#	elif [[ "$datalength" == "20" ]]; then
		#echo $input
#		continue
	else
#		echo "datalength does not match: $datalength"
		continue
	fi
	hc=$defcolor
	if [[ "$type" == "Connect Thermostat" ]]; then
		x=$((16#${data:78:4}))
		if [[ "$x" == "0" ]]; then
			heating=" OFF "
			hc=$hoff
		elif [[ "$x" -gt "0" ]]; then
			heating=" ON "
			hc=$hon
		else
			echo "error: 1337"
		fi
	else
		heating=n/a
	fi
	if [[ ! -z "$bat" ]]; then
		batr=$bat
		bat="Battery lvl: $bat"
	fi
	echo -ne $defcolor
	COLUMNS=$(tput cols)
	printf "$(date +"%H:%M:%S")${randomcolor[${from#0}]}%*s${defcolor} \
-> %*s%*s%*s%*s\n" $(((${#title}+$COLUMNS)/10)) "$from/$fromname" \
$(((${#title}+$COLUMNS)/8)) "$to/$toname" $(((${#title}+$COLUMNS)/8)) " Current temp.: $target_temp1" $(((${#title}+$COLUMNS)/8)) "Unknown temp.: $current_temp1" $(((${#title}+$COLUMNS)/8)) "State: $heating $bat"
	if [[ "$fromname" == "Livingroom" || "$fromname" == "1st_floor" ]]; then
		fromname="$fromname_$from"
	fi
	if [[ ! "$fromname" == "Controller" ]]; then
		#echo "jokum $target_temp1 jokum"
		publish x $fromname $target_temp1 $batr
	else
		publish y $toname $target_temp1 0
	fi
	#printf "%s -> %50s %50s C Type=%s\n" "$from/$fromname" "$to/$toname" "$temp1" "$type"
	echo -ne "\033[0m"
	hex=$(echo ${data:2} | sed 's/.\{4\}/& /g')
	hex2=$(echo ${data:2} | sed 's/.\{2\}/& /g')
	hex8=$(echo ${data:2} | sed 's/.\{8\}/& /g')
	#echo -ne "\t"
done < "${1:-/dev/stdin}"
