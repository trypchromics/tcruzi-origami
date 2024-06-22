#!/usr/bin/env bash

# Script: 0-findBestMatch.bash
# 
# Description: this is the main script (driver) that calls all the other ones with the object of
# finding the best matches (using blastn) between a set of FASTA files and the index of a given
# genome. By best match we mean a result of blastn whose coverage and identity are above a
# predetermined threshold and that is not contained by any other result (here called superset).

# Error code used when the script is improperly called. It should be called with just one argument.
ERR_MISSING_ARG=1

# The only parameter that must be passed to the script is the name of the experiment. This name is
# used to load configuration parameters, find the input files and write the output files at specific
# directories.
if [[ "$#" != "1" ]]
then
   echo "You should pass the name of the experiment."
   echo "Usage: $0 <EXPERIMENT>"
   echo "Example: $0 18S-restricted"
   echo "Aborting."
   exit ${ERR_MISSING_ARG}
fi

# At this point we know that the script was executed with exactly one argument, so we can use $1.
export EXPERIMENT=${1}

# Load all the environment variables that define this experiment.
source config/${EXPERIMENT}.bash
export GENOME_FASTA
export BLAST_DB
export GFF_FILE
export FEATURE
export FEATURE_DIR
export GFF_FEATURE
export PERCENT
export COVERAGE
export IDENTITY
export FASTAS_DIR
export MIN_LENGTH_PERCENT

# Set up initial directories structure.
mkdir -p {input,log,output}/${EXPERIMENT}

# Make symbolic links for input data.
ln -fs ${GENOME_FASTA} input
ln -fs ${GFF_FILE} input

# Get the name of the file.
export GFF_FILENAME=`basename ${GFF_FILE}`

FEATURE_FS="${FEATURE_DIR}"
# Select only the GFF lines of interest.
cat "input/${GFF_FILENAME}" | ./script/selectGffLines.bash "${GFF_FILE}" "${GFF_FEATURE}" \
   "${FEATURE}" "${FEATURE_FS}" "${EXPERIMENT}" > \
   "output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}-${FEATURE_FS}.gff"

#   ./script/getFastaForBlast.bash input/`basename ${GENOME_FASTA}` \
#      output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}-${FEATURE}.gff \
#      > output/${EXPERIMENT}/${GFF_FILENAME%.gff}-${GFF_FEATURE}-${FEATURE_DIR}.fasta

# Run blastn for each FASTA file at experiment input directory.
/usr/bin/nice -n 19 /usr/bin/time --verbose --output=log/${EXPERIMENT}/1-multiBlast.time saveCommand \
   ./script/1-multiBlast.bash ${PERCENT} ${BLAST_DB} ${FEATURE} ${EXPERIMENT} 2> \
   log/${EXPERIMENT}/1-multiBlast.err > log/${EXPERIMENT}/1-multiBlast.out

# Concatenate all blastn output files.
cat output/${EXPERIMENT}/blastn/*.tsv > output/${EXPERIMENT}/1-${EXPERIMENT}-multiBlast.tsv

# Switch chromStart with chromEnd in the case they are at negative strand. This is necessary in
# order to compare coordinates between entities to verify if it is contained by other entity.
/usr/bin/nice -n 19 /usr/bin/time --verbose --output=log/${EXPERIMENT}/2-switchNegativeCoords.time \
   saveCommand \
   ./script/2-switchNegativeCoords.bash output/${EXPERIMENT}/1-${EXPERIMENT}-multiBlast.tsv -m > \
   output/${EXPERIMENT}/2-${EXPERIMENT}-switchNegativeCoords.tsv

# GFF filtering.
# Get the name of the file.
export GFF_FILENAME=`basename ${GFF_FILE}`

# Remove lines with comments at the beggining.
grep -v '^#' input/${GFF_FILENAME} > output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments.gff

# Get only the lines that has GFF_FEATURE at third column.
grep -P ".*\t.*\t${GFF_FEATURE}\t.*\t.*\t.*\t.*\t.*\t.*" output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments.gff > output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}.gff

# Get only the lines that has FEATURE at ninth column.
grep -P ".*\t.*\t.*\t.*\t.*\t.*\t.*\t.*\t.*${FEATURE}.*" \
   output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}.gff \
   > output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}-${FEATURE_DIR}.gff

# Switch eventual negative coordinates at GFF file.
./script/2-switchNegativeCoords.bash \
   output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}-${FEATURE_DIR}.gff -g \
   > output/${EXPERIMENT}/${GFF_FILENAME%.gff}-withoutComments-${GFF_FEATURE}-${FEATURE_DIR}-switchNegativeCoords.gff

./script/3-blastFiltering.bash output/${EXPERIMENT}/2-${EXPERIMENT}-switchNegativeCoords.tsv ${EXPERIMENT} > output/${EXPERIMENT}/3-${EXPERIMENT}-blastFiltering.tsv

./script/4-selectSupersets.bash output/${EXPERIMENT}/3-${EXPERIMENT}-blastFiltering.tsv > output/${EXPERIMENT}/4-${EXPERIMENT}-selectSuperSets.tsv

cut -f2-4 output/${EXPERIMENT}/4-${EXPERIMENT}-selectSuperSets.tsv > output/${EXPERIMENT}/4-${EXPERIMENT}-selectSuperSets.bed3

# Remove intermediate files.
# rm output/{0,1,2}-${EXPERIMENT}* 

exit 0
