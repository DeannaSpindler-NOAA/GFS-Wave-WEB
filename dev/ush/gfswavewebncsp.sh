#!/bin/ksh -l
###############################################################################
#                                                                             #
# This script makes a six panel spectral plot for a given output point for    #
# the GFS-Wave WAVEWATCH (WW3) implementation or parallels (Python).          #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - Shell script variables controling time, directories etc. are set in the   #
#   mother script.                                                            #
# - This script runs in the work directory designated in the mother script.   #
#   Under this directory it geneates a work directory plsp_$loc which is      #
#   removed if this script exits normally.                                    #
# - See section 0.c for variables that need to be set.                        #
#                                                                             #
#                                                             July 2007       #
#                                ported to GFS-Wave and Python Aug 2021       #
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

  rm -rf plsp_$1
  mkdir plsp_$1
  cd plsp_$1

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '!       Make spectral plot       |'
  echo '+--------------------------------+'
  echo "   Model ID        : $RUN"
  [[ "$LOUD" = YES ]] && set -x

# 0.b Check if buoy location set

  if [ "$#" -lt '1' ]
  then
    set +x
    echo ' '
    echo '**************************************************'
    echo '*** LOCATION ID IN gfswavewebncsp.sh NOT SET ***'
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
    [[ "$LOUD" = YES ]] && set -x
    if [ -z "$point" ]
    then
      set +x
      echo '*********************************************************'
      echo '*** LOCATION ID IN gfswavewebncsp.sh NOT RECOGNIZED ***'
      echo '*********************************************************'
      echo ' '
      [[ "$LOUD" = YES ]] && set -x
      exit 2
    fi
  fi

# 0.c Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  if [ -z "$YMDH" ] || [ -z "$dtplsp" ] || [ -z "$EXECwave" ] || \
     [ -z "$RUN" ] || [ -z "$utilexec" ] || [ -z "$toffplsp" ] 
  then
    set +x
    echo ' '
    echo '*********************************************************'
    echo '*** EXPORTED VARIABLES IN gfswavewebncsp.sh NOT SET ***'
    echo '*********************************************************'
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 3
  fi

# 0.d Starting time for output

  ymdh=`$NDATE $toffplsp $YMDH`
  tstart="`echo $ymdh | cut -c1-8` `echo $ymdh | cut -c9-10`0000"
  the_day="`echo $ymdh | cut -c1-8`"
  tend=`$NDATE +120 $ymdh`    ### 24 x 5
  end_day="`echo $tend | cut -c1-8`"
  tint="`echo $ymdh | cut -c9-10`0000"

  set +x
  echo "   Output starts at $tstart."
  echo "   Output interval ${dtplsp}s."
  echo "   Output ends at ${end_day}."
  echo ' '
  [[ "$LOUD" = YES ]] && set -x

# 0.e Links to mother directory

  ln -s ../mod_def.$gridbuoy mod_def.ww3 
  ln -s ../spec_ids .
  
# --------------------------------------------------------------------------- #
# 2.  Run WAVEWATCH NetCDF postprocessor
# 2.a Input file for postprocessor

  set +x
  echo "   Generate SPECTRAL input file for NetCDF point output post-processor"
  echo "   Executing $EXECwave/ww3_ounp"
  [[ "$LOUD" = YES ]] && set -x

# for each hourly raw file, 24 hrs from cycle
  numfile=0
  while (( ${the_day} <= ${end_day} )); do
    rawfile="${RUN}.out_pnt.${gridbuoy}.${the_day}.${cyc}0000"
    ln -s ../${rawfile} out_pnt.ww3
  
# 2.b Run the postprocessor
    sed -e "s/OUTPUT_TIMES/${the_day} $tint $dtplsp 1/g" \
        -e "s/POINT/$point/g" \
	    -e "s/ITYPE/1/g" \
        -e "s/SOURCE_FLAGS/3 0. 0. 33 F/g" \
                               ../ww3_ounp.inp.tmpl > ww3_ounp.inp

    $EXECwave/ww3_ounp
	err=$?
	
	if [ "$err" != '0' ]
	then
      set +x
	  echo ' '
	  echo '************************************************************* '
	  echo '*** FATAL ERROR : ERROR IN NetCDF SPECTRA post-processing *** '
	  echo '************************************************************* '
	  echo ' '
	  [[ "$LOUD" = YES ]] && set -x
	  exit 4
	fi
	
	if [ ! -f ww3.${the_day}_spec.nc ] 
	then
      set +x
	  echo ' '
	  echo '**************************************************************** '
	  echo '*** FATAL ERROR : ww3_ounp spectra OUTPUT FILES MISSING      *** '
	  echo '**************************************************************** '
	  echo ' '
	  [[ "$LOUD" = YES ]] && set -x
	  exit 5
	fi
	
	the_day=$(date --date="${the_day} + 1 day" '+%Y%m%d')
    rm -f out_pnt.ww3
	rm -f ww3_ounp.inp
	
  done
  rm -f mod_def.ww3
  
  ncrcat -h ww3.*_spec.nc out_pnt.nc
  
  if [ ! -f out_pnt.nc ] 
  then
    set +x
	echo ' '
	echo '************************************************************ '
	echo '*** FATAL ERROR : out_pnt.nc MISSING before spectra plot *** '
	echo '************************************************************ '
	echo ' '
	[[ "$LOUD" = YES ]] && set -x
	exit 5
  fi

# --------------------------------------------------------------------------- #
# 3.  Run Python

  set +x
  echo "   Run Python to create the spectral plots"
  [[ "$LOUD" = YES ]] && set -x
 
  echo `which python`
  echo "PYTHONPATH is $PYTHONPATH"
  # On WCOSS1:
  #export PYTHONPATH=/usrx/local/prod/packages/python/3.6.3/lib/python3.6/site-packages/:$PYTHONPATH
  #echo " NEW PYTHONPATH is $PYTHONPATH"

  python $FIXwave/ww3_spectra_nc.py
  #python -c 'import xarray' 
  
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************** '
    echo '*** FATAL ERROR : ERROR IN Python spectra plot *** '
    echo '************************************************** '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 6
  fi

  if [ ! -f $RUN.$buoy.spec.png ]
  then
    set +x
    echo ' '
    echo '************************************************* '
    echo '*** FATAL ERROR : $RUN.$buoy.spec.png MISSING *** '
    echo '************************************************* '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 7
  fi

# --------------------------------------------------------------------------- #
# 4.  Move results up one directory
# images are tarred and moved to $WEBOUT/plots from exwave_gfs_web.sh.ecf

  if [ "$SENDWEB" = 'YES' ]
  then
    set $setoff
    echo '   Move files to web directory ...'
    set $seton
#    mv $RUN.*.spec.png $WEBOUT/plots/.
    mv $RUN.*.spec.png $DATA/.
	mv out_pnt.nc $DATA/ww3.${buoy}_spec.nc
  fi

# 4.b Clean up the rest

  cd ..
  rm -rf plsp_$buoy

  set +x
  echo ' '
  echo 'End of gfswavewebncsp.sh at'
  date

# End of gfswavewebncsp.sh ------------------------------------------------- #
