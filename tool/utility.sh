#!/usr/bin/bash
#
# File: utility.sh
# Created: 15, December 2014
#
# Copyright (C) 2014, Jarielle Catbagan
#
# Licensed under BSD License
#
#
# Synopsis:
#
# This script file merely contains function definitions that are utilized in other script files.  This
# is done to alleviate clutter from other script files.
#
# To include these functions just 'source' this file.


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Description:
#	- LOGFILE variable must be preset before this function is invoked inorder to save the output to a
#	  file, otherwise it goes to standard output
# parameters:
#	- string(s) to output
# return:
#	- always returns '0'
log()
{
	if [ ! -z $LOGFILE ]; then
		echo -e "`date`: $@" >> $LOGFILE
	else
		echo -e "`date`: $@"
	fi
	
	return 0
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Description:
#	- this function invokes 'log()'
# Parameters:
#	- string(s) to output as error
# Return:
#	- always exits with a return value of '1' to indicate failure
abort()
{
	log "error: " $@

	exit 1
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Description:
#	- tests whether the specified link provided is valid
# Parameters:
#	- source link to test the validity of
# Return:
#	- '0' link is valid
#	- '1' link is invalid
test_link()
{
	ping -c 1 -W 1 -q $1 >/dev/null 2>&1
	
	return $?
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
