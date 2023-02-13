#!/bin/ksh
###############################################################################
#                                                                             #
# This script takes the individual time stamp GRIB files combines them into a #
# a single file and then decomposes it into files with single parameters for  #
# later use on the web.                                                       #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - This script generates it own sub-directory 'grib2_$1'.                    #
# - See section 0.b for variables that need to be set.                        #
#                                                                             #
#                                                               August 2009   #
#                                                port to GFS_Wave July 2021   #
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

  ./postmsg "$jlogfile" "Combining grib files for grid $1."

  rm -rf grib2_$1
  mkdir grib2_$1
  cd grib2_$1

# 0.b Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  grdID=$1

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '!     Make GRIB2 files for web   |'
  echo '+--------------------------------+'
  echo "   Model ID         : $RUN"
  echo "   GRID             : $grdID"
  echo "   GRIB file        : $RUN.$cycle.$grdID.f*.grib2"
  echo "   GRIB parameters  : $gribpars"
  [[ "$LOUD" = YES ]] && set -x

  if [ -z "$cycle" ] || [ -z "$utilexec" ] || [ -z "$WEBOUT" ] || \
     [ -z "$SENDWEB" ] || [ -z "$gribpars" ] 
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

  gribfile=$RUN.$grdID.all.grb2

  cat ../$RUN.$cycle.$grdID.f*.grib2 > $gribfile
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '***************************************************'
    echo '*** FATAL ERROR : ERROR IN COMBINING GRIB FILES ***'
    echo '***************************************************'
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 2
  fi
  
# --------------------------------------------------------------------------- #
# 1.  Split up GRIB file
# 1.a Get file with all data

  set +x
  echo ' '
  echo '   Copy file with all data ...'
  [[ "$LOUD" = YES ]] && set -x

  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************* '
    echo "*** FATAL ERROR : ERROR IN COPYING $gribfile"
    echo '************************************************* '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 3
  fi

# 1.b Make grib index file

  set +x
  echo '   Make index file ...'
  [[ "$LOUD" = YES ]] && set -x

  $WGRIB2 $gribfile  > grib.index
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************ '
    echo '*** FATAL ERROR : ERROR IN MAKING INDEX FILE *** '
    echo '************************************************ '
    echo ' '
    [[ "$LOUD" = YES ]] && set -x
    exit 4
  fi

# 1.c Split up file

  set +x
  echo '   Split up GRIB file ...'
  [[ "$LOUD" = YES ]] && set -x

  for par in $gribpars
  do
    grep $par grib.index | \
         $WGRIB2 -i $gribfile -grib $RUN.$grdID.$par.grb2  > /dev/null
    err=$?

    if [ "$err" != '0' ]
    then
      set +x
      echo ' '
      echo '************************************************ '
      echo "*** FATAL ERROR : ERROR IN EXTRACTING $par"
      echo '************************************************ '
      echo ' '
      [[ "$LOUD" = YES ]] && set -x
      exit 5
    fi
  done

  rm -f grib.index

# --------------------------------------------------------------------------- #
# 2.  Move data to web directory

  if [ "$SENDWEB" = 'YES' ]
  then
    set +x
    echo '   Move GRIB files to web directory ...'
    [[ "$LOUD" = YES ]] && set -x

    mv *.grb2 $WEBOUT/data/.
  fi

# --------------------------------------------------------------------------- #
# 3.  Clean up the directory

  set +x
  echo "   Removing work directory after success."
  [[ "$LOUD" = YES ]] && set -x

  rm -f $gribfile
  cd ..
  rm -rf grib2_$grdID

  set +x
  echo ' '
  echo "End of gfswavewebgrib2_comb.sh at"
  date

# End of gfswavewebgrib2_comb.sh ------------------------------------------ #
