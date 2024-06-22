#!/usr/bin/env bash

# This script receives a BLAST output file as input and returns a filtered file to standard output.
# The only prerequisites are for the contents of columns 2, 3 and 4, which should contain:
#    column 2: chromosome name
#    column 3: feature start
#    column 4: feature end
# The purpose of the filtering is to eliminate the blocks defined by each line that are "included"
# at other "bigger" blocks. Making an analogy with math sets, the script outputs only the supersets.
#
# Since some lines at BLAST output contain a chromStart greater than chromEnd, the algorithm below
# switches these two values in order to facilitate the determination of intersection.

# TODO: Test if this script works for a general BED file (not only for BED3 files), since the
# pre-requisite to be a BED file is just related with the contents of the first three columns.

# Error codes.
ERR_WRONG_NUMBER_OF_PARAMETERS=1 # At least one parameter should be passed: BED3 file.

#if there is no ${2} parameter, the file will be sived directly in the OUTPUT directory.

# Checking command line parameters.
if [[ $# != 1 ]]
then
   echo "Required parameter: BLAST output file with, at least chromosome name (at column 2),"
   echo "feature start (at column 3), feature end (at column 4)."
   echo "Usage: $0 <BLAST_OutputFile>"
   echo "Example: $0 input/genes.tsv"
   echo "Aborting."
   exit ${ERR_WRONG_NUMBER_OF_PARAMETERS}
fi

# Input parameter.
INPUT_FILE="${1}"
FILENAME=`basename ${INPUT_FILE} | rev | cut -d. -f2- | rev`
EXTENSION=`echo ${INPUT_FILE} | rev | cut -d. -f1 | rev`

# This function assigns the corresponding values related with block A or B (depending of the
# parameter): chromosome, start and end.
function readBlock {
   BLOCK=${1}

   if [ "${BLOCK}" == "A" ]
   then
      CHROM_A=`echo ${BLOCK_A} | cut -f2`
      START_A=`echo ${BLOCK_A} | cut -f3`
      END_A=`echo ${BLOCK_A} | cut -f4`
   else
      if [ "${BLOCK}" == "B" ]
      then
         CHROM_B=`echo ${BLOCK_B} | cut -f2`
         START_B=`echo ${BLOCK_B} | cut -f3`
         END_B=`echo ${BLOCK_B} | cut -f4`
      fi
   fi
}

# This function should be used every time there is no doubt that block B is a next promising block.
function blockBIsANextPromisingBlock {
   echo "${BLOCK_B}" >> ${NEXT_PROMISING_BLOCKS}
}

# The core of the algorithm consists of comparing the first line of the input BED3 file
# (BLOCK_A) with all remaining lines (TAIL), eliminating those blocks that are contained by other
# blocks. The file PROMISING_BLOCKS has all the blocks that still have to be analised. At each
# "while" loop, we write the contents of the NEXT_PROMISING_BLOCKS file, with all the blocks that
# are not contained by BLOCK_A.
#PREVIOUS=PROMISING_BLOCKS="output/promisingBlocks.tsv"
PROMISING_BLOCKS="output/${EXPERIMENT}/promisingBlocks.tsv"
#PREVIOUS = NEXT_PROMISING_BLOCKS="output/nextPromisingBlocks.tsv"
NEXT_PROMISING_BLOCKS="output/${EXPERIMENT}/nextPromisingBlocks.tsv"

# Setting up initial directories structure.
mkdir -p final log output

# Remove the file that contains excluded blocks from previous run.
#rm -f output/excludedBlocks.tsv

# Initially, all the blocks at OUTPUT_SWITCH_COORDS_FILE compose our first promising blocks set and
# the file NEXT_PROMISING_BLOCKS is empty.
cp ${INPUT_FILE} ${PROMISING_BLOCKS}
echo -n "" > ${NEXT_PROMISING_BLOCKS}

# TODO: We can shorten the processing time of this script if we sort the first column of input file.

# The input field separator has to be '\n' such that we can parse each line instead of each word.
IFS="
"

# At each "while" loop we do four things:
#    1. Eliminate each block that is contained by BLOCK_A, until it is found a block that contains
#       BLOCK_A.
#    2. Eliminate BLOCK_A if it is contained by any block in TAIL.
#    3. Print the next promising blocks to the corresponding file.
#    4. Print final blocks to the output.
while [ `wc -l "${PROMISING_BLOCKS}" | cut -d' ' -f1` -ge 2 ]
do
   # In principle, block A is a superset candidate block, to be printed at the final set.
   BLOCK_A_IS_SUPERSET="true"

   # The contents of BLOCK_A is always the first line of PROMISING_BLOCKS.
   BLOCK_A=`head -1 ${PROMISING_BLOCKS}`

   # BLOCK_B starts with the contents of the second line of PROMISING_BLOCKS and is assigned the
   # values of the next lines (stored at TAIL), one by one, at the for looping below.
   BLOCK_B_LINE=2
   TAIL=`tail -n +2 ${PROMISING_BLOCKS}`

   readBlock A

   for BLOCK_B in ${TAIL}
   do
      readBlock B

      # Are the blocks at the same chromosome?
      if [ "${CHROM_A}" == "${CHROM_B}" ]
      then
         # Does block A contain block B?
         if [[ "${START_A}" -le "${START_B}" && "${END_A}" -ge "${END_B}" ]]
         then
            # Forget about block B: it is contained by block A. Let's move to the next one.
            let "BLOCK_B_LINE = BLOCK_B_LINE + 1"

            echo "${BLOCK_B}" >> output/${EXPERIMENT}/${FILENAME}-excludedBlocks.tsv

            continue
         fi
         
         # Does block B contain block A?
         if [[ ${START_A} -ge ${START_B} && ${END_A} -le ${END_B} ]]
         then
            # Forget about block A: it is contained by block B.
            BLOCK_A_IS_SUPERSET="false"
           
            # At this point, block B and all the remained ones are next promising blocks.
            tail -n +${BLOCK_B_LINE} ${PROMISING_BLOCKS} >> ${NEXT_PROMISING_BLOCKS}

            echo "${BLOCK_A}" >> output/${EXPERIMENT}/${FILENAME}-excludedBlocks.tsv

            # We have finished with block A.
            break
         fi

         #Neither BlockA contains block B nor Block B contains Block A:
         blockBIsANextPromisingBlock
      else
         # TODO: if PROMISING_BLOCKS is sorted by first column, maybe we can conclude that block A
         # is a superset, since there is no other block that belongs to the same chromosome. Think
         # better about this idea later.
         blockBIsANextPromisingBlock
      fi

      # We have finished with block B. Let's analyse the next one.
      let "BLOCK_B_LINE = BLOCK_B_LINE + 1"
   done

   # If we reached this point because of the break command, we do not have to print block A.
   if [ "${BLOCK_A_IS_SUPERSET}" == "true" ]
   then
      echo "${BLOCK_A}"
   fi

   # Let's process the next promising blocks file.
   cp ${NEXT_PROMISING_BLOCKS} ${PROMISING_BLOCKS}
   echo -n "" > ${NEXT_PROMISING_BLOCKS}
done

# Print the last block.
cat ${PROMISING_BLOCKS}

# Remove temporary files.
rm ${PROMISING_BLOCKS} ${NEXT_PROMISING_BLOCKS}

exit 0
