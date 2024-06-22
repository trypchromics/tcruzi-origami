#!/usr/bin/env bash

# Error codes.
ERR_MISSING_PARAMETER=1 # At least one parameter should be passed: blast result file.

# Checking command line.
if [[ $# != 2 ]]
then
   echo "Required parameters: switched Blast result file and experiment name."
   echo "Usage: $0 <blastResultFile> <experiment>"
   echo "Example: $0 output/18S-restricted/2-18S-restricted-switchNegativeCoords.tsv 18S-restricted"
   echo "Aborting."
   exit ${ERR_MISSING_PARAMETER}
fi

# Environment variables.
INPUT_FILE="${1}"
EXPERIMENT="${2}"

# source config/${EXPERIMENT}.bash

COVERAGE_COLUMN=9
IDENTITY_COLUMN=8
OUTPUT="output/${EXPERIMENT}/3-${EXPERIMENT}-blastFiltering.tsv"

# Getting a list of all the features (first column).
FEATURES_LIST=`cut -f1 ${INPUT_FILE} | sort -u`

# The input field separator has to be "\n" such that we can parse each line instead of each word.
IFS="
"

# echo "File = ${INPUT_FILE}"
# echo "Coverage = ${COVERAGE}"

for ENTITY_ID in ${FEATURES_LIST}
do
   SELECTED_LINES=`grep -P "^${ENTITY_ID}\t" ${INPUT_FILE}`
   for CURRENT_LINE in ${SELECTED_LINES}
   do
      CURRENT_COVERAGE=`echo ${CURRENT_LINE} | cut -f${COVERAGE_COLUMN}`
      if [[ ${CURRENT_COVERAGE} -ge ${COVERAGE} ]]
      then
         CURRENT_IDENTITY=`echo ${CURRENT_LINE} | cut -f${IDENTITY_COLUMN}`
         if (( `echo "${CURRENT_IDENTITY} >= ${IDENTITY}" | bc -l` ))
         then
            echo ${CURRENT_LINE}
         fi
      fi
   done
done > ${OUTPUT}

Rscript ./script/3-medianFiltering.R \
   output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}-${FEATURE_DIR}-switchNegativeCoords.gff ${OUTPUT} ${MIN_LENGTH_PERCENT} ${EXPERIMENT}

exit 0
