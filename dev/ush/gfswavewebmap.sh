#!/bin/ksh
###############################################################################
#                                                                             #
# This script makes a map plot based on a given view for                      #
# the Multi-Grid WAVEWATCH (MWW3) implementation or parallels (Python).       #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - Shell script variables controlling view, necessary grids etc. are set     #
#   in the mother script.                                                     #
# - This script runs in the work directory designated in the mother script.   #
#   Under this directory it geneates a work directory map_$view_$time_start   #
#   which is removed if this script exits normally.                           #
# - See section 0.c for variables that need to be set.                        #
#                                                                             #
#                                                             July 2007       #
#                                Modified to use NetCDF/Python Aug 2021       #
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

  rm -rf map_$1_$2_$3
  mkdir map_$1_$2_$3
  cd map_$1_$2_$3
  
  runtime=$1
  fcsthr=$2
  region=$3
  
  set +x
  echo ' '
  echo '+---------------------------+'
  echo '!       Make map plot       |'
  echo '+---------------------------+'
  echo "   Model ID           : $RUN"
  echo "   Run time           : $1"
  echo "   Cycle              : $cyc"  
  echo "   Forecast hour      : $2"
  echo "   View               : $3"
  echo ' '
  [[ "$LOUD" = YES ]] && set -x

  if [ "$#" -lt '3' ]
  then
    set +x
	echo ' '
	echo '*********************************************'
	echo '*** variables IN gfswavewebmap.sh NOT SET ***'
	echo '*********************************************'
	echo ' '
	[[ "$LOUD" = YES ]] && set -x
	exit 1
  fi

# 0.b Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  if [ -z "$RUN" ] || [ -z "$cycle" ] || [ -z "$FIXwave" ] 
  then
    set +x
    echo ' '
    echo '********************************************************'
    echo '*** EXPORTED VARIABLES IN gfswavewebmap.sh NOT SET ***'
    echo '********************************************************'
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 3
  fi

# 0.c Link up necessary files 

  for grdID in $grids
  do
    ln -sf ../${RUN}.${cycle}.${grdID}.f${fcsthr}.nc .
  done

  ln -sf ../wave_gfs.buoys.full .
  
  if [[ "$region" = 'arctic' ]] || [[ "$region" = 'antarctic' ]]
  then
    echo "no buoy_loc files for $region"
  else
    ln -sf ../buoys.${region} .
  fi

# --------------------------------------------------------------------------- #
# Run Python

  set +x
  echo "   Run Python to create the maps of the fields"
  [[ "$LOUD" = YES ]] && set -x
  
  # On WCOSS1:
  #export PYTHONPATH=/usrx/local/prod/packages/python/3.6.3/lib/python3.6/site-packages/:$PYTHONPATH
  
  python $FIXwave/ww3_graphics.py $runtime $cyc $fcsthr $region
  
  err=$?
  
  if [ "$err" != '0' ]
  then
    set +x
	echo ' '
	echo '****************************************** '
	echo '*** FATAL ERROR : ERROR IN Python maps *** '
	echo '****************************************** '
	echo ' '
	[[ "$LOUD" = YES ]] && set -x
	exit 6
  else
    echo '*********************************************************** '
    echo " Python finished cleanly for $runtime $cyc $fcsthr $region"
    echo '*********************************************************** '
  fi
    
  nr_png=`ls plots/*.png | wc -l | awk '{ print $1}'`

  if [ "$nr_png" = '0' ]
  then
    set $setoff
    echo ' '
    echo '****************************************************************** '
    echo '*** FATAL ERROR : ERROR IN Python maps (png files not created) *** '
    echo '****************************************************************** '
    echo ' '
    set $seton
    exit 6
  fi 

# --------------------------------------------------------------------------- #
# 4.  Move images to parent directory

  if [ "$SENDWEB" = 'YES' ]
  then
    set $setoff
    echo '   Move files to $DATA for tarring ...'
    set $seton
#	cp buoy_locs/* $WEBOUT/buoy_locs/.
    cp plots/*.png $DATA/.
    if [[ "$region" = 'arctic' ]] || [[ "$region" = 'antarctic' ]]
    then
      echo "no buoy_loc files for $region"
    else
	  cp buoy_locs/* $DATA/.
    fi
  fi
  
# 4.b Clean up the rest

  cd ..
  rm -rf map_$1_$2_$3

  set +x
  echo ' '
  echo 'End of gfswavewebmap.sh at'
  date

# End of gfswavewebmap.sh ------------------------------------------------- #
