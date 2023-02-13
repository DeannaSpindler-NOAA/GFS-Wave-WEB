#!/bin/ksh
###############################################################################
#                                                                             #
# This script takes the bulletin tar file from the postprocessor and gets the #
# individual files minus those in the excludelist and puts them in the web    #
# directory.                                                                  #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - This script generates it own sub-directory 'bull'.                        #
# - See section 0.b for variables that need to be set.                        #
#                                                                             #
#                                                                 July 2007   #
#                                                port to GFS-Wave July 2021   #
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
  ./postmsg "$jlogfile" "Splitting up the bulletin files"

  ID=$1
  rm -rf bull_${ID}
  mkdir bull_${ID}
  cd bull_${ID}

# 0.b Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '! Process bulletin files for web |'
  echo '+--------------------------------+'
  echo "   Model ID         : $ID"
  echo "   Bulletin file    : $ID.$cycle.bull_tar"
  [[ "$LOUD" = YES ]] && set -x

  if [ -z "$cycle" ] || [ -z "$WEBOUT" ] || [ -z "$SENDWEB" ]
  then
    set +x
    echo ' '
    echo '*******************************************************'
    echo '*** EXPORTED VARIABLES IN WEB postprocessor NOT SET ***'
    echo '*******************************************************'
    echo ' '
    exit 1
    [[ "$LOUD" = YES ]] && set -x
  fi

# 0.c Links to working directory

  bullfile=${DATA}/${ID}.${cycle}.bull_tar

# --------------------------------------------------------------------------- #
# 1.  Untar data file

  set +x
  echo ' '
  echo '   Untar data file ...'
  [[ "$LOUD" = YES ]] && set -x

  tar -xf $bullfile
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************* '
    echo "*** FATAL ERROR : ERROR IN UNTARRING $bullfile"
    echo '************************************************* '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 2
  fi

# --------------------------------------------------------------------------- #
# 2.  Process exclude list

  if [ -z "$excludelist" ]
  then
    set +x
    echo ' '
    echo '   Process exclude list.'
    echo "      No points in exclude list."
    [[ "$LOUD" = YES ]] && set -x
  else
    set +x
    echo ' '
    echo '   Process exclude list.'
    [[ "$LOUD" = YES ]] && set -x

    nr_exclude=0
    nr_total=0
    for name in $excludelist
    do
      if [ -f $ID.$name.bull ]
      then
        rm -f $ID.$name.bull
        nr_exclude=`expr $nr_exclude + 1`
      fi
      nr_total=`expr $nr_total + 1`
    done

    set +x
    echo "      Data for $nr_exclude of $nr_total removed."
    [[ "$LOUD" = YES ]] && set -x
  fi

# --------------------------------------------------------------------------- #
# 3.  Add NOAA/NWS/NCEP MMAB branch stamp to file

  year=`echo $YMDH | cut -c1-4`
  mnth=`echo $YMDH | cut -c5-6`
  day=`echo $YMDH | cut -c7-8`

  job_type="`echo $job | cut -c1-1`"

  case $job_type in
   'p' ) typeID=" (parallel model run)" ;;
   'x' ) typeID=" (experimental model run)" ;;
    *  ) typeID= ;;
  esac

  for buoy in $buoys
  do 
    file=$ID.${buoy}.bull
    echo ' '                                                        >> $file
    echo " NOAA/NWS/NCEP/EMC, $year/$mnth/$day $typeID"             >> $file
  done

# --------------------------------------------------------------------------- #
# 4.  Move data to web directory

  if [ "$SENDWEB" = 'YES' ]
  then
    set +x
    echo '   Move files to web directory ...'
    [[ "$LOUD" = YES ]] && set -x
 
    #for buoy in $buoys
    #do
    #  echo "cp $ID.${buoy}.bull $WEBOUT/data/."
    #  cp $ID.${buoy}.bull $WEBOUT/data/.
    #done
    
    # make sure the bulletins were copied
    cp ${ID}.*.bull ${WEBOUT}/data/.    
    nc=$(ls ${WEBOUT}/data/*bull | wc -l | awk '{print $1}')
    echo "Found ${nc} bulletin files in data directory"
  fi

# --------------------------------------------------------------------------- #
# 3.  Clean up the directory

  set +x
  echo "   Removing work directory after success."
  [[ "$LOUD" = YES ]] && set -x

  rm -f $bullfile
  cd ..
  rm -rf bull_${ID}

  set +x
  echo ' '
  echo "End of gfswavewebbull.sh at"
  date

# End of gfswavewebbull.sh ------------------------------------------------ #
