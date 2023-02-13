#!/bin/ksh
###############################################################################
#                                                                             #
# This script produces a plot of source terms for a given output point for    #
# any one of the GFS-Wave (WW3) implementations or parallels (Python).        #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - Shell script variables controling time, directories etc. are set in the   #
#   mother script.                                                            #
# - This script runs in the work directory designated in the mother script.   #
#   Under this directory it geneates a work directory plsr_$loc which is      #
#   removed if this script exits normally.                                    #
# - See section 0.c for variables that need to be set.                        #
#                                                                             #
#                                                                July 2007    #
#                            Modify to NetCDF/Python for GFS-Wave Aug 2021    #
###############################################################################
#
# --------------------------------------------------------------------------- #
# 0.  Preparations
# 0.a Basic modes of operation

   PS4=" \${SECONDS} `basename $0` L\${LINENO} + "
  set -x
  LOUD=`echo ${LOUD:-'YES'} | tr [a-z] [A-Z]`    #  default to echo most command statements.
  [[ "$LOUD" != YES ]] && set +x

  cd $DATA

  rm -rf plsr_$1
  mkdir plsr_$1
  cd plsr_$1

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '!     Make source term plot      |'
  echo '+--------------------------------+'
  echo "   Model ID        : $modID"
  [[ "$LOUD" = YES ]] && set -x

# 0.b Check if buoy location set

  if [ "$#" -lt '1' ]
  then
    set +x
    echo ' '
    echo '**************************************************'
    echo '*** LOCATION ID IN gfswavewebncsr.sh NOT SET ***'
    echo '**************************************************'
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 1
  else
    buoy=$1
    grep $buoy ../buoy_log.ww3 > tmp_list.loc
    while read line
    do
      buoy_name=`echo $line | awk '{print $2}'`
      if [ $buoy = $buoy_name ]
      then
        point=`echo $line | awk '{ print $1 }'`
        set +x
        echo "              Location ID/#   : $buoy (${point})"
        echo "   Spectral output start time : $ymdh "
        echo ' '
        [[ "$LOUD" = YES ]] && set -x
        break
      fi
    done < tmp_list.loc
    if [ -z "$point" ]
    then
      set +x
      echo '*********************************************************'
      echo '*** LOCATION ID IN gfswavewebncsr.sh NOT RECOGNIZED ***'
      echo '*********************************************************'
      echo ' '
      [[ "$LOUD" = YES ]] && set -x
      exit 2
    fi
  fi

# 0.c Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  if [ -z "$YMDH" ] || [ -z "$EXECwave" ] || \
     [ -z "$RUN" ] || [ -z "$utilexec" ] 
  then
    set +x
    echo ' '
    echo '*********************************************************'
    echo '*** EXPORTED VARIABLES IN gfswavewebncsr.sh NOT SET ***'
    echo '*********************************************************'
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 3
  fi

# 0.d Starting time for output

  tstart="`echo $YMDH | cut -c1-8` `echo $YMDH | cut -c9-10`0000"
  
  set +x
  echo "   Output starts at $tstart."
  echo ' '
  [[ "$LOUD" = YES ]] && set -x

  filedate="`echo $YMDH | cut -c1-8`"
  filehour="`echo $YMDH | cut -c9-10`0000"
  filetime="$filedate.$filehour"

# 0.e Links to mother directory

  ln -s ../mod_def.$gridbuoy mod_def.ww3
  ln -s ../gfswave.out_pnt.$gridbuoy.$filetime out_pnt.ww3
  ln -s ../spec_ids .

# --------------------------------------------------------------------------- #
# 2.  Run WAVEWATCH GrADS postprocessor
# 2.a Input file for postprocessor

  set +x
  echo "   Generate SOURCE input file for NetCDF point output post-processor."
  echo "   Executing $EXECwave/ww3_ounp"
  [[ "$LOUD" = YES ]] && set -x

  sed -e "s/OUTPUT_TIMES/$tstart 3600 1/g" \
      -e "s/POINT/$point/g" \
	  -e "s/ITYPE/3/g" \
      -e "s/SOURCE_FLAGS/4 0 0 T T T T T T T 0/g" \
                               ../ww3_ounp.inp.tmpl > ww3_ounp.inp

# 2.b Run the postprocessor

  $EXECwave/ww3_ounp
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************************ '
    echo '*** FATAL ERROR : ERROR IN NetCDF SOURCE post-processing *** '
    echo '************************************************************ '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 4
  fi

  if [ ! -f ww3.${filedate}_src.nc ]
  then
    set +x
    echo ' '
    echo '********************************************************** '
    echo '*** FATAL ERROR : ww3_ounp source OUTPUT FILES MISSING *** '
    echo '********************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 5
  fi

  mv ww3.${filedate}_src.nc ww3_src.nc
  rm -f mod_def.ww3
  rm -f out_pnt.ww3
  rm -f ww3_ounp.inp

# --------------------------------------------------------------------------- #
# 3.  Run Python

  set +x
  echo "   Run Python to create the source term plots"
  [[ "$LOUD" = YES ]] && set -x
  
  # On WCOSS1:
  #export PYTHONPATH=/usrx/local/prod/packages/python/3.6.3/lib/python3.6/site-packages/:$PYTHONPATH
  python $FIXwave/ww3_source_nc.py

  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************* '
    echo '*** FATAL ERROR : ERROR IN Python source plot *** '
    echo '************************************************* '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 6
  fi

  if [ ! -f ${RUN}.${buoy}.source.png ]
  then
    set +x
    echo ' '
    echo '******************************************************* '
    echo '*** FATAL ERROR : ${RUN}.${buoy}.source.png MISSING *** '
    echo '******************************************************* '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 7
  fi

# --------------------------------------------------------------------------- #
# 4.  Post results to web directory and clean up
# images are tarred and moved to $WEBOUT/plots from exwave_gfs_web.sh.ecf

  if [ "$SENDWEB" = 'YES' ]
  then
    set $setoff
    echo '   Move files to web directory ...'
    set $seton
	mv $RUN.*.source.png $DATA/.
	mv ww3_src.nc $DATA/ww3.${buoy}_src.nc
  fi

# 4.b Clean up the rest

  cd ..
  rm -rf plsr_$buoy

  set +x
  echo ' '
  echo 'End of gfswavewebncsr.sh at'
  date

# End of gfswavewebncsr.sh ------------------------------------------------ #
