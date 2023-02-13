import os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates     

from string import *
from numpy import *
from pylab import *

import time

bfil = open('bfile')
bnum=bfil.read().replace('\n', '')
afil = open('aneh')
aneh=afil.read().replace('\n', '')
aneh=float(aneh)
pdyfil=open('PDY')
pdyc=pdyfil.read().replace('\n', '')

fhstr=['0h','24h','48h','72h','96h','120h','144h','168h','192h','216h']

fname=bnum+".00.wmo"
if os.path.isfile(fname):
	plot00=1
	yyyy, mm, date, hour, U10mod, UDmod, Hsmod, Tpmod = np.loadtxt(fname, unpack=True)
        nobs=size(mm)
        dayh=[None]*size(yyyy) 
        for k in xrange(0,nobs) :
               dayh[k]=date2num(datetime.datetime(int(yyyy[k]),int(mm[k]),int(date[k]),int(hour[k])))
else:
	plot00=0

fname=bnum+".006.wmo"
if os.path.isfile(fname):
        plot006=1
	yyyy, mm, date, hour, U10mod006, UDmod006, Hsmod006, Tpmod006 = np.loadtxt(fname, unpack=True)
        nobs=size(mm)
        dayh006=[None]*size(yyyy) 
        for k in xrange(0,nobs) :
               dayh006[k]=date2num(datetime.datetime(int(yyyy[k]),int(mm[k]),int(date[k]),int(hour[k]))) 
else:
        plot006=0

fname=bnum+".024.wmo"
if os.path.isfile(fname):
        plot024=1
	yyyy, mm, date, hour, U10mod024, UDmod024, Hsmod024, Tpmod024 = np.loadtxt(fname, unpack=True)
        nobs=size(mm)
        dayh024=[None]*size(yyyy) 
        for k in xrange(0,nobs) :
               dayh024[k]=date2num(datetime.datetime(int(yyyy[k]),int(mm[k]),int(date[k]),int(hour[k]))) 
else:
        plot024=0

fname=bnum+".048.wmo"
if os.path.isfile(fname):
        plot048=1
	yyyy, mm, date, hour, U10mod048, UDmod048, Hsmod048, Tpmod048 = np.loadtxt(fname, unpack=True)
        nobs=size(mm)
        dayh048=[None]*size(yyyy) 
        for k in xrange(0,nobs) :
               dayh048[k]=date2num(datetime.datetime(int(yyyy[k]),int(mm[k]),int(date[k]),int(hour[k]))) 
else:
        plot048=0

fname=bnum+".072.wmo"
if os.path.isfile(fname):
        plot072=1
	yyyy, mm, date, hour, U10mod072, UDmod072, Hsmod072, Tpmod072 = np.loadtxt(fname, unpack=True)
        nobs=size(mm)
        dayh072=[None]*size(yyyy) 
        for k in xrange(0,nobs) :
               dayh072[k]=date2num(datetime.datetime(int(yyyy[k]),int(mm[k]),int(date[k]),int(hour[k]))) 
else:
        plot072=0

fname=bnum+".120.wmo"
if os.path.isfile(fname):
        plot120=1
	yyyy, mm, date, hour, U10mod120, UDmod120, Hsmod120, Tpmod120 = np.loadtxt(fname, unpack=True)
        nobs=size(mm)
        dayh120=[None]*size(yyyy) 
        for k in xrange(0,nobs) :
               dayh120[k]=date2num(datetime.datetime(int(yyyy[k]),int(mm[k]),int(date[k]),int(hour[k]))) 
else:
        plot120=0

fname=bnum+".ndbc"
print os.path.getsize(fname)
if os.path.getsize(fname)>0:
        plotbuoy=1
        dateo, hh, mm, BID, BLAT, BLON, PRES, WDIR, WSPD, W10M, ATMP, SST, DPD, WVHT, AHGT = np.loadtxt(bnum+".ndbc", unpack=True)
        WSPD=WSPD*(aneh/10.)**(1/7)
        ymaxou=max(WSPD)
        ymaxot=max(DPD)
        ymaxoh=max(WVHT)
        dateoh=[None]*size(WVHT) 
        nobs=size(hh)
