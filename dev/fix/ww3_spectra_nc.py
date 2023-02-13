"""
WW3 Spectral Term Plots
version 1.0
Todd Spindler
6 July 2021

Spectral plots built to reproduce the Multi_1 GrADS spectral plots.
Two data sources:
    ASCII specfile containing all forecasts, one per cycle and buoy
    Multiple NC files from GFS-Wave binary spectral output files, one per cycle/buoy/forecast
    
"""
import matplotlib
matplotlib.use('svg')
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm, LinearSegmentedColormap
import xarray as xr
import numpy as np
import numpy.ma as ma
from copy import copy
from datetime import datetime
from math import pi
import os, sys
import pdb

#-------------------------------------------------------------------- 
def read_specfile(filename):
    """
    Read in data from a 2D spectral file in WW3 V2.22 format
    J. Henrique Alves, March, 2000
    Modified into a function form by A. Chawla, June 2011
    Ported to Python by T. Spindler October 2014
    """
        
    with open(filename) as file:        
        contents=file.read().strip().replace("'"," ").split()
     
    # process header line and convert freq,theta to np arrays
    [NF,ND],contents=[int(c) for c in contents[3:5]],contents[10:]
    freq,contents=contents[:NF],contents[NF:]
    theta,contents=contents[:ND],contents[ND:]
    theta2=copy(theta)
    theta2.append(theta2[0])
    freq=np.array(freq,dtype=float)
    theta=np.array(theta,dtype=float)
    theta2=np.array(theta2,dtype=float)
    
    # Scan basic properties of spectra from file
    
    dtheta=np.abs(theta[1]-theta[0])
        
    data={}
    data['freq'] = freq
    data['theta'] = theta    
    data['time']=[]
    data['espt']=[]
    data['U10']=[]
    data['UTheta']=[]
    data['cU']=[]
    data['cTheta']=[]
    data['sp1d']=[]
    data['hs']=[]
    data['dp']=[]
    data['fp']=[]
    
    while len(contents):
        time,contents=contents[:2],contents[2:]
        time=datetime.strptime(''.join(time),'%Y%m%d%H%M%S')
        
        stn,contents=contents[0],contents[1:]
        if len(contents[0])>7:   # lat and lon are conjoined, dammit
            latlon,contents=contents[0],contents[1:]
            lat,lon=list(map(float,latlon.replace('-',' -').split()))
            [depth,U10,UTheta,cU,cTheta],contents=[float(c) for c in contents[:5]],contents[5:]
        else:
            [lat,lon,depth,U10,UTheta,cU,cTheta],contents=[float(c) for c in contents[:7]],contents[7:]
            
        sp2d,contents=contents[:NF*ND],contents[NF*ND:]
        sp2d=np.array(sp2d,dtype=float).reshape(NF,ND,order='F')
        
        if 'stn' not in data:
            data['stn']=stn
            data['lat']=lat
            data['lon']=lon
            data['depth']=depth
            
        data['time'].append(time)
        data['U10'].append(U10)
        data['UTheta'].append(UTheta)
        data['cU'].append(cU)
        data['cTheta'].append(cTheta) 
        data['espt'].append(sp2d)        
        data['sp1d'].append(np.sum(sp2d,axis=1)*dtheta)
        data['hs'].append(4*np.sqrt(np.trapz(data['sp1d'][-1],freq)))

        # Computing peak direction

        sp2d=np.hstack((sp2d,np.expand_dims(sp2d[:,0],axis=1)))        
        loc=np.where(data['sp1d'][-1]==max(data['sp1d'][-1]))
        b1=np.trapz(np.sin(theta2)*sp2d[loc,],theta2)
        a1=np.trapz(np.cos(theta2)*sp2d[loc,],theta2)
        theta_m = np.arctan2(b1,a1)
        if (theta_m < 0):
           theta_m = theta_m + 2*pi
        data['dp'].append(theta_m)
        data['fp'].append(freq[loc])
 
    return data

#-------------------------------------------------------------------- 
def read_spec_nc(filename):
    
    data=xr.open_dataset(filename,decode_times=True)
            
    # match the names of specfile parameters
    data=data.rename({'station_name':'stn',
                      'wnd':'U10',
                      'wnddir':'UTheta',
                      'frequency':'freq',
                      'direction':'theta',
                      'efth':'espt'})
                      
    data=data.squeeze() # remove singleton dimensions

    # switch from xarray to numpy arrays
    data['theta']=np.deg2rad(data['theta']) # theta is in deg in nc
    theta=data['theta'].values
    freq=data['freq'].values
    espt=data['espt'].values
    # Hs computation taken from read_specfile
    dtheta=np.abs(theta[1]-theta[0])
    sp1d=np.sum(espt,axis=-1)*dtheta
    hs=4*np.sqrt(np.trapz(sp1d,freq,axis=-1))
    data['hs']=hs
    # decode the station name
    data['stn']=''.join(data.stn.str.decode('utf-8').values.tolist())
    
    return data

