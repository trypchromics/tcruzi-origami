#!/usr/bin/env bash

ERR_MISSING_PARAMETER=1

INPUT_FILE=${1}
FILE_TYPE=${2}

if [[ "${FILE_TYPE}" == "-g" ]]
then
   START_COL="4"
   END_COL="5"
   LINE_PREFIX_COLS="1-3"
   LINE_SUFFIX_COLS="6-"
elif [[ "${FILE_TYPE}" == "-m" ]]
then
   START_COL="3"
   END_COL="4"
   LINE_PREFIX_COLS="1-2"
   LINE_SUFFIX_COLS="5-"
else
   echo "You should inform the file type: GFF (-g) or multiblast result (-m)."
   echo "Aborting."
   exit ${ERR_MISSING_PARAMETER}
fi

IFS="
"

for LINE in `cat ${INPUT_FILE}`
do
   START=`echo ${LINE} | cut -f${START_COL}`
   END=`echo ${LINE} | cut -f${END_COL}`
   if [[ ${START} -le ${END} ]]
   then
      echo ${LINE}
   else
      LINE_PREFIX=`echo ${LINE} | cut -f${LINE_PREFIX_COLS}`
      LINE_SUFFIX=`echo ${LINE} | cut -f${LINE_SUFFIX_COLS}`
      echo -e "${LINE_PREFIX}\t${END}\t${START}\t${LINE_SUFFIX}"
   fi
done

exit 0 

# awk -v OFS='\t' '{if ($3 <= $4) print $0; else $11 = $3; $3 = $4; $4 = $11; print $0}' ${INPUT_FILE} > ${OUTPUT_FILE}
# awk 'NF==10 {$11 = $2 * $3 / $4; print $0}'
