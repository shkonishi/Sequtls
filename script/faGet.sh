#!/bin/bash
VERSION=0.0.1
AUTHOR=SHOGO_KONISH
CMDNAME=`basename $0`

# print help document of this script
function print_doc() {
cat << EOS
Usage:
    $CMDNAME [options] <INPUT>

Description:
    extract sequences from multifasta by ID string or file.
    Results are printed on standard output.

Options:
  -s <CHR>  Single ID string
  -i <CHR>  File path for IDs
  -h        Print this document

Examples:
    $CMDNAME -s id1 input.fa
    $CMDNAME -i id.txt input.fa

EOS
}

# Argument check 01: optional arguments
while getopts s:i:h OPT
do
  case $OPT in
    "s" ) STR="${OPTARG}";;
    "i" ) IN="${OPTARG}";;
    "h" ) print_doc; exit 1 ;;
     \? ) print_doc; exit 1 ;;
  esac
done
shift `expr $OPTIND - 1`

# argument check1:
if [[ -z "$STR" && -z "$IN" ]] ; then
  echo "The id string or file path to be used for the search is given as an argument."
elif [[ -n "$STR" ]]; then
  # Store id strings into an array
  ids=($STR)
elif [[ -n "$IN" && -f "$IN" ]]; then
  # Stores file contents into an array
  ids=($(cat $IN))
else
  print_doc
  exit 1
fi

# argument check2:
if [[ -f "$1" ]]; then
  fa=$1
else
  print_doc
  exit 1
fi

### MAIN ###
for i in ${ids[@]}; do
cat ${fa} | awk -v RS='>' -v ORS='' '$1~/'$i'/ {print RS $0}'
done
