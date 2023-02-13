#!/bin/bash
###############################################################################
#                                                                             #
# Compiles all codes, moves executables to exec and cleans up                 #
#                                                                             #
#                                                                 Dec, 2019   #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #

# Load modulefile
  module purge
  module use /gpfs/dell2/emc/verification/noscrub/Deanna.Spindler/VPPPG/EMC_waves-prod-gen/WEB/dev/modulefiles
  module load build_multi_1_sorc.module
  module list


# 1. Preparations: seek source codes to be compiled

  fcodes=`ls -d *.fd | sed 's/\.fd//g'` 
  ccodes=`ls -d *.Cd | sed 's/\.Cd//g'` 

  echo " FORTRAN codes found: "$fcodes
  echo " C codes found: "$ccodes

  outfile=`pwd`/make_codes.out
  rm -f ${outfile}

# 2. Create executables

  for code in $fcodes $ccodes
  do
    echo " Making ${code} " >> ${outfile}
    cd ${code}.?d 
    make >> ${outfile}
    echo " Moving ${code} to exec" >> ${outfile}
    mv ${code} ../../exec
    echo " Cleaning up ${code} directory" >> ${outfile}
    make clean
    echo ' ' >> ${outfile}
    cd ..
  done
