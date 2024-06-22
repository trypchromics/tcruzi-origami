#!/usr/bin/env bash

# For each chromosome present at first column of the chromSizes file (second argument), we search
# for features at BED file that belongs to this same chromosome. The size of the feature is
# calculated and added to a variable that sums up all the sizes of the features on this chromosome.
# At the end of the looping, this total is divided by the length of the chromosome, in order to
# obtain the percentage of the chromosome that is coveraged by the features at BED file.

BED="${1}"
CHROM_SIZES="${2}"

IFS='
'
for LINE_CHROM in `cat "${CHROM_SIZES}"`
do
   CHROM=`echo ${LINE_CHROM} | cut -f1`
   CHROM_SIZE=`echo ${LINE_CHROM} | cut -f2`
   SUM_FEATURES_SIZES=0
   for LINE_BED in `cat "${BED}"`
   do
      CHROM_BED=`echo ${LINE_BED} | cut -f1`
      if [[ "${CHROM_BED}" == "${CHROM}" ]]
      then
         START=`echo ${LINE_BED} | cut -f2`
         END=`echo ${LINE_BED} | cut -f3`

         # Since BED coordinates are of type 0-based, half-open, the size of a feature can be
         # obtained by just subtracting the end coordinate from the start coordinate.
         let "FEATURE_SIZE = END - START"
         let "SUM_FEATURES_SIZES = SUM_FEATURES_SIZES + FEATURE_SIZE"
      fi
   done

   PERCENTAGE=`echo "${SUM_FEATURES_SIZES} / ${CHROM_SIZE}" | bc -l`
   echo -e "${CHROM}\t${PERCENTAGE}"
done

exit 0
