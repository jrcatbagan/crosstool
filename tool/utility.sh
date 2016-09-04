#!/usr/bin/bash
#
# File: utility.sh
# Created: 15, December 2014
#
#
# Copyright (C) 2014 Jarielle Catbagan
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted 
# provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this list of conditions 
#   and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
#   and the following disclaimer in the documentation and/or other materials provided with the 
#   distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR 
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
