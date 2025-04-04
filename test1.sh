#!/bin/bash
#set -x
read -p  "enter your age: " age
eligibility=18
if [ $age -eq $eligibility ]; then
	echo "you are eligible"
else
	diff=$((age - eligibility))
	echo " you are eligible in $diff years"
fi

