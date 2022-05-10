#!/bin/bash
VERSION=0.0.1
AUTHOR=SHOGO_KONISHI
CMDNAME=`basename $0`

# print help document of this script
function print_doc() {
cat << EOS
Usage:
    $CMDNAME [options] <fastq_directory>

Description:
    This script creates a manifest file as CSV for data import in qiime2.

Options:
  -h  print this document
  -s  single end
  -p  paired-end
  -o  output filename [default: manifest.csv]

Examples:
    $CMDNAME -s -o q2dat.csv fqdir    [single-end]
    $CMDNAME -p -o q2dat.csv fqdir    [paired-end]
EOS
}

# Argument check 01: オプションの処理
while getopts spo:h OPT
do
  case $OPT in
    "s" ) FLG_s="TRUE" ;;
    "p" ) FLG_p="TRUE" ;;
    "o" ) VALUE_o="$OPTARG" ;;
    "h" ) print_doc
            exit 1 ;;
     \? ) print_doc
            exit 1 ;;
  esac
done
shift `expr $OPTIND - 1`

# Argument check 02: オプションのデフォルト値 (出力ファイル名)
if [[ -n $VALUE_o ]]; then
  OUTPUT=${VALUE_o}
else
  OUTPUT='manifest.csv'
fi

# Argument check 03: オプション無引数の処理
if [[ $# = 1 && -d $1 ]]; then
    :
else
    echo "Your input directory don't exists."
    exit 1
fi
echo $OUTPUT

### MAIN ###
# fastqディレクトリのパスを取得
FQD=`basename $1`
CPFQD=$(pwd $FQD)/$FQD

# header line
echo sample-id","absolute-filepath","direction > $OUTPUT

# Write down the complete path and read direction of the fastq files contained in the directory
if [[ ${FLG_s} == "TRUE" && ${FLG_p} == "TRUE" ]]; then
  echo "Either the -p or -o option must be selected."

elif [[ ${FLG_s} == "TRUE" && ${FLG_p} != "TRUE" ]]; then # single end
  # collect fastq files
  FQS=`ls $CPFQD | grep -e ".fastq$" -e ".fastq.gz$" -e ".fq$" -e ".fq.gz$"`

  for r1 in ${FQS[@]}; do
    ID=`echo $r1 | cut -f 1 -d "_"`
    cpfq_r1=${CPFQD}/${r1}
    echo -e ${ID}","${cpfq_r1}","forward >> $OUTPUT
  done

elif [[ ${FLG_s} != "TRUE" && ${FLG_p} == "TRUE" ]]; then # paired-end
  # collect Read1 files
  FQS=(`ls $CPFQD | grep -e "_R1" -e "_1" `)

  for r1 in ${FQS[@]}; do
    r2=`echo $r1 | sed -e 's/_R1/_R2/' -e 's/_1\./_2\./' `
    ID=`echo $r1 | cut -f 1 -d "_"`
    cpfq_r1=${CPFQD}/${r1}
    cpfq_r2=${CPFQD}/${r2}
    echo -e ${ID}","${cpfq_r1}","forward >> $OUTPUT
    echo -e ${ID}","${cpfq_r2}","reverse >> $OUTPUT
  done
else
    print_doc
    exit 1
fi
