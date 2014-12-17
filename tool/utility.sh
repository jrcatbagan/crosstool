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
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
# Description:
#	- this function invokes 'log()'
# Parameters:
#	- string(s) to output as error
# Return:
#	- always exits with a return value of '1' to indicate failure
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
abort()
{
	log "error: " $@

	exit 1
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Description:
#	- tests whether the specified link provided is valid
# Parameters:
#	- source link to test the validity of
# Return:
#	- '0' link is valid
#	- '1' link is invalid
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
test_link()
{
	ping -c 1 -W 1 -q $1 >/dev/null 2>&1
	
	return $?
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Description:
# 	- downloads the file from the link specified
#	- both are arguments to this function
# Paramters:
#	- $1 = source link
#	- $2 = file to download
# Return:
#	- '0' for success
#	- '1' for error
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
download()
{
	wget $1/$2 # >/dev/null 2>&1
	
	return $?
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Description:
#	- extracts the compressed archive file accordingly
#	- removes the compressed file extension as the directory created from the 
#	  extraction has the same base name
# Parameters:
#	- file to extract; this must be the name of the variable, no expansion must take place for
#	  the argument
# Return:
#	- '0' extraction was successful
#	- '1' extraction failed
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
extract()
{
	local TMP
	eval TMP='$'$1
	case $TMP in
	*.bz2)
		echo $TMP
		tar -xvjf $TMP
		rm $TMP
		eval $1=`echo $TMP | sed 's/.tar.bz2//' -`
		;;
	*.gz)
		echo $TMP
		tar xvzf $TMP
		rm $TMP
		eval $1=`echo $TMP | sed 's/.tar.gz//' -`
		;;
	esac

	return $?
}