#        for k in xrange(1,nobs-1) :
#	        WVHT[k]=(WVHT[k-1]+WVHT[k]+WVHT[k+1])/3
#	        WSPD[k]=(WSPD[k-1]+WSPD[k]+WSPD[k+1])/3
#	        DPD[k]=(DPD[k-1]+DPD[k]+DPD[k+1])/3

        obyy=floor(dateo/10000)
        obmm=floor(dateo/100)-obyy*100
        obdd=floor(dateo)-obyy*10000-100*obmm
        for k in xrange(0,nobs) :
               dateoh[k]=date2num(datetime.datetime(int(obyy[k]),int(obmm[k]),int(obdd[k]),int(hh[k]),int(mm[k])))
else:
        plotbuoy=0
        WVHT=-1
        DPD=-1
        ymaxot=-1
        ymaxoh=-1
        ymaxou=-1
        dateoh=dayh


# Three subplots sharing both x/y axes
f, (ax1, ax2, ax3) = plt.subplots(3, sharex=True, sharey=False)
#f, (ax1, ax2) = plt.subplots(2, sharex=True, sharey=False)

ax3.plot([(1, 2), (3, 4)], [(4, 3), (2, 3)])
maxU10=-1
if plotbuoy==1:
        ax3.plot_date(dateoh, WSPD,'o',color='k',markerfacecolor='w',markersize=5,label='Buoy')
        ax3.plot_date(dateoh, WSPD,'o',markerfacecolor='lightgray',alpha=0.4,markersize=5,markeredgewidth=0.01)
if plot006==1:
        ax3.plot_date(dayh006, U10mod006, fmt='r--',linewidth=2,alpha=0.8, label='Run -6h')
if plot024==1:
        ax3.plot_date(dayh024, U10mod024, fmt='g--',linewidth=2,alpha=0.8, label='Run -1d')
        maxU10=max(maxU10,max(U10mod024))
if plot048==1:
        ax3.plot_date(dayh048, U10mod048, fmt='c--',linewidth=2,alpha=0.8, label='Run -2d')
        maxU10=max(maxU10,max(U10mod048))
if plot072==1:
        ax3.plot_date(dayh072, U10mod072, fmt='m--',linewidth=2,alpha=0.8, label='Run -3d')
        maxU10=max(maxU10,max(U10mod072))
if plot120==1:
        ax3.plot_date(dayh120, U10mod120, fmt='y--',linewidth=2,alpha=0.8, label='Run -5d')
        maxU10=max(maxU10,max(U10mod120))
ax3.plot_date(dayh, U10mod, fmt='r-',linewidth=2.5,alpha=0.8, label='Run Latest')
ax3.set_ylabel("U10 (m/s)")
ax3.grid()
ymaxm=max(maxU10,max(U10mod),max(U10mod006))
ax3.set_ylim(0,1.05*ceil(max(ymaxou,ymaxm)))
legend = ax3.legend(loc='lower right', shadow=False, fontsize=10 , handlelength=1.5, borderpad=0.25, labelspacing=0.2)
frame = legend.get_frame()
frame.set_facecolor('1.00')
frame.set_alpha(0.4)

ax1.plot([(1, 2), (3, 4)], [(4, 3), (2, 3)])
maxHs=-1
if plotbuoy==1:
        ax1.plot_date(dateoh, WVHT,'o',color='k',markerfacecolor='w',markersize=5,label='Buoy')
        ax1.plot_date(dateoh, WVHT,'o',markerfacecolor='lightgray',alpha=0.4,markersize=5,markeredgewidth=0.01)
        maxHs=max(maxHs,max(WVHT))
if plot006==1:
        ax1.plot_date(dayh006, Hsmod006, fmt='r--',linewidth=2,alpha=0.8, label='Run -6h')
        maxHs=max(maxHs,max(Hsmod006))
if plot024==1:
        ax1.plot_date(dayh024, Hsmod024, fmt='g--',linewidth=2,alpha=0.8, label='Run -1d')
        maxHs=max(maxHs,max(Hsmod024))
if plot048==1:
        ax1.plot_date(dayh048, Hsmod048, fmt='c--',linewidth=2,alpha=0.8, label='Run -2d')
        maxHs=max(maxHs,max(Hsmod048))