#-------------------------------------------------------------------- 
def specplot(fig,data,day,axnum=1):

    nrows=3
    ncols=2

    hendrik_colors=[(  0,   0, 205),
                    (  0, 102, 255),
                    (  0, 183, 255),
                    (  0, 224, 255),
                    (  0, 255, 255),
                    (  0, 255, 204),
                    (  0, 255, 153),
                    (  0, 255,   0),
                    (153, 255,   0),
                    (204, 255,   0),
                    (255, 255,   0),
                    (255, 204,   0),
                    (255, 153,   0),
                    (255, 102,   0),
                    (255,   0,   0),
                    (176,  48,  96),
                    (208,  32, 144),
                    (255,   0, 255)]
    hendrik_colors=np.array(hendrik_colors)/255
    cmap=LinearSegmentedColormap.from_list('hendrik',hendrik_colors)
    
    freq=data['freq']
    theta=data['theta']
    spec=data['espt'][day,]
    thedate=data['time'][day].dt.strftime('%Y/%m/%d %Hz').values
    Hs=data['hs'][day].values
    u10=data['U10'][day].values
    utheta=data['UTheta'][day].values

    # rotate the grid to the cyclic endpoint
    theta=np.roll(theta,-9)
    spec=np.roll(spec,-9,axis=1)

    # tack on the mean of the two outer spectral columns to smooth the circle
    specmean=(spec[:,1]+spec[:,-1])/2
    spec=np.hstack([spec,specmean[:,np.newaxis]])
    theta=np.hstack([theta,theta[-1]+np.diff(theta)[-1]])
    
    # normalize the spectrum
    spec=spec/spec.max()
        
    # mask low levels
    spec=ma.array(spec,mask=[spec==0])
        
    #levels=np.logspace(-2,2,num=25)
    #levels=np.geomspace(vmin,vmax,num=30)
    
    """
    Hendrik's GrADS code
    i = 17
    factor = 2
    level=1.001
    levels=''
    
    while ( i > 0 )
      level = level / factor
      levels = level ' ' levels
      i = i - 1
    endwhile
    """

    factor=2
    level=1.001
    levels=[level]
    for i in range(18,0,-1):
        level/=factor
        levels.append(level)

    levels=levels[::-1] # reverse the order of the levels
    
    # get the first entry in the colormap
    #cmap=matplotlib.cm.get_cmap('jet')
    rgba=cmap(0)

    # plot spectrum.  Note the scale factor
    ax=fig.add_subplot(nrows,ncols,axnum,polar=True,facecolor=rgba)
    ax.set_theta_zero_location('N')
    ax.set_theta_direction(-1)    
    ax.set_rlim(bottom=0,top=0.25)    
    ax.set_rscale('symlog')

    cc=ax.contourf(theta,freq,spec,levels=levels,norm=LogNorm(vmin=levels[0],vmax=levels[-1],clip=True),cmap=cmap,zorder=100)
    cc2=ax.contour(theta,freq,spec,levels=levels,norm=LogNorm(),linewidths=0.3,colors='k',zorder=200)
    ax.grid(color='w', linestyle=':', linewidth=0.5,zorder=300)
    # add white circle
    ax.fill_between(np.linspace(0.0, 2*np.pi,100), np.ones(100)*.03,edgecolor='face',facecolor='w',zorder=400)
    
    # quiver doesn't respect the theta rotation    
    # it thinks the axis is 0 at east, CCW rotation
    #print(u,utheta)
    x=u10*np.cos(np.radians(270-utheta))
    y=u10*np.sin(np.radians(270-utheta))
    ax.quiver(0,0,x,y,pivot='middle',color='k',zorder=500,units='inches',scale=50)

    ax.set_yticklabels([])
    ax.set_xticklabels([])
        
    #cc.set_clim(0.001,1.0)
    ax.text(0,1.05,thedate,horizontalalignment='left',verticalalignment='center',transform=ax.transAxes,fontsize='small')
    ax.text(1,1.05,f'Hs={Hs:>.2f}m',horizontalalignment='right',verticalalignment='center',transform=ax.transAxes,fontsize='small')
    
    ax2=fig.add_axes(ax.get_position(),frameon=True)
    ax2.patch.set_facecolor('none')
    ax2.yaxis.set_visible(False)
    ax2.xaxis.set_visible(False)
    return

#-------------------------------------------------------------------- 
if __name__ == '__main__':

    #data=read_specfile('spec/data/multi_1.'+name+'.spec')
    #data=read_specfile('specfiles/gfswave.'+name+'.spec')

    # this routine expects out_pnt.nc in the local directory
    infile='out_pnt.nc'    
    data=read_spec_nc('out_pnt.nc')
        
    fig=plt.figure(figsize=(5,8),dpi=150)
    for n,i in enumerate(range(6)):
        specplot(fig,data,i,n+1)
    
    fig.suptitle(f'GFS-Wave Spectra for {data["stn"].values}',fontsize=12,y=0.925)
    #fig.supxlabel(f'NOAA/NWS/NCEP/EMC Verif & Post-Proc Product Gen Branch {datetime.now():%Y/%m/%d}\nGFS-Wave model (static grids)',
    #    fontsize=9,y=0.06)
        
    ax=fig.add_subplot(111)
    ax.text(0.0,-0.02,'NCEP/EMC/Verification Post Processing Product Generation Branch',
    	horizontalalignment='left',fontsize=6)
    ax.text(1.0,-0.02,datetime.now().strftime('%d %b %Y'),
    	horizontalalignment='right',fontsize=6)
    plt.axis('off')
            
    plt.savefig(f'gfswave.{data["stn"].values}.spec.png',bbox_inches='tight',pad_inches=0.1)
    
