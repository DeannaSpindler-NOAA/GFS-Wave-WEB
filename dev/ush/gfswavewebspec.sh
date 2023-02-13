#!/bin/ksh
###############################################################################
#                                                                             #
# This script takes the spectral data tar file from the postprocessor and     #
# gets the individual files minus those in the excludelist and puts them in   #
# the web directory.                                                          #
#                                                                             #
# Remarks :                                                                   #
# - The necessary files are retrieved by the mother script.                   #
# - This script generates it own sub-directory 'spec'.                        #
# - See section 0.b for variables that need to be set.                        #
#                                                                             #
#                                                                 July 2007   #
#                                              ported to GFS-Wave July 2021   #
#                                                                             #
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
  ./postmsg "$jlogfile" "Separating spectral files"

  ID=$1
  rm -rf spec_${ID}
  mkdir spec_${ID}
  cd spec_${ID}


# 0.b Define directories and the search path.
#     The tested variables should be exported by the postprocessor script.

  set +x
  echo ' '
  echo '+--------------------------------+'
  echo '! Process spectral files for web |'
  echo '+--------------------------------+'
  echo "   Model ID         : $ID"
  echo "   Spectral file    : $ID.$cycle.spec_tar.gz"
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

  specfile=../$ID.$cycle.spec_tar.gz

# --------------------------------------------------------------------------- #
# 1.  Untar data file

  set +x
  echo ' '
  echo '   Untar data file ...'
  [[ "$LOUD" = YES ]] && set -x

  tar -zxf $specfile
  err=$?

  if [ "$err" != '0' ]
  then
    set +x
    echo ' '
    echo '************************************************* '
    echo "*** FATAL ERROR : ERROR IN UNTARRING $specfile"
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
    echo '   Process exclude list.'
    echo "      No points in exclude list."
    [[ "$LOUD" = YES ]] && set -x
  else
    set +x
    echo '   Process exclude list.'
    [[ "$LOUD" = YES ]] && set -x

    nr_exclude=0
    nr_total=0
    for name in $excludelist
    do
      if [ -f $ID.$name.spec ]
      then
        rm -f $ID.$name.spec
        nr_exclude=`expr $nr_exclude + 1`
      fi
      nr_total=`expr $nr_total + 1`
    done

    set +x
    echo "      Data for $nr_exclude of $nr_total removed."
    [[ "$LOUD" = YES ]] && set -x
  fi

# --------------------------------------------------------------------------- #
# 3.  Compress data if needed

  set +x
  echo '   Compress all data files.'
  [[ "$LOUD" = YES ]] && set -x

# 3.a Compressing the rest 

  for file in `ls $ID.*.spec`
  do
    /bin/gzip $file
    err=$?

    if [ "$err" != '0' ]
    then
      set +x
      echo ' '
      echo '************************************************* '
      echo "*** FATAL ERROR : ERROR IN COMPRESSING $file"
      echo '************************************************* '
      echo ' '
      [[ "$LOUD" = YES ]] && set -x
      exit 3
    fi
  done

# --------------------------------------------------------------------------- #
# 4.  Move data to web directory

  if [ "$SENDWEB" = 'YES' ]
  then
    set +x
    echo '   Move files to web directory ...'
    [[ "$LOUD" = YES ]] && set -x

    for buoy in $buoys
    do
      mv $ID.${buoy}.spec* $WEBOUT/data/.
    done
  fi

# --------------------------------------------------------------------------- #
# 3.  Clean up the directory

  set +x
  echo "   Removing work directory after success."
  [[ "$LOUD" = YES ]] && set -x

  rm -f $specfile
  cd ..
  rm -rf spec_${ID}

  set +x
  echo ' '
  echo "End of gfswavewebspec.sh at"
  date

# End of gfswavewebspec.sh ------------------------------------------------ #
