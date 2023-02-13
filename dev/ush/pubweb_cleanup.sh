#!/bin/sh
# ---------------------------------------------------------------------------- #
# polar_cleanup                                                                #
#                                                                              #
# This script is copied from the IBM m/c to polar and remotely run there to    #
# clean up and manage the web and ftp directories on polar. Only up to 6       #
# cycles are kept in polar                                                     #
#                                                                              #
# Origination : 08/10/2007                                                     #
# ---------------------------------------------------------------------------- #
# 0.a Set up directories 

  dir=$1
  mod=$2
  date_file=$3
  clean_old=$4

  cd $dir

# 1.b ID output to screen

  echo ' '
  echo '+----------------------+'
  echo '| Updating remote site |'
  echo '+----------------------+'
  echo "   working directory  : $dir"
  echo "   working model      : $mod"

# ---------------------------------------------------------------------------- #
# 1.  Update link to latest run

  echo ' '
  echo 'Updating latest run link :'
  echo '--------------------------'

  link=`ls -d ${mod}.????????.t??z | tail -1`
  rm -f ${mod}.latest_run
  ln -s $link ${mod}.latest_run
  echo "      ($link)"
  if [ "$date_file" = 'yes' ]
  then
    date=`echo $link | cut -d. -f2`
    cyct=`echo $link | cut -d. -f3`
    year=`echo $date | cut -c1-4`
    month=`echo $date | cut -c5-6`
    day=`echo $date | cut -c7-8`
    date_str="<!--#set var=\"LATEST\" value=\"${year}/${month}/$day `echo $cyct | cut -c2-4`\" -->"
    echo $date_str > ${mod}.dates.shtml
  fi

# ---------------------------------------------------------------------------- #
# 2.  Removing old directories

  echo ' '
  echo 'Removing old directories :'
  echo '--------------------------'

if [ "${mod}" = "glwu" ]
then
  nslice=48
else
  nslice=6
fi

# Find if there are more than nslice files

ls -d ${mod}.????????.t??z > totdir

nft=`wc -l totdir | awk '{print $1}'`

echo 'MOD NSLICE CLENOLD '$mod $nslice $clean_old
#if [ ${nft} -gt ${nslice} ]
#then
#  nslice=`expr ${nft} - ${nslice}`
#fi

if [ ${nslice} -gt 0 ]
then

  ls -d ${mod}.????????.t??z | tail -${nslice} > dirlist

  if [ "$clean_old" = "yes" ]
  then

    nf=`wc -l dirlist | awk '{print $1}'`

    if [ "$nf" = "${nslice}" ]
    then
      for ddir in `ls -d ${mod}.????????.t??z`
      do
        if [ -z "`grep $ddir dirlist`" ]
        then
          echo "      Deleting $ddir"
          rm -rf $ddir
        else
          echo "      Leaving $ddir untouched"
        fi
      done
    fi
  fi

fi

# ---------------------------------------------------------------------------- #
# 3. Adding links to remaining old cycles

  nr=`wc dirlist | awk '{ print $1 }'`
  count=1

  for ddir in `cat dirlist`
  do
    if [ "$count" != "$nr" ]
    then
      ncr=`expr $nr - $count`
      rm -f ${mod}.cycle.${ncr}_back  
      ln -sf $ddir ${mod}.cycle.${ncr}_back  
      if [ "$date_file" = 'yes' ]
      then
        date=`echo $ddir | cut -d. -f2`
        cyct=`echo $ddir | cut -d. -f3`
        year=`echo $date | cut -c1-4`
        month=`echo $date | cut -c5-6`
        day=`echo $date | cut -c7-8`
        date_str="<!--#set var=\"${ncr}_BACK\" value=\"${year}/${month}/$day `echo $cyct | cut -c2-4`\" -->"
        echo $date_str >> ${mod}.dates.shtml
      fi
    fi
    count=`expr $count + 1`
  done

#  rm -f dirlist
# ---------------------------------------------------------------------------- #
# 4.  The end

  echo ' '
  echo 'End of script (polar clean-up)'

# end of polar_cleanup ------------------------------------------------------- #
