#!/bin/sh 
#  OmniFocusCLI v.1.6
#  Created by Donald Southard aka @binaryghost
#  Last edited on November 12, 2012 05:03:17 PM CDT

#Check for empty task
usage ()
{
     echo "OmniFocusCLI v1.7"
     echo "	usage: OmniFocusCLI.sh [task with date and time info]"
     echo "	Create an OmniFocus task using Natural Language Processing"
}

if [ $# -lt 1 ]
then
    usage
    exit
fi


#IMPORTANT - USER INPUT in ARRAY
declare -a inputArray
inputArray=($*)


#Global Variables
d=86400 
my_context_check=1 
noon_check=0 
weekday_check=0 
monthname_check=0 
start_check=0
due_check=0
mon_day_check=0
num_date_check=0
due_check=0
abbrv_date_check=0
today=0
tomorrow=0
hr=12
wd=7
month=`date +%-m` #find current month
day_mon=`date +%-d`	#find current day of the month
day_week=`date +%w` #find current day of the week
due_today=0
due_tom=0


#Define Arrays
Months=(31 28 31 30 31 30 31 31 30 31 30 31)
Mon_names=('january' 'february' 'march' 'april' 'may' 'june' 'july' 'august' 'september' 'october' 'november' 'december')
Abbrv_Mon_names=('jan' 'feb' 'mar' 'apr' 'may' 'jun' 'jul' 'aug' 'sept' 'oct' 'nov' 'dec')
Week_days=('sunday' 'monday' 'tuesday' 'wednesday' 'thursday' 'friday' 'saturday')
Abbrv_days=('sun' 'mon' 'tues' 'wed' 'thurs' 'fri' 'sat' 'sun')


#READ CONTEXTS FROM DB -- WORK IN PROGRESS
declare -a contextArray
declare -a agendaArray
if [ ! -d ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/ ]; then
	contextArray=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus/OmniFocusDatabase2 'select name from context;'`)
else
	contextArray=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/OmniFocusDatabase2 'select name from context;'`)
fi

if [ ! -d ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/ ]; then
	agendaArray=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus/OmniFocusDatabase2 'select name from context where parent = ( select persistentIdentifier from context where name = "Agenda" or name = "Agendas" );'`)
else
	agendaArray=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/OmniFocusDatabase2 'select name from context where parent = ( select persistentIdentifier from context where name = "Agenda" or name = "Agendas" );'`)
fi

if [ ! -d ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/ ]; then
	phoneContext=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus/OmniFocusDatabase2 'select name from context where name = "@Phone" or name = "Phone";'`)
else
	phoneContext=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/OmniFocusDatabase2 'select name from context where name = "@Phone" or name = "Phone";'`)
fi

