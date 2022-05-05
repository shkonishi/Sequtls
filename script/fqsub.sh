#!/bin/bash
VERSION=0.0.1
AUTHOR=SHOGO_KONISHI[shkonishi@gmail.com]
CMDNAME=`basename $0`

# print help document of this script
function print_doc() {
cat << EOS
Usage:
    $CMDNAME [options] <INPUT>

Description:
    This script extracts a random subset from a fastq file. In the single-ended case, the results are displayed on standard output. In the paired-end case, the results are written to a file.

Options:
  -n <INT>  Size of subset [default: 10000]
  -s <INT>  Seed number
  -h        Print this document

Examples:
    $CMDNAME -n 1000 input.fastq > sub.fastq
    $CMDNAME -n 100 -s 123 input_R1.fastq.gz input_R2.fastq.gz

EOS
}

# Argument check 01: optional arguments
while getopts n:s:h OPT
do
  case $OPT in
    "n" ) FLG_n="TRUE" ; VALUE_n="$OPTARG"
      if [[ ! $VALUE_n =~ ^[1-9][0-9]*$ ]] ; then
        echo "Must be an integer value greater than or equal to 1: -n";
        exit 1
      fi ;;
    "s" ) FLG_s="TRUE" ; VALUE_s="$OPTARG";
      if [[ ! $VALUE_s =~ ^[1-9][0-9]*$ ]] ; then
        echo "Must be an integer value greater than or equal to 1: -s";
        exit 1
      fi ;;
    "h" ) print_doc; exit 1 ;;
     \? ) print_doc; exit 1 ;;
  esac
done
shift `expr $OPTIND - 1`

# argument check 03: set default settings
if [[ -z $VALUE_n ]] ; then
  VALUE_n=10000
fi
if [[ -n $VALUE_s ]] ; then
  RANDOM=$VALUE_s
fi


# argument check 05: no optional arguments
if [[ $# = 2 ]]; then # paired-end
  for fp in $@; do
    if [ -f $fp ]; then
      echo "${fp} exists"
    else
      echo "Your input files don't exists."
      exit 1
    fi
  done

  R1=$1
  R2=$2

elif [[ $# = 1 ]]; then # single end
  if [ -f $@ ]; then
    echo "$1 exists"
  else
    echo "Your input files don't exists."
    exit 1
  fi

  R1=$1

else
  echo "One or two arguments are required as the fastq file path."
  print_doc
  exit 1
fi
