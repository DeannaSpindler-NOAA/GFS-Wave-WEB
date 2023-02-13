#!/bin/bash

#export jobid=${job}.$$

# number of files for cfp command:
export nfile=512

export SENDCOM=YES
export SENDWEB=YES

export SYSVER='gfs.v16.3.3'
export WAVE_USER='deanna.spindler'
export HOMEDIR="/lfs/h2/emc/vpppg/noscrub/${WAVE_USER}"
export LSFWAVE="${HOMEDIR}/VPPPG/EMC_waves-prod-gen/WEB/lsf_scripts/wave_${SYSVER}"

if [ -f ${LSFWAVE}/PDY_gfswave ]
then
  . ${LSFWAVE}/PDY_gfswave
else
  echo '###############################################################'
  echo '### ERROR in dev_envir !! : COULD NOT SET THE PDY AND CYCLE ###'
  echo '###############################################################'
  exit 1
fi

# Set Version numbers
export PRODVER=v16.3
#export MODEL_VER=v16.2.2
export MODEL_VER=v16.3.3
export WAVE_CODE_VER=v7.0
export WAVE_CODE_PKG=st4nc

# Set variables
export PCODE='GFS-DEV'
export MODID='gfs'
export NET='wave'
export RUN='gfswave'
export ICEID='icean_5m'  # was iceID
export WINDID='gfs_30m'  # was wndID
export ENVIR='dev'  # was also RUN_ENVIR in JWAVE_GFS_WEB.lsf

export HOMEwave="${HOMEDIR}/VPPPG/EMC_waves-prod-gen/WEB/dev/wave_${SYSVER}"
export EXECwave="${HOMEwave}/exec"
export FIXwave="${HOMEwave}/fix"
export PARMwave="${HOMEwave}/parm"
export USHwave="${HOMEwave}/ush"
#export AUXwave="${HOMEDIR}/wavepa/save/aux/buoy_qc/fix"
export SMSBIN="${HOMEDIR}/VPPPG/EMC_waves-prod-gen/WEB/sms_fake"

export PRODUTIL="${UTILROOT}"
export HOMEcode="${PACKAGEROOT}/${SYSVER}"
export EXECcode="${PACKAGEROOT}/${SYSVER}/exec"
export FIXcode="${PACKAGEROOT}/${SYSVER}/fix/fix_wave_gfs"
export UTILEXEC="${UTILROOT}/exec"

export COMIN="${COMROOT}/gfs/${PRODVER}"
export COMOUT="${HOMEDIR}/wavepa/GFS_WEB/COM"
export WEB="${HOMEDIR}/wavepa/GFS_WEB/WEB"
export OUT="${HOMEDIR}/wavepa/GFS_WEB/OUTPUT"
export DATAROOT="/lfs/h2/emc/ptmp/${WAVE_USER}/GFS_WEB"
export batchloc="${DATAROOT}/batchscripts"

#export jlogfile=/dev/null
export JLOGFILE=${COMOUT}/wave_jlogfile  ## cron log
export WAVELOG=${COMOUT}/wave.log  ## boss log

# Remote host Polar
export HOST='emcrzdm.ncep.noaa.gov'
export USRID='waves'  ## was usrID
export RWEB='/home/www/polar/waves/WEB'
export RFTP='/home/ftp/polar/waves/WEB'
export RHOME='/home/people/emc/waves'