if [ ! -d ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/ ]; then
	homeContext=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus/OmniFocusDatabase2 'select name from context where name = "@Home" or name = "Home";'`)
else
	homeContext=(`sqlite3 ~/Library/Caches/com.omnigroup.OmniFocus.MacAppStore/OmniFocusDatabase2 'select name from context where name = "@Home" or name = "Home";'`)
fi

context_total=`echo ${#contextArray[*]}`
agenda_total=`echo ${#agendaArray[*]}`
agenda_used=0
not_agenda=0
input_counter=0
call_check=0
for i in "${inputArray[@]}"
do
		input_formatted=`echo $i | tr A-Z a-z`
			for (( c=0;c<$context_total;c++ )); do
			context_formatted=`echo ${contextArray[$c]} | tr A-Z a-z`
				if [[ $input_formatted = $context_formatted ]] && [[ $input_formatted != "for" ]] && [[ $input_formatted != "from" ]]
				then
					my_context=${contextArray[$c]}
					#Sub-array for comparing to agenda names so it doesn't delete people names from tasks
					if [ "$agenda_total" -eq 0 ]; then
						#If the "Agenda" context doesn't exsist, then skip the next loop and just remove context from task name.
						unset inputArray[$input_counter]
						if [ ${inputArray[($input_counter-1)]} == "at" ]; then
							(( input_counter=$input_counter-1 ))
							unset inputArray[$input_counter]
						fi
					else
						for (( a=0;a<$agenda_total;a++ )); do
							agenda_formatted=`echo ${agendaArray[$a]} | tr A-Z a-z`
							if [[ ${contextArray[$c]} == ${agendaArray[$a]} ]]
							then
							agenda_used=`echo ${contextArray[$c]} | tr A-Z a-z`
							else
							not_agenda=1
							fi
						done
					fi
					#only remove context from array if is NOT an agenda. 
					if [[ $not_agenda -eq 1 ]] && [[ $input_formatted != $agenda_used ]];then
						unset inputArray[$input_counter]
						if [ ${inputArray[($input_counter-1)]} == "at" ]; then
							(( input_counter=$input_counter-1 ))
							unset inputArray[$input_counter]
						fi
					fi
				fi
			done
			if [[ $phoneContext ]] && [[ $input_formatted = "call" ]]; then
				call_context=1
			fi
			if [[ $homeContext ]] && [[ -z $my_context ]] && [[ $input_formatted = "home" ]]; then
				my_context=$homeContext
			fi
			((input_counter++))	
done

#echo "Context Check (0/1): "$my_context_check
#echo "Context used: "$my_context
if [[ $call_context -eq 1 ]]; then
	my_context=$phoneContext
fi

if [ -z $my_context ]
then
	my_context_check=0
fi

#
#DUE DATE CODE
#
due_counter=0
input_total=`echo ${#inputArray[*]}`
for i in "${inputArray[@]}"
do
	if [[ $i = "due" ]] || [[ $i = "by" ]]; then
		due_check=1
		unset inputArray[$due_counter]
		((due_counter++))
		for (( k=$due_counter;k<input_total;k++)); do
		    #Main Variable for testing conditions
            testing_input=`echo ${inputArray[($due_counter)]}`
            if [[ $testing_input =~ ^[0-9]d ]] || [[ $testing_input =~ ^[0-9][0-9]d ]]; then
                num_days=`echo $testing_input | tr -dc '[0-9]'`
                temp_days=`echo ""$num_days"*$d" | bc`
                unset inputArray[$due_counter]
            else
                temp_days=0
            fi
    
            if [[ $testing_input =~ ^[0-9]w ]] || [[ $testing_input =~ ^[0-9][0-9]w ]]; then
                num_weeks=`echo $testing_input | tr -dc '[0-9]'`
                temp_weeks=`echo "("$num_weeks"*7)*$d" | bc`
                unset inputArray[$due_counter]
            else
                temp_weeks=0
            fi
    
            if [[ $testing_input =~ ^[0-9]m ]] || [[ $testing_input =~ ^[0-9][0-9]m ]]; then
                num_monthz=`echo $testing_input | tr -dc '[0-9]'`
                temp_monthz=`echo "("$num_monthz"*31)*$d" | bc`
                unset inputArray[$due_counter]
            else
                temp_monthz=0	
            fi
            #calculate total number of days until due
            ddays=`echo "$temp_days" + "$temp_weeks" + "$temp_monthz" | bc`
            
            #Find natural month due date i.e. Sept, August, July, Mar, jan
            mon_formatted=`echo $testing_input | tr A-Z a-z`
            #echo $mon_formatted
            for (( m=0;m<12;m++)); do
                mon_input=`echo ${Mon_names[${m}]}`
                abbrv_mon_input=`echo ${Abbrv_Mon_names[${m}]}`
                if [[ $mon_formatted = "$mon_input" ]] || [[ $mon_formatted = "$abbrv_mon_input" ]]; then		
                    month=`date +%-m`
                    my_mon=`echo "("$m"+1)" | bc`
                    month_counter_max=$m
                    NatMon_day_counter=0
                    array_var=${Months[$asdf]}
                    i=`echo "("$day_mon"+1)" | bc`
                    x=`date +%-m`
                    if [[ $my_mon -ne $month ]]; then
                        while [[ $x -le $month_counter_max ]]
                        do
                            while [[ $i -le $array_var ]]; do
                            (( NatMon_day_counter++ ))
                            (( i++ ))
                            done		
                            month=`echo "("$month"+1)" | bc`
                            array_var="${Months[$month]}"
                            i=1
                            ((x++))
                        done
                        if [[ ${Months[($m)]} -eq 30 ]]; then
                            NatMon_day_counter=`echo "("$NatMon_day_counter"+1)" | bc`
                        elif [[ ${Months[($m)]} -eq 28 ]]; then
                            NatMon_day_counter=`echo "("$NatMon_day_counter"+3)" | bc`
                        fi  
                    fi
                fi
            done
            #Finds slash dates i.e. 8/30 , 12/12
            if [[ $testing_input =~ ^[0-9]/[0-9] ]] || [[ $testing_input =~ ^[0-9][0-9]/[0-9] ]] || [[ $testing_input =~ ^[0-9]/[0-9[0-9]] ]] || [[ $testing_input =~ ^[0-9][0-9]/[0-9][0-9] ]]; then
                num_date_check=1
                start_value_mon=`echo $testing_input | sed 's/\/[0-9]*//'`
                start_value_day=`echo $testing_input | sed 's/[0-9]*\///'`
                result_day=`echo "$start_value_day" | bc`
                month_counter_max=`echo "("$start_value_mon"-1)" | bc`
                due_day_counter=0
                array_var=${Months[$month_counter]}
                i=`echo "("$day_mon"+1)" | bc`
                x=`date +%-m`
                if [[ "$start_value_mon" -ne $month ]]; then
                    while [[ $x -le $month_counter_max ]]
                    do
                        while [[ $i -le $array_var ]]; do
                        (( due_day_counter++ ))
                        (( i++ ))
                        done		
                        month=`echo "("$month"+1)" | bc`
                        array_var="${Months[$month]}"
                        i=1
                        ((x++))
                    done
        
                    if [[ ${Months[("$start_value_mon"-1)]} -eq 31 ]] 
                    then
                        due_day_counter=`echo "("$day_counter"-1)" | bc`
                        echo $due_day_counter
                    fi
                    else
                    if [[ "$start_value_day" -gt $day_mon ]]; then
                        result_due_day=`echo ""$start_value_day"-$day_mon" | bc`
    
                    fi
                fi
            fi
            h=`echo ${inputArray[($due_counter+1)]}`
            if [[ $h =~ [0-9]st ]] || [[ $h =~ [0-9]nd ]] || [[ $h =~ [0-9]rd ]] || [[ $h =~ [0-9]th ]] || [[ $h =~ [0-9][0-9]st ]] || [[ $h =~ [0-9][0-9]nd ]] || [[ $h =~ [0-9][0-9]rd ]] || [[ $h =~ [0-9][0-9]th ]]; then
                mon_day_check=1
                mon_day_taskname=$h
                start_value_day=`echo $h | sed 's/st*//' | sed 's/nd*//' | sed 's/rd*//' | sed 's/th*//'`
                result_due_day=`echo "("$start_value_day"-1)" | bc`           
            fi
            #find specific due date in Hours
            if [[ $testing_input =~ ^[0-9]am ]] ||  [[ $testing_input =~ ^[0-9][0-9]am ]]; then
                time_value=`echo $testing_input | sed 's/am//'`
                unset inputArray[$due_counter]	
               
                
            elif [[ $testing_input =~ ^[0-9]:[0-9][0-9]am ]] ||  [[ $testing_input =~ ^[0-9][0-9]:[0-9][0-9]am ]]; then
                time_value=`echo $testing_input | awk 'BEGIN { FS = ":" } ; { print $1}' | tr -dc '[0-9]'`
                unset inputArray[$due_counter]	
                
            elif [[ $testing_input =~ ^[0-9]pm ]] || [[ $testing_input =~ ^[0-9][0-9]pm ]]; then
                time_value_pm=`echo $testing_input | sed 's/pm//'`
                time_value=`echo ""$time_value_pm"+$hr" | bc`
                if [[ $time_value = 24 ]]; then
                    time_value=12
                fi
                unset inputArray[$due_counter]	
            elif [[ $testing_input =~ ^[0-9]:[0-9][0-9]pm ]] ||  [[ $testing_input =~ ^[0-9][0-9]:[0-9][0-9]pm ]]; then
                time_value_pm=`echo $testing_input | awk 'BEGIN { FS = ":" } ; { print $1}' | tr -dc '[0-9]'`
                time_value=`echo ""$time_value_pm"+$hr" | bc`
                if [[ $time_value = 24 ]]; then
                    time_value=12
                fi
                unset inputArray[$due_counter]	
            elif [[ $noon_formatted =~ "noon" ]]; then
                time_value=12
                unset inputArray[$due_counter]	
            fi
            #Find weekday name
            input_formatted=`echo $testing_input | tr A-Z a-z`
            for (( w=0;w<7;w++)); do
                week_day_input=`echo ${Week_days[${w}]}`
                abbrv_day_input=`echo ${Abbrv_days[${w}]}`
                if [[ $input_formatted = "$week_day_input" ]] || [[ $input_formatted = "$abbrv_day_input" ]]; then
                        if [[ $w -ge $day_week ]]; then
                            ((week_day_value=$w-$day_week))
                        elif [[ $w -lt $day_week ]]; then
                            ((week_day_value=7-$day_week+$w))
                        fi
                        unset inputArray[$due_counter]
                    
                fi
            done
            #Check for a due date of Today
            if [ "$input_formatted" = "today" ]; then
                due_today=1
                unset inputArray[$due_counter]
            fi
             #Check for a due date of tomorrow
            if [[ "$input_formatted" = "tomorrow" ]] || [[ $input_formatted = "tom" ]]; then
                due_tom=1
                unset inputArray[$due_counter]
            fi
            #insert next due check code here:
            
            ((due_counter++))        
        done
	else
		((due_counter++))
	fi
done

#
#START DATE CODE
#
scounter=0
for i in "${inputArray[@]}"
do
		if [[ $i =~ ^[0-9]d ]] || [[ $i =~ ^[0-9][0-9]d ]]; then
			num_days=`echo $i | tr -dc '[0-9]'`
			temp_days=`echo ""$num_days"*$d" | bc`
			unset inputArray[$scounter]
		else
			temp_days=0
		fi

		if [[ $i =~ ^[0-9]w ]] || [[ $i =~ ^[0-9][0-9]w ]]; then
			num_weeks=`echo $i | tr -dc '[0-9]'`
			temp_weeks=`echo "("$num_weeks"*7)*$d" | bc`
			unset inputArray[$scounter]
		else
			temp_weeks=0
		fi

		if [[ $i =~ ^[0-9]m ]] || [[ $i =~ ^[0-9][0-9]m ]]; then
			num_monthz=`echo $i | tr -dc '[0-9]'`
			temp_monthz=`echo "("$num_monthz"*31)*$d" | bc`
			unset inputArray[$scounter]
		else
			temp_monthz=0	
		fi

		((scounter++))

done
sdays=`echo "$temp_days" + "$temp_weeks" + "$temp_monthz" | bc`

#This on checks for a start date in a (#|##)/(#|##) format
#Complicated embedded loops and arrays... good luck figuring this code out :P 
for i in "$@"
do
	if [[ $i =~ ^[0-9]/[0-9] ]] || [[ $i =~ ^[0-9][0-9]/[0-9] ]] || [[ $i =~ ^[0-9]/[0-9[0-9]] ]] || [[ $i =~ ^[0-9][0-9]/[0-9][0-9] ]]; then
		num_date_check=1
		start_value_mon=`echo $i | sed 's/\/[0-9]*//'`
		start_value_day=`echo $i | sed 's/[0-9]*\///'`
		#echo "Start value (month): "$start_value_mon
		#echo "Start value (day): "$start_value_day
		result_day=`echo "$start_value_day" | bc`
		month_counter_max=`echo "("$start_value_mon"-1)" | bc`
		day_counter=0
		array_var=${Months[$month_counter]}
		i=`echo "("$day_mon"+1)" | bc`
		x=`date +%-m`
		if [[ "$start_value_mon" -ne $month ]]; then
		while [[ $x -le $month_counter_max ]]
		do
			while [[ $i -le $array_var ]]; do
			(( day_counter++ ))
			(( i++ ))
			done		
			month=`echo "("$month"+1)" | bc`
			array_var="${Months[$month]}"
			i=1
			((x++))
		done
		start_check=1
			if [[ ${Months[("$start_value_mon"-1)]} -eq 31 ]] 
			then
				day_counter=`echo "("$day_counter"-1)" | bc`
			fi
		#echo "Number of days from month inputed passed: "$day_counter
		#echo "Number of days from day inputed passed: "$result_day
		else
			if [[ "$start_value_day" -gt $day_mon ]]; then
				result_day=`echo ""$start_value_day"-$day_mon" | bc`
				start_check=1
			fi
		fi
	fi
#start_check=1
done

#Find name of month and set it start date
for i in "$@"
do
	mon_formatted=`echo $i | tr A-Z a-z`
	for (( m=0;m<12;m++)); do
	    mon_input=`echo ${Mon_names[${m}]}`
		abbrv_mon_input=`echo ${Abbrv_Mon_names[${m}]}`
		if [[ $mon_formatted = "$mon_input" ]] || [[ $mon_formatted = "$abbrv_mon_input" ]]; then
			monthname_check=1
			monthname_taskname=$i			
			month=`date +%-m`
			my_mon=`echo "("$m"+1)" | bc`
			month_counter_max=$m
			NatMon_day_counter=0
			array_var=${Months[$asdf]}
			i=`echo "("$day_mon"+1)" | bc`
			x=`date +%-m`
			if [[ $my_mon -ne $month ]]; then
				while [[ $x -le $month_counter_max ]]
				do
					while [[ $i -le $array_var ]]; do
					(( NatMon_day_counter++ ))
					(( i++ ))
					done		
					month=`echo "("$month"+1)" | bc`
					array_var="${Months[$month]}"
					i=1
					((x++))
				done
				if [[ ${Months[($m)]} -eq 30 ]]; then
					NatMon_day_counter=`echo "("$NatMon_day_counter"+1)" | bc`
				elif [[ ${Months[($m)]} -eq 28 ]]; then
					NatMon_day_counter=`echo "("$NatMon_day_counter"+3)" | bc`
				fi
				start_check=1
			fi
		fi
	done
done

#check for numerical day after natural month ending "th""st""nd""rd"
for i in "$@"
do
	if [[ $i =~ [0-9]st ]] || [[ $i =~ [0-9]nd ]] || [[ $i =~ [0-9]rd ]] || [[ $i =~ [0-9]th ]] || [[ $i =~ [0-9][0-9]st ]] || [[ $i =~ [0-9][0-9]nd ]] || [[ $i =~ [0-9][0-9]rd ]] || [[ $i =~ [0-9][0-9]th ]]; then
		mon_day_check=1
		mon_day_taskname=$i
		start_value_day=`echo $i | sed 's/st*//' | sed 's/nd*//' | sed 's/rd*//' | sed 's/th*//'`
		#echo "Start value (day): "$start_value_day
		result_day=`echo "("$start_value_day"-1)" | bc`
		start_check=1
	fi
done

#check for week day name as start value
wd_counter=0
for i in "${inputArray[@]}"
do
	day_formatted=`echo $i | tr A-Z a-z`
	for (( w=0;w<7;w++)); do
	    week_day_input=`echo ${Week_days[${w}]}`
		abbrv_day_input=`echo ${Abbrv_days[${w}]}`
		if [[ $day_formatted = "$week_day_input" ]] || [[ $day_formatted = "$abbrv_day_input" ]]; then
			word_by=${inputArray[($wd_counter-1)]}
			if [[ $word_by = "by" ]]; then
				unset inputArray[$wd_counter]
				tempy=$wd_counter-1
				unset inputArray[$tempy]
				if [[ $w -ge $day_week ]]; then
					((days_due=$w-$day_week))
					due_check=1
				elif [[ $w -lt $day_week ]]; then
					((days_due=7-$day_week+$w))
					due_check=1
				fi
			else
				unset inputArray[$wd_counter]
				if [[ $w -ge $day_week ]]; then
					((week_day_value=$w-$day_week))
					#echo "Week day value passed: "$week_day_value
					start_check=1
				elif [[ $w -lt $day_week ]]; then
					((week_day_value=7-$day_week+$w))
					#echo "Week day value passed: "$week_day_value
					start_check=1
				fi
			fi
		fi
	done
	((wd_counter++))
done


#Find time #(am|pm) format and check for "noon"
input_counter=0
for i in "${inputArray[@]}"
do
	noon_formatted=`echo $i | tr A-Z a-z`
	if [[ $i =~ ^[0-9]am ]] ||  [[ $i =~ ^[0-9][0-9]am ]]; then
		time_value=`echo $i | sed 's/am//'`
		unset inputArray[$input_counter]
		start_check=1
	elif [[ $i =~ ^[0-9]:[0-9][0-9]am ]] ||  [[ $i =~ ^[0-9][0-9]:[0-9][0-9]am ]]; then
		time_value=`echo $i | awk 'BEGIN { FS = ":" } ; { print $1}' | tr -dc '[0-9]'`
		unset inputArray[$input_counter]
		start_check=1
	elif [[ $i =~ ^[0-9]pm ]] || [[ $i =~ ^[0-9][0-9]pm ]]; then
		time_value_pm=`echo $i | sed 's/pm//'`
		time_value=`echo ""$time_value_pm"+$hr" | bc`
		if [[ $time_value = 24 ]]; then
			time_value=12
		fi
		unset inputArray[$input_counter]
		start_check=1
	elif [[ $i =~ ^[0-9]:[0-9][0-9]pm ]] ||  [[ $i =~ ^[0-9][0-9]:[0-9][0-9]pm ]]; then
		time_value_pm=`echo $i | awk 'BEGIN { FS = ":" } ; { print $1}' | tr -dc '[0-9]'`
		time_value=`echo ""$time_value_pm"+$hr" | bc`
		if [[ $time_value = 24 ]]; then
			time_value=12
		fi
		unset inputArray[$input_counter]
		start_check=1
	elif [[ $noon_formatted =~ "noon" ]]; then
		time_value=12
		start_check=1
		unset inputArray[$input_counter]
	fi
	((input_counter++))
done
#echo "Start date (hours): "$time_value

#This on checks for a time : minutes
for i in "$@"
do
	if [[ $i =~ ^[0-9]:[0-9][0-9](am|pm) ]] || [[ $i =~ ^[0-9][0-9]:[0-9][0-9](am|pm) ]]; then
		minutes=`echo $i | awk 'BEGIN { FS = ":" } ; { print $2}' | tr -dc '[0-9]'`
		#echo "Start date (minutes): "$minutes
		start_check=1
	fi
done
#echo "Start date (minutes): "$minutes

#Check for a start date of Today
input_counter=0
for i in "${inputArray[@]}"
do
	today_formatted=`echo $i | tr A-Z a-z`
	if [ $today_formatted = "today" ]; then
		unset inputArray[$input_counter]
		today=1
	fi
	((input_counter++))
done


#Check for a start date of Tomorrow
tom_counter=0
for i in "${inputArray[@]}"
do
	tom_formatted=`echo $i | tr A-Z a-z`
	if [[ $tom_formatted = "tomorrow" ]] || [[ $i = "tom" ]]; then
		unset inputArray[$tom_counter]
		tomorrow=1
	fi
	((tom_counter++))
done


#Check if for any reason the last word is at and remove if it is
total=${#inputArray[*]}
other_total=`echo "$total"-1 | bc`
last_word=${inputArray[${total}]}
other_last_word=${inputArray[($total-1)]}
if [[ "$last_word" = "at" ]] || [[ "$last_word" = [:blank:] ]]; then
	unset inputArray[$total]
elif [[ "$other_last_word" = "at" ]] || [[ "$last_word" = [:blank:] ]];then
	unset inputArray[$other_total]
fi

#Rebuilt Code to construct the task name
task_name=${inputArray[@]}

if [[ $weekday_check -gt 0 ]]; then
	task_name=`echo $task_name | sed "s/$weekday_taskname//g"`
fi

if [[ $monthname_check -gt 0 ]]; then
	task_name=`echo $task_name | sed "s/$monthname_taskname//g"`
fi

if [[ $mon_day_check -gt 0 ]]; then
	task_name=`echo $task_name | sed "s/$mon_day_taskname//g"`
fi

if [[ $abbrv_date_check -gt 0 ]]; then
	task_name=`echo $task_name | sed "s/$abbrv_date_taskname//g"`
fi

if [[ $num_date_check -gt 0 ]]; then
	task_name=`echo $task_name | sed 's/[0-9]*\/[0-9]*//g'`
fi

osascript <<EOS
	tell application "System Events"
	   count (every process whose name is "OmniFocus")
		if result < 1 then
		tell application "OmniFocus" to activate
		--Uncomment line below to hide OmniFocus when launched
 		--set visible of process "OmniFocus" to false
		end if
	end tell
	
  tell front document of application "OmniFocus"
	if "$my_context_check" > 0 then
	set theContext to "$my_context"
	set MyContextArray to null
	set MyContextArray to complete theContext as context maximum matches 1
	set MyContextID to id of first item of MyContextArray
	set ThisContext to context id MyContextID
	set theTask to make new inbox task with properties {name:"$task_name", context:ThisContext}
	else
	set theTask to make new inbox task with properties {name:"$task_name"}
	end if
	
	set theDate to (current date) - (time of (current date))
	
	
	if "$start_check" = "1" then
	set theDate to (current date) - (time of (current date)) + ("$day_counter" * days) + ("$NatMon_day_counter" * days) + ("$result_day" * days) + ("$th_num_days" * days) + ("$week_day_value" * days) + ("$time_value" * hours) + ("$minutes" * minutes)
	set the start date of theTask to theDate	
	end if
	
	if "$due_check" = "1" then
	set theDueDate to (current date) - (time of (current date)) + ("$days_due" * days) + ("$week_day_value" * days) + ("$NatMon_day_counter" * days) + ("$day_counter" * days) + ("$result_due_day" * days) + ("$time_value" * hours) + ("$minutes" * minutes)
	set the due date of theTask to theDueDate	
	end if	
	
	if "$sdays" > 0 then
	set theDate to current date
	set time of theDate to "$sdays"
	set the start date of theTask to theDate
	end if
	
	if "$ddays" > 0 then
	set theDate to current date
	set time of theDate to "$ddays"
	set the due date of theTask to theDate
	end if
	
	if "$today" = "1" then
		set theDate to (current date) - (time of (current date))
		set the start date of theTask to (theDate + (0 * hours)) + ("$time_value" * hours) + ("$minutes" * minutes)
	end if
	
	if "$tomorrow" = "1" then
		set theDate to (current date) - (time of (current date))
		set the start date of theTask to (theDate + (24 * hours)) + ("$time_value" * hours) + ("$minutes" * minutes)
	end if
	
	if "$due_today" = "1" then
		set theDate to (current date) - (time of (current date))
		set the due date of theTask to (theDate + (0 * hours)) + ("$time_value" * hours) + ("$minutes" * minutes)
	end if
	
	if "$due_tom" = "1" then
		set theDate to (current date) - (time of (current date))
		set the due date of theTask to (theDate + (24 * hours)) + ("$time_value" * hours) + ("$minutes" * minutes)
	end if
	
 	end tell
EOS

if [[ $task_name ]]; then
    echo "Inbox task created: $task_name"
fi
