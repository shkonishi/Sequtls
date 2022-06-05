#!/bin/bash
# Common functions 1: checkFqfmt
function checkFqfmt () {
  # echo compressed format
  if file $1 | grep -q "gzip" ; then
    echo "gz"
  elif file $1 | grep -q "bzip2" ; then
    echo "bz2"
  elif file $1 | grep -q "ASCII" ; then
    echo "fastq"
  else
    echo "The input file must be a gz or bz2 compressed fastq file or uncompressed fastq format. "
    return 1
  fi
}

# Common functions 2: stdFqfmt
function stdFqfmt () {
  if file $1 | grep -q "gzip" ; then
    gunzip -c $1
  elif file $1 | grep -q "bzip2" ; then
    bunzip2 -c $1
  elif file $1 | grep -q "ASCII" ; then
    cat $1
  else
    echo "The input file must be a gz or bz2 compressed fastq file or uncompressed fastq format. "
    return 1
  fi
}

# faTab
function faTab () {
  awk 'BEGIN{RS=">"; FS="\n"} NR>1 {print $1"\t"$2;}' $1
}

# faFormat
function faFormat () {
  awk '/^>/ { print n $0; n = "" }!/^>/ { printf "%s", $0; n = "\n" } END{ printf "%s", n }' $1
}

# fqFa: fastq to fasta
function fqFa () {
  cat $1 | awk '(NR - 1) % 4 < 2' | sed 's/@/>/'
}

# fqLen : fastq length
function fqLen () {
  awk 'NR % 4 == 2 { print length($0) }'
}

# fqTab : fastq to tab
function fqTab () {
  awk '{printf("%s",$0); n++; if(n%4==0) { printf("\n");} else if(n%4==2){printf("\t"$0"\t");} else { printf("\t");} }' $1
}
