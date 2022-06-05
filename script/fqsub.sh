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
    This script extracts a random subset from a fastq file.
    The input format is bz2, gzip, or uncompressed fastq.
    The output file is automatically created as a file similar to
    the input file format.　If you do not specify a file name.
    The file name will be, for example, <prefix>_sub.fastq.gz.

Options:
  -n <INT>  Size of subset [default: 10000]
  -s <INT>  Seed number
  -o <CHR>  Read1 output filename
  -O <CHR>  Read2 output filename, in case of paired-end reads
  -h        Print this document

Examples:
    $CMDNAME -n 100 in_R1.fastq
    $CMDNAME -n 100 -s 123 in_R1.fastq in_R2.fq.gz
    $CMDNAME -n 100 -o r1_sub.fq -O r2_sub.fq in_R1.fastq in_R2.fastq
    $CMDNAME -n 100 -s123 -o - r1_sub.fq.gz

EOS
}

# Argument check 01: optional arguments
while getopts n:s:o:O:h OPT
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
    "o" ) VALUE_o="$OPTARG";;
    "O" ) VALUE_O="$OPTARG";;
    "h" ) print_doc; exit 1 ;;
     \? ) print_doc; exit 1 ;;
  esac
done
shift `expr $OPTIND - 1`

# Argument check 02: set default settings
# sanmpling size and seed number
if [[ -z $VALUE_n ]] ; then
  VALUE_n=10000
fi
if [[ -z $VALUE_s ]] ; then
  RAND=${RANDOM}
else
  RAND=${VALUE_s}
fi

