"""
WW3 Source Term Plots
version 1.0
Todd Spindler
4 August 2021

Source term plots built to reproduce the Multi_1 GrADS source term plots.
One data source:
    NC file from GFS-Wave binary source output files, one per cycle/buoy/forecast
    
"""
import matplotlib
matplotlib.use('svg')
import matplotlib.pyplot as plt
import matplotlib.colors as colors
from matplotlib import cm
import xarray as xr
import pandas as pd
import numpy as np
import numpy.ma as ma
from copy import copy
from datetime import datetime
from math import pi
import os, sys
import warnings

warnings.filterwarnings("ignore")

#-------------------------------------------------------------------- 
def read_source_nc(filename):
    
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
    cmap=colors.LinearSegmentedColormap.from_list('hendrik',hendrik_colors)
    
    freq=data['freq']
    theta=data['theta']
    spec=data['espt']
    thedate=data['time'].dt.strftime('%Y/%m/%d %Hz').values
    Hs=data['hs'].values
    u=data['U10'].values
    utheta=data['UTheta'].values

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
        levels=[level]+levels
    
    # get the first entry in the colormap
    #cmap=matplotlib.cm.get_cmap('jet')
    rgba=cmap(0)

    # plot spectrum.  Note the scale factor
    ax=fig.add_subplot(nrows,ncols,axnum,polar=True,facecolor=rgba)
    ax.set_theta_zero_location('N')
    ax.set_theta_direction(-1)    
    ax.set_rlim(bottom=0,top=0.25)    
    ax.set_rscale('symlog')

    cc=ax.contourf(theta,freq,spec,levels=levels,
    	norm=colors.LogNorm(vmin=levels[0],vmax=levels[-1],clip=True),
        cmap=cmap,zorder=100)
    cc2=ax.contour(theta,freq,spec,levels=levels,
    	norm=colors.LogNorm(),linewidths=0.3,colors='k',zorder=200)
    ax.grid(color='w', linestyle=':', linewidth=0.5,zorder=300)
    # add white circle
    ax.fill_between(np.linspace(0.0, 2*np.pi,100), np.ones(100)*.03,edgecolor='face',facecolor='w',zorder=400)
    
    # quiver doesn't respect the theta rotation    
    # it thinks the axis is 0 at east, CCW rotation
    #print(u,utheta)
    x=u*np.cos(np.radians(270-utheta))
    y=u*np.sin(np.radians(270-utheta))
    ax.quiver(x,y,pivot='middle',color='k',zorder=500,units='inches',scale=50)

    ax.set_yticklabels([])
    ax.set_xticklabels([])
        
    #cc.set_clim(0.001,1.0)
    ax.text(0,1.05,'spectrum',horizontalalignment='left',verticalalignment='center',transform=ax.transAxes,fontsize='small')
    #ax.text(1,1.05,f'Hs={Hs:>.2f}m',horizontalalignment='right',verticalalignment='center',transform=ax.transAxes,fontsize='small')
    
    ax2=fig.add_axes(ax.get_position(),frameon=True)
    ax2.patch.set_facecolor('none')
    ax2.yaxis.set_visible(False)
    ax2.xaxis.set_visible(False)
    return

