#!/bin/bash
NEWHOME=/path/to/cron
SRCDIR=/path/to/lsf_scripts

# Product Generation

## GFS-Wave WEB and PUBWEB
gfs_ver='v16.3.3'
${SRCDIR}/gfswave.cron > ${NEWHOME}/logs/gfswave_WEB.cron.out 2>1
    