if plot072==1:
        ax1.plot_date(dayh072, Hsmod072, fmt='m--',linewidth=2,alpha=0.8, label='Run -3d')
        maxHs=max(maxHs,max(Hsmod072))
if plot120==1:
        ax1.plot_date(dayh120, Hsmod120, fmt='y--',linewidth=2,alpha=0.8, label='Run -5d')
        maxHs=max(maxHs,max(Hsmod120))
ax1.plot_date(dayh, Hsmod, fmt='r-',linewidth=2.5,alpha=0.8, label='Run Latest')
maxHs=max(maxHs,max(Hsmod))
# Now add the legend with some customizations.
#legend = ax1.legend(loc='upper right', shadow=False, fontsize=10 , handlelength=1.5, borderpad=0.25, labelspacing=0.2)
# The frame is matplotlib.patches.Rectangle instance surrounding the legend.
#frame = legend.get_frame()
#frame.set_facecolor('0.00')
#frame.set_alpha(0.4)
ax1.set_ylabel("Hs (m)")
ax1.grid()
ymaxm=maxHs
ax1.set_ylim(0,1.05*ceil(max(ymaxoh,ymaxm)))

ax2.plot([(7, 2), (5, 3)], [(1, 6), (9, 5)])
maxTp=-1
if plotbuoy==1:
        ax2.plot_date(dateoh, DPD,'o',color='k',markerfacecolor='w',markersize=5,label='Buoy')
        ax2.plot_date(dateoh, DPD,'o',markerfacecolor='lightgray',alpha=0.4,markersize=5,markeredgewidth=0.01)
        maxTp=max(maxTp,max(DPD))
if plot006==1:
        ax2.plot_date(dayh006, Tpmod006, fmt='r--',linewidth=2,alpha=0.8, label='Run -6h')
        maxTp=max(maxTp,max(Tpmod006))
if plot024==1:
        ax2.plot_date(dayh024, Tpmod024, fmt='g--',linewidth=2,alpha=0.8, label='Run -1d')
        maxTp=max(maxTp,max(Tpmod024))
if plot048==1:
        ax2.plot_date(dayh048, Tpmod048, fmt='c--',linewidth=2,alpha=0.8, label='Run -2d')
        maxTp=max(maxTp,max(Tpmod048))
if plot072==1:
        ax2.plot_date(dayh072, Tpmod072, fmt='m--',linewidth=2,alpha=0.8, label='Run -3d')
        maxTp=max(maxTp,max(Tpmod072))
if plot120==1:
        ax2.plot_date(dayh120, Tpmod120, fmt='y--',linewidth=2,alpha=0.8, label='Run -5d')
        maxTp=max(maxTp,max(Tpmod120))
ax2.plot_date(dayh, Tpmod, fmt='r-',linewidth=2.5,alpha=0.8, label='Run Latest')
maxTp=maxTp
ax2.set_ylabel("Tp (s)")
ax2.grid()
ymaxm=maxTp
ax2.set_ylim(0,1.05*ceil(max(ymaxot,ymaxm)))
ax2.set_xlim(dateoh[0],dateoh[-1]) 

# Fine-tune figure; make subplots close to each other and hide x ticks for
# all but bottom plot.
f.subplots_adjust(hspace=.05)
plt.setp([a.get_xticklabels() for a in f.axes[:-1]], visible=False)

plt.xlim(dayh[0]-5,ceil(max(dayh006[-1],dayh[-1])))
ax1.xaxis.set_major_formatter(DateFormatter('%y-%m-%d %H'))
f.autofmt_xdate()

ax1.title.set_fontsize(16)
ax1.xaxis.label.set_fontsize(5)
ax2.xaxis.label.set_fontsize(5)
ax1.yaxis.label.set_fontsize(12)
ax2.yaxis.label.set_fontsize(12)
plt.tick_params(axis='both', which='major', labelsize=10)

ax1.set_title("WW3 Wave Height (Hs), Peak Period (Tp) and Wind Speed (U10), GLWU x Buoy: "+bnum, fontsize=11)

# Print to file
savefig('tsval.'+bnum+'.png', dpi=None, facecolor='w',  \
edgecolor='w', orientation='landscape', papertype=None,        \
format='png', transparent=False, bbox_inches='tight',          \
pad_inches=0.1)

plt.close()

