# GFS-Wave-WEB
Create the graphics for the GFS-Wave and upload them to the website.

lsf_scripts:

   dev_envir.sh # loads modules and exports all the directory variables

   PDY_gfswave # sets the date and cycle to run
   
   gfswave.cron # runs dev_envir.sh, sets the PDY, and runs gfswave.boss 
   
   gfswave.boss # runs JWAVE_GFS_WEB and JWAVE_GFS_PUBWEB
   
   JWAVE_GFS_WEB.pbs  # creates the graphics and the bulletin files
   
   JWAVE_GFS_PUBWEB.pbs # pushes them to the website

dev:

exec, fix, jobs, parm, scripts, sorc, ush

Output:
/user/path/to/wavepa/GFS_WEB

COM: 
gfswave.YYYYMMDD has the gfs.tHHz.webdone and pubwebdone files that
tells the demon whether to run the process or not.  Cron checks every
10 minutes.

WEB:  
gfswave.YYYYMMDDHH has the actual output files, 2.2G/day, needs to be
cleaned up periodically especially before production switches
buoy_locs: 18 files
data: 918 *.bull files
plots: 21 *tar files

OUTPUT: 
gfswave.YYYYMMDD has the gfswave.boss.tHHz.out files