#-------------------------------------------------------------------- 
def sourceplot(fig,data,term,axnum=1):

    term_names={'espt':'spectrum',
                'sin':'wind source term',
                'stt':'total source term',
                'snl':'nonlinear interactions',
                'sds':'dissipation source term'}
    
    nrows=3
    ncols=2

    hendrik_colors=[(  0,   0, 255),
                    (  0, 102, 255),
                    (  0, 153, 255),
                    (  0, 204, 255),
                    (  0, 255, 255),
                    (153, 255, 255),
                    (204, 255, 255),
                    (255, 255, 255),
                    (255, 255, 255),
                    (255, 255, 204),
                    (255, 255, 153),
                    (255, 255,   0),
                    (255, 204,   0),
                    (255, 153,   0),
                    (255, 102,   0),
                    (255,   0,   0)]

    hendrik_colors=np.array(hendrik_colors)/255
    cmap=colors.LinearSegmentedColormap.from_list('hendrik',hendrik_colors)
    
    freq=data['freq']
    theta=data['theta']
    spec=data[term]
    thedate=data['time'].dt.strftime('%Y/%m/%d %Hz').values
    Hs=data['hs'].values
    u=data['U10'].values
    utheta=data['UTheta'].values

    # rotate the grid to the cyclic endpoint
    theta=np.roll(theta,-9)
    spec=np.roll(spec,-9,axis=1)

    # tack on the mean of the two outer spectral columns to smooth the circle
    specmean=(spec[:,1]+spec[:,-1])/2
    spec=np.hstack([spec,specmean[:,np.newaxis]])
    theta=np.hstack([theta,theta[-1]+np.diff(theta)[-1]])

    # normalize the spectrum between -1 and 1
    ##X_std = (X - X.min(axis=0)) / (X.max(axis=0) - X.min(axis=0))
    ##X_scaled = X_std * (max - min) + min    
    #min=-1
    #max=1
    #spec=(spec-spec.min()) / (spec.max() - spec.min())
    #spec=spec*(max - min) + min

    # kinda normalize things
    spec=spec/np.abs(spec).max()
                
    """
    Hendrik's GrADS code
    i = 7
    factor = 2
    levelp =  1.001
    leveln = -1.001
    levpos = ''
    levneg = ''
*
    while ( i > 0 )
      levelp = levelp / factor
      leveln = leveln / factor
      levpos = levelp ' ' levpos
      levneg = levneg ' ' leveln
      i = i - 1
    endwhile
    levels = levneg ' 0 ' levpos
    """

    factor=1.5
    levelp=1.001
    leveln=-1.001
    levpos=[levelp]
    levneg=[leveln]
    for i in range(7,0,-1):
        levelp/=factor
        leveln/=factor
        levpos=[levelp]+levpos
        levneg=levneg+[leveln]

    levels= levneg+[0]+levpos
                
    # plot spectrum.  Note the scale factor
    ax=fig.add_subplot(nrows,ncols,axnum,polar=True)
    ax.set_theta_zero_location('N')
    ax.set_theta_direction(-1)    
    ax.set_rlim(bottom=0,top=0.25)
    #ax.set_rscale('symlog')
    
    #print(term,spec.min(),spec.max())
    if not np.isnan(spec.mean()):
        cc=ax.contourf(theta,freq,spec,levels=levels,cmap=cmap,
    		norm=colors.SymLogNorm(linthresh=0.2,clip=True))
        cc2=ax.contour(theta,freq,spec,levels=levels,
        	linewidths=0.3,colors='k')
        #plt.colorbar(cc)
    ax.grid(color='k', linestyle=':', linewidth=0.5)
    
    # add white circle
    ax.fill_between(np.linspace(0.0, 2*np.pi,100), np.ones(100)*.045,edgecolor='w',facecolor='w',zorder=1000)
            
    ax.set_yticklabels([])
    ax.set_xticklabels([])
        
    #cc.set_clim(0.001,1.0)
    ax.text(0,1.05,term_names[term],horizontalalignment='left',
    	verticalalignment='center',transform=ax.transAxes,fontsize=8)
    
    ax2=fig.add_axes(ax.get_position(),frameon=True)
    ax2.patch.set_facecolor('none')
    ax2.yaxis.set_visible(False)
    ax2.xaxis.set_visible(False)
    return

#-------------------------------------------------------------------- 
if __name__ == '__main__':

    data=read_source_nc('./ww3_src.nc')
    fig=plt.figure(figsize=(5,8),dpi=150)
    specplot(fig,data,1)
    sourceplot(fig,data,'sin',2)
    sourceplot(fig,data,'stt',3)
    sourceplot(fig,data,'snl',4)
    sourceplot(fig,data,'sds',6)
        
    text=f'Location     : {data.longitude.values:0.1f}, {data.latitude.values:0.1f}\n'+\
         f'Depth        : {data.dpt.values:0.1f} m\n'+\
         f'Wind speed   : {data.U10.values:0.1f} m/s\n'+\
         f'Current vel. : {data.cur.values:0.2f} m/s\n'+\
         f'Wave height  : {data.hs.values:0.2f} m'
         
    ax=fig.add_subplot(3,2,5)
    ax.text(0.0,0.8,text,verticalalignment='top',
	    fontdict={'size':8,'family':'monospace'})
    plt.axis('off')
        
    fig.suptitle(f'GFS-Wave Sources {data["stn"].values} '+ \
    	f'{pd.to_datetime(data.time.values).to_pydatetime():%Y%m%d %H}Z',
	    fontsize=10,y=0.925)
    #fig.supxlabel(f'NOAA/NWS/NCEP/EMC Verif & Post-Proc Product Gen Branch {datetime.now():%Y/%m/%d}\nGFS-Wave model (static grids)',
    #    fontsize=9,y=0.06)
        
    ax=fig.add_subplot(111)
    ax.text(0.0,-0.02,'NCEP/EMC/Verification Post Processing Product Generation Branch',
    	horizontalalignment='left',fontsize=6)
    ax.text(1.0,-0.02,datetime.now().strftime('%d %b %Y'),
    	horizontalalignment='right',fontsize=6)
    plt.axis('off')
            
    plt.savefig(f'gfswave.{data["stn"].values}.source.png',bbox_inches='tight',pad_inches=0.1)
    