# Argument check 03: Check the file format of the argument without options.
if [[ $# = 2 && -f $1 && -f $2 ]]; then  # paired-end
  if file $1 | grep -q "gzip" && file $2 | grep -q "gzip" ; then
    INSFX="gz"
  elif file $1 | grep -q "bzip2" && file $2 | grep -q "bzip2" ; then
    INSFX="bz2"
  elif file $1 | grep -q "ASCII" && file $2 | grep -q "ASCII"; then
    INSFX="fastq"
  else
    echo "The input file must be a gz or bz2 compressed fastq file or uncompressed fastq format. "
    exit 1
  fi

elif [[ $# = 1 && -f $1 ]]; then # single end
  if file $1 | grep -q "gzip" ; then
    INSFX="gz"
  elif file $1 | grep -q "bzip2" ; then
    INSFX="bz2"
  elif file $1 | grep -q "ASCII" ; then
    INSFX="fastq"
  else
    echo "The input file must be a gz or bz2 compressed fastq file or uncompressed fastq format. "
    exit 1
  fi

else
  echo "One or two arguments are required as the path to the fastq or compressed fastq file (gz|bz2)."
  exit 1
fi

# Argument check 04: default output file names as args
if [[ $# = 2 && -f $1 && -f $2 ]]; then # paired-end
  if [[ -n $VALUE_o && -n $VALUE_O ]]; then
    OUTPUT1=${VALUE_o}
    OUTPUT2=${VALUE_O}

  elif [[ -z $VALUE_o && -z $VALUE_O ]]; then
    R1=`basename $1`; R2=`basename $2`
    PFX1=$(echo $R1 | sed -e 's/\..*//')
    PFX2=$(echo $R2 | sed -e 's/\..*//')
    OUTPUT1=${PFX1}_sub.fastq.${INSFX}
    OUTPUT2=${PFX2}_sub.fastq.${INSFX}
  else
    :
  fi

elif [[ $# = 1 && -f $1 ]]; then # single-end
  if [[ -n $VALUE_o && -z $VALUE_O && $VALUE_o ]]; then
    OUTPUT1=${VALUE_o}

  elif [[ -z $VALUE_o && -z $VALUE_O ]]; then
    R1=`basename $1`
    PFX1=$(echo $R1 | sed -e 's/\..*//')
    OUTPUT1=${PFX1}_sub.fastq.${INSFX}
  else
    :
  fi
else
  :
fi

# Check var
echo "Sampling number:${VALUE_n}" >&2
echo "Seed number: ${RAND}" >&2
echo "Read1: $1" >&2
echo "Read2: $2" >&2
echo "Suffix of output: ${INSFX}" >&2
echo "Read1 output: ${OUTPUT1}" >&2
echo "Read2 output: ${OUTPUT2}" >&2

### MAIN ###
if [[ $# = 2 ]]; then
  case "${INSFX}" in
    "bz2" )
      paste <(bunzip2 -c $1) <(bunzip2 -c $2) \
      | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
      | shuf -n $VALUE_n --random-source=<(yes ${RAND}) \
      | awk -F"\t" '{print $1"\n"$3"\n"$5"\n"$7 | "bzip2 > '$OUTPUT1'"; \
      print $2"\n"$4"\n"$6"\n"$8 | "bzip2 > '$OUTPUT2'"}'
      ;;

    "gz" )
      paste <(gunzip -c $1) <(gunzip -c $2) \
      | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
      | shuf -n $VALUE_n --random-source=<(yes ${RAND}) \
      | awk -F"\t" '{print $1"\n"$3"\n"$5"\n"$7 | "gzip > '$OUTPUT1'"; \
      print $2"\n"$4"\n"$6"\n"$8 | "gzip > '$OUTPUT2'"}'
      ;;

    "fastq" )
      paste <(cat $1) <(cat $2) \
      | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
      | shuf -n $VALUE_n --random-source=<(yes ${RAND}) \
      | awk -F"\t" -v OUTPUT1=${OUTPUT1} -v OUTPUT2=${OUTPUT2} \
      '{print $1"\n"$3"\n"$5"\n"$7 > OUTPUT1 ; \
      print $2"\n"$4"\n"$6"\n"$8 > OUTPUT2 }'
      ;;

    * ) echo -e "You must select bz2, gz, or uncompressed fastq."
    exit 1 ;;
  esac

elif [[ $# = 1 ]]; then
  case "${INSFX}" in
    "bz2" )
    if [[ "$OUTPUT1" == "-" ]]; then
      bunzip2 -c $1 \
      | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
      | shuf -n $VALUE_n --random-source=<(yes ${RAND})\
      | awk -F"\t" '{print $1"\n"$2"\n"$3"\n"$4 }'

    else
      bunzip2 -c $1 \
      | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
      | shuf -n $VALUE_n --random-source=<(yes ${RAND})\
      | awk -F"\t" '{print $1"\n"$2"\n"$3"\n"$4 }' \
      | bzip2 > $OUTPUT1
    fi
      ;;

    "gz" )
    if [[ "$OUTPUT1" == "-" ]]; then
      gunzip -c $1 \
      | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
      | shuf -n $VALUE_n --random-source=<(yes ${RAND}) \
      | awk -F"\t" '{print $1"\n"$2"\n"$3"\n"$4 }'
    else
      gunzip -c $1 \
      | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
      | shuf -n $VALUE_n --random-source=<(yes ${RAND}) \
      | awk -F"\t" '{print $1"\n"$2"\n"$3"\n"$4 }' \
      | gzip > $OUTPUT1
    fi
      ;;

    "fastq" )
     if [[ "$OUTPUT1" == "-" ]]; then
       cat $1 \
       | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
       | shuf -n $VALUE_n --random-source=<(yes ${RAND}) \
       | awk -F"\t" '{print $1"\n"$2"\n"$3"\n"$4 }'

     else
       cat $1 \
       | awk '{ printf("%s",$0); n++; if(n%4==0) { printf("\n");} else { printf("\t");} }' \
       | shuf -n $VALUE_n --random-source=<(yes ${RAND}) \
       | awk -F"\t" '{print $1"\n"$2"\n"$3"\n"$4 }' > $OUTPUT1
     fi
      ;;

    * ) echo -e "You must select bz2, gz, or uncompressed fastq."
    exit 1 ;;
  esac
else
  :
fi

exit 0
