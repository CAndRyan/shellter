#!/bin/sh

# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
RED='\033[0;31m'
NC='\033[0m' # No Color

SOURCE="${BASH_SOURCE[0]}"
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -ExecutionPolicy RemoteSigned -NoProfile -File $DIR"/pre-commit.ps1" $DIR

rc=$?
if [ ! $rc -eq 0 ]; then
	echo -e "${RED}Pre-Commit script failed with code: $rc${NC}"
	exit $rc
fi
