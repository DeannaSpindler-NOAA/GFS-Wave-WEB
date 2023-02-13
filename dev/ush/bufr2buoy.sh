#!/bin/sh

##############################################################################
#                                                                            #
# This script is used to extract the buoy data from buffer dumps and store   #
# in daily archive files. It saves the data for present day -1               #
#                                                                            #
##############################################################################
# 0. Preparation
# 0.a Paths should be defined in dev_envir.sh

  #HOMEDIR='/lfs/h2/emc/vpppg/noscrub/deanna.spindler'
  work_dir=/lfs/h2/emc/ptmp/${WAVE_USER}/wavepa/bufr2buoy.$$
  tank=$DCOMROOT/prod

# 0.b Check Time Stamp

  if [ "$#" -lt '1' ]
  then
    echo "usage: bufr2buoy.sh yyyymmdd" 2>&1 ; exit 1
  fi

  ymdh=${1}00
  ymd=${1}

  $NDATE 0 $ymdh > /dev/null 2>&1
  OK=$?

  if [ "$OK" != '0' ]
  then
    echo ' '
    echo " *** $1 not a legal date *** "
    echo ' ' ; exit 2
  fi

# 0.c Header

  echo ' '
  echo '        *** Buoy Data Extraction from DCOM for Waves ***'
  echo '        ------------------------------------------------'
  echo "                             Script : bufr2buoy.sh  " 
  echo "                             Time   : $ymd "
  echo ' '

# 0.d Move to correct directory

  if [ -d $work_dir ]
  then
    cd $work_dir
    rm -f *
  else
    mkdir -p $work_dir
    cd $work_dir
  fi

# 1 Extract data
# 1.a Get Files

  if [ -f "$tank/${ymd}/b001/xx002" ]
  then
    echo ' '
    echo " Copying data from data tank $tank/${ymd}/b001/xx002 "
    echo ' '
    cp $tank/${ymd}/b001/xx002  drifters
  else
    echo ' '
    echo "Data tank not found ! ($tank/${ymd}/b001/xx002) "
    echo ' '
    exit 2
  fi

  if [ -f "$tank/${ymd}/b001/xx003" ]
  then
    echo ' '
    echo " Copying data from data tank $tank/${ymd}/b001/xx003 "
    echo ' '
    cp $tank/${ymd}/b001/xx003  fixbuoys
  else
    echo ' '
    echo "Data tank not found ! ($tank/${ymd}/b001/xx003) "
    echo ' '
    exit 3
  fi

  if [ -f "$FIXwave/fboys.anhts" ]
  then
    echo ' '
    echo " Copying fixed file $FIXwave/fboys.anhts"
    echo ' '
    cp $FIXwave/fboys.anhts fboylst
  else
    echo ' '
    echo "Fixed file not found ! ($FIXwave/fboys.anhts) "
    echo ' '
    exit 4
  fi

  echo $ymdh > scandate

# 1.b Set up links

  export XLFRTEOPTS="unit_vars=yes"
  ln -sf drifters fort.1
  ln -sf fixbuoys fort.2
  ln -sf scandate fort.4
  ln -sf fboylst fort.12
  ln -sf sfcmar.${ymd} fort.9

# 1.c Execute extraction

  $EXECwave/extractbuoy 1> ft06 2> errfile
  OK=$?

  if [ "$OK" != '0' ]
  then
    echo ' '
    echo " *** ERROR RUNNING BUOY EXTRACTION ROUTINE *** "
    echo ' ' ; exit 5
  fi
 
  rm -f tmp_file
  sort sfcmar.${ymd} > tmp_file
  uniq tmp_file >file.${ymd}

  echo ' '
  echo " Moving file.${ymd} to $DATA "
  echo ' '

  mv file.$ymd ${DATA}

# 2 Clean up

  rm -f tmp_file
  rm -f sfcmar.$ymd
  rm -f drifters
  rm -f fixbuoys
  rm -f scandate
  rm -f fboylst
 
  echo ' ' 
  echo 'End of buffr2buoy.sh'  
