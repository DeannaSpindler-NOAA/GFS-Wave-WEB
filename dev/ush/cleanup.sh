#!/bin/bash
###############################################################################
#                                                                             #
# This script cleans up running jobs to assure that the same job will not     #
# be running two times simultaneously.                                        #
#                                                                             #
# Remarks :                                                                   #
# - Checking for jobs with present LL ID too.                                 #
#                                                                             #
# Origination                                                 February 2007   #
# Transition to WCOSS                                         December 2012   #
# Transition to WCOSS2                                        September 2022  #
#                                                                             #
###############################################################################
#
# --------------------------------------------------------------------------- #
# 0.  Preparations
# 0.a Basic modes of operation

  echo ' '
  echo "        Check duplicate job copies :"
  echo "        ------------------------------------------------------------"

# 0.b Get number of present job

  present="`echo ${PBS_JOBID}`"
  echo "present job is $present"

# --------------------------------------------------------------------------- #
# 1.  Loop over jobs

  if [ -z "$PBS_JOBNAME" ] && [ -z "$*" ]
  then
      echo "           Nothing to check."
  else
    for job in $PBS_JOBNAME $*
    do
      #if [ "$job" = "$LOADL_JOB_NAME" ]  ## no idea what this is in PBS
      #then
      #   jobout=$job
      #else
         jobout=`cat ${job}.pbs | grep 'export job=' | sed 's/=/ /g' | awk '{print $3}'`
      #fi
      
      #numbers="`bjobs -u all -w |  grep $jobout | awk '{print $1}'`"
      numbers="`qstat |  grep $jobout | awk '{print $1}'`"
      if [ -z "$numbers" ]
      then
        echo "           No jobs $jobout found."
      else
        for nr in $numbers
        do
          if [ "$nr" = "$present" ]
          then
            echo "           Job $jobout ($nr) is present job."
          else
            #bkill $nr > bkill.$$ 2>&1
            qdel $nr > qdel.$$ 2>&1
            OK=$?
            if [ "$OK" != '0' ]
            then
              cat qdel.$$
            fi
            rm -f qdel.$$
            echo "           Job $jobout ($nr) deleted."
          fi
        done
      fi
    done
  fi

# End of cleanup.sh --------------------------------------------------------- #
