#!/bin/bash

read -p "enter number:" num
if (( num % 2 ==0));then
	echo "$num is an even number"
else
	echo "$num is odd":
fi
