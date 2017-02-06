#!/bin/sh
SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -ExecutionPolicy RemoteSigned -NoProfile -File $DIR"/post-commit.ps1" $DIR

rc = $?;
if 
	[[ $rc != 0 ]] 
then 
	exit $rc
fi
