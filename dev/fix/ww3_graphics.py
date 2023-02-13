#!/bin/env python
"""
GFS-Wave Graphics Postprocessor
Todd Spindler

Version	Date			Comments
1.0		9 Jul 2021		initial version ported from GEFS-Wave
1.01    9 Aug 2021      Use full GFS-Wave buoy list and regional buoy lists
1.02   17 Aug 2021      Replaced contourf with pcolormesh and BoundaryNorm

"""

import warnings
#warnings.filterwarnings("ignore")
import matplotlib as mpl
mpl.use('svg')  # there is a problem with Mars Agg backend
import matplotlib.pyplot as plt
import matplotlib.image as image
import matplotlib.colors as colors
#from matplotlib.colors import LinearSegmentedColormap
from matplotlib import rc
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import pandas as pd
import numpy as np
import xarray as xr
from datetime import datetime, timedelta
import os, sys
#import warnings 

#warnings.filterwarnings("ignore")

imageDir='.'
THIS_IS_A_TEST=True

#----------------------------------------------------------------------
def init_settings():
    regions={
             'alaska':{'name':'Alaskan_Waters','lonlat':[160,230,40,80],'crs':ccrs.PlateCarree},
             'atlantic':{'name':'Atlantic','lonlat':[255,425,-77.5,77.5],'crs':ccrs.PlateCarree},
             'aus_ind_phi':{'name':'Australia-Indonesia','lonlat':[80,180,-60,40],'crs':ccrs.PlateCarree},
             'gmex':{'name':'Gulf_of_Mexico','lonlat':[262,282,13,31],'crs':ccrs.PlateCarree},
             'hawaii':{'name':'Hawaii','lonlat':[197,208,15,26],'crs':ccrs.PlateCarree},
             'indian_o':{'name':'Indian_Ocean','lonlat':[20,130,-72.5,27.5],'crs':ccrs.PlateCarree},
             'N_atlantic':{'name':'North_Atlantic','lonlat':[260,380,-7.5,82.5],'crs':ccrs.PlateCarree},
             'N_pacific':{'name':'North_Pacific','lonlat':[110,250,-7.5,82.5],'crs':ccrs.PlateCarree},
             'NE_atlantic':{'name':'Northeast_Atlantic','lonlat':[330,385,42,77],'crs':ccrs.PlateCarree},
             'NE_pacific':{'name':'Northeast_Pacific','lonlat':[160,250,3,77],'crs':ccrs.PlateCarree},
             'NW_atlantic':{'name':'Northwest_Atlantic','lonlat':[262,322,0,60],'crs':ccrs.PlateCarree},
             'pacific':{'name':'Pacific','lonlat':[110,290,-77.5,77.5],'crs':ccrs.PlateCarree},
             'pac_islands':{'name':'Pacific Islands','lonlat':[135,175,0,20],'crs':ccrs.PlateCarree},
             'US_eastcoast':{'name':'US_East_Coast','lonlat':[276,306,20.5,45.5],'crs':ccrs.PlateCarree},
             'US_keywest':{'name':'Key_West','lonlat':[274,282,21,29],'crs':ccrs.PlateCarree},
             'US_puertorico':{'name':'Puerto_Rico','lonlat':[290,297,15,22],'crs':ccrs.PlateCarree},
             'US_wc_zm1':{'name':'US_West_Coast_Zoom_1','lonlat':[223,237,38.75,50.75],'crs':ccrs.PlateCarree},
             'US_wc_zm2':{'name':'US_West_Coast_Zoom_2','lonlat':[230,244,29,41],'crs':ccrs.PlateCarree},
             'arctic':{'name':'Arctic','lonlat':[0,360,55,90],'crs':ccrs.NorthPolarStereo},
             'antarctic':{'name':'Antarctic','lonlat':[0,360,-90,-30],'crs':ccrs.SouthPolarStereo}
             }
    
    vlims={}
    vlims['HTSGW_surface']=np.hstack([np.arange(0,1.6,.5),np.arange(2,15.1)])
    vlims['PERPW_surface']=np.hstack([np.arange(2,9,2),np.arange(9,21.1)])
    vlims['WIND_surface']=np.arange(4,69,4)
    vlims['WVHGT_surface']=vlims['HTSGW_surface']
    vlims['SWELL_1insequence']=vlims['HTSGW_surface']
    vlims['SWELL_2insequence']=vlims['HTSGW_surface']
    vlims['SWELL_3insequence']=vlims['HTSGW_surface']
    vlims['WVPER_surface']=vlims['PERPW_surface']
    vlims['SWPER_1insequence']=vlims['PERPW_surface']
    vlims['SWPER_2insequence']=vlims['PERPW_surface']
    vlims['SWPER_3insequence']=vlims['PERPW_surface']
    return regions, vlims

#----------------------------------------------------------------------
def plot_map(theDate,cycle,fcst,region_name):
    """
    general purpose field data processing and plotting routine
    """
    
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

    dpi=150
    pixwidth=600
    pixheight=660
    
    # load regions and plotting limits
    regions, vlims=init_settings()
    region=regions[region_name]
        
    # load buoy locations
    #names=['LON','LAT','NAME','AH','TYPE','SOURCE','SCALE']
    #buoys=pd.read_csv('wave_gfs.buoys.dat',comment='$',names=names,
    #	header=None,skipinitialspace=True,delimiter=' ',quotechar="'")
    #buoys=pd.read_csv('fix/gfswave_active_buoys.dat')        
    #buoys['id']=buoys.id.astype('str')
    
    names=['lon','lat','id','ah','type','source','scale']
    buoys=pd.read_csv('wave_gfs.buoys.full',comment='$',names=names,
    	header=None,skipinitialspace=True,delimiter=' ',quotechar="'")
    buoys['id']=buoys.id.str.strip()
    buoys.drop(columns=['ah','type','source','scale'],inplace=True)
    buoys.sort_values('id',inplace=True)
    buoys['lon']=buoys.lon%360. # convert from -180 - 180 to 0 - 360

    # load regional buoys list and use it to select from the full buoys list
    if region_name != 'arctic' and region_name != 'antarctic':    
        region_buoys=pd.read_csv('buoys.'+region_name,header=None,names=['id','x','y'],
    		skipinitialspace=True,delimiter=' ',skiprows=1)
        region_buoys.sort_values('id',inplace=True)
        buoys=buoys[buoys.id.isin(region_buoys.id)]
    # Some buoys are across the prime meridian, this might fix that
    buoys['lon']=buoys.lon.where(buoys.lon>=region['lonlat'][0],buoys.lon+360)
    
    buoys=buoys.to_xarray().set_coords(['lon','lat'])
    
    
    #hlevs = '0.5 1.0 1.5 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10. 11. 12. 13. 14. 15.'
    #hcols = '21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38'
    hlevs=[*np.arange(0.5,1.6,0.5),*np.arange(2.,16.)]
    hcols=colors.LinearSegmentedColormap.from_list('hcols',hendrik_colors)
    
    #tlevs = '2  4  6  8  9  10 11 12 13 14 15 16 17 18 19 20 21'
    #tcols = '21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38'
    tlevs=[*range(2,9,2),*range(9,22)]
    tcols=colors.LinearSegmentedColormap.from_list('tcols',hendrik_colors)
    
    #wlevs = '4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 '
    #wcols = '21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38'
    wlevs=range(4,69,4)
    wcols=colors.LinearSegmentedColormap.from_list('wcols',hendrik_colors)
    
    #flevs = '0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9'
    #fcols = '21 23 25 27 29 30 32 34 36 38'
    flevs=np.arange(0.1,1.0,0.1)
    fcols=colors.LinearSegmentedColormap.from_list('fcols',hendrik_colors[::2])
    
    #nlevs = '0.5 1.5 2.5 3.5 4.5 5.5 6.5 7.5 8.5 9.5 10.5 11.5 12.5 13.5 14.5'
    #ncols = '21 23 24 25 26 27 28 29 30 31 32 33 34 35 36 38'
    nlevs=np.arange(0.5,14.6,0.5)
    ncols=colors.LinearSegmentedColormap.from_list('ncols',hendrik_colors[[0,*range(2,18)]])

    params={'HTSGW_surface':{'name':'hs','cmap':hcols,'levels':hlevs},
            'PERPW_surface':{'name':'tp','cmap':tcols,'levels':tlevs},
            'WVHGT_surface':{'name':'hs_ws','cmap':hcols,'levels':hlevs},
            'WVPER_surface':{'name':'tp_ws','cmap':tcols,'levels':tlevs},
            'WIND_surface' :{'name':'u10','cmap':wcols,'levels':wlevs},
            'SWELL_1insequence':{'name':'hs_sw1','cmap':hcols,'levels':hlevs},
            'SWPER_1insequence':{'name':'tp_sw1','cmap':tcols,'levels':tlevs},
            'SWELL_2insequence':{'name':'hs_sw2','cmap':hcols,'levels':hlevs},
            'SWPER_2insequence':{'name':'tp_sw2','cmap':tcols,'levels':tlevs},
            'SWELL_3insequence':{'name':'hs_sw3','cmap':hcols,'levels':hlevs},
            'SWPER_3insequence':{'name':'tp_sw3','cmap':tcols,'levels':tlevs}}

    # set up the image directories
    if not os.path.exists(f'{imageDir}/plots'):
        os.makedirs(f'{imageDir}/plots')
    if not os.path.exists(f'{imageDir}/buoy_locs'):
        os.makedirs(f'{imageDir}/buoy_locs')
        
    if THIS_IS_A_TEST:
        fname=f'/lfs/h2/emc/ptmp/deanna.spindler/GFS_WEB/JWAVE_GFS_WEB.v16.3.3/gfswave.t{cycle:02n}z.global.0p25.f{fcst:03n}.nc'
    else:
        fname=f'gfswave.t{cycle:02n}z.global.0p25.f{fcst:03n}.nc'
        
    data=xr.open_dataset(fname,decode_times=True)
    data=data.squeeze()

    # extend grid for antimeridian issues
    data2=data.copy()
    data2['longitude']=data2.longitude+360.
    data=xr.concat([data,data2],dim='longitude')

    print('processing',theDate,cycle,fcst,region_name)    

    for param in params:
        if data[param].level=='1 in sequence':
            data[param].attrs['long_name']=data[param].long_name.replace('of','of Primary')
        elif data[param].level=='2 in sequence':
            data[param].attrs['long_name']=data[param].long_name.replace('of','of Secondary')
        elif data[param].level=='3 in sequence':
            data[param].attrs['long_name']=data[param].long_name.replace('of','of Tertiary')

            
    data2=data.where((data.longitude>=region['lonlat'][0]) & 
                     (data.longitude<region['lonlat'][1]) &
                     (data.latitude>=region['lonlat'][2]) & 
                     (data.latitude<region['lonlat'][3]),drop=True)
                                 
    buoys2=buoys.where((buoys.lon>=region['lonlat'][0]) &
                       (buoys.lon<region['lonlat'][1]) &
                       (buoys.lat>=region['lonlat'][2]) &
                       (buoys.lat<region['lonlat'][3]),drop=True)
    
    # all wave and wind directions reference true north, not 0 radians
    #scaled with wind speed
    uwind=data2.WIND_surface.to_masked_array()*np.sin(np.radians(data2.WDIR_surface.to_masked_array()-180.))
    vwind=data2.WIND_surface.to_masked_array()*np.cos(np.radians(data2.WDIR_surface.to_masked_array()-180.))

    # unit direction vector
    uwwave=np.sin(np.radians(data2.WVDIR_surface.to_masked_array()-180.))
    vwwave=np.cos(np.radians(data2.WVDIR_surface.to_masked_array()-180.))

    # unit direction vector
    uwave=np.sin(np.radians(data2.DIRPW_surface.to_masked_array()-180.))
    vwave=np.cos(np.radians(data2.DIRPW_surface.to_masked_array()-180.))

    lons=data2.HTSGW_surface.longitude.values
    lats=data2.HTSGW_surface.latitude.values

    #lonlat=region['lonlat'].copy()
    #lonlat[0]=np.remainder((lonlat[0]+180),360)-180
    #lonlat[1]=np.remainder((lonlat[1]+180),360)-180
    
    for pname,param in params.items():
        # create figure with pixel-specific size
        #fig=plt.figure(dpi=dpi,figsize=(pixwidth/dpi,pixheight/dpi),tight_layout=True)
        fig=plt.figure(dpi=dpi,figsize=(pixwidth/dpi,pixheight/dpi))
            
        central_longitude=(region['lonlat'][0]+region['lonlat'][1])/2.
        proj=region['crs'](central_longitude=central_longitude)
        ax=plt.axes(projection=proj)
        if region_name != 'arctic' and region_name != 'antarctic':
            ax.set_aspect('auto')
        #else:
        #    ax.set_extent(region['lonlat'],crs=proj)
                
        WANT_QUIVER=False
        WANT_BARB=False
        if pname=='HTSGW_surface':
            WANT_QUIVER=True
            WANT_BARB=True
            u=uwave
            v=vwave
            qlabel='Primary Wave Direction (unscaled)'
            qcolor='red'
        elif pname=='PERPW_surface':
            WANT_QUIVER=True
            WANT_BARB=False
            u=uwave
            v=vwave            
            qlabel='Primary Wave Direction (unscaled)'
            qcolor='black'
        elif pname[:5]=='SWELL' or pname[:5]=='SWPER':
            WANT_QUIVER=False
            WANT_BARB=False
        elif pname=='WVHGT_surface' or pname=='WVPER_surface':
            WANT_QUIVER=True
            WANT_BARB=False
            u=uwwave
            v=vwwave
            qlabel='Wind Wave Direction (unscaled)'
            qcolor='black'
        elif pname=='WIND_surface':
            WANT_QUIVER=False
            WANT_BARB=True
    
        if WANT_QUIVER:
            ax.plot(np.nan,np.nan,'-',color=qcolor,label=qlabel,linewidth=0.5)
        if WANT_BARB:
            ax.plot(np.nan,np.nan,'-',color='black',label='Wind Barbs',linewidth=0.5)
        if WANT_QUIVER or WANT_BARB:
            ax.legend(loc='lower center',fontsize='x-small',ncol=2)
            
        # some regions need more arrows than others
        if region_name != 'arctic' and region_name != 'antarctic':
            skipx=int(np.round(lons.size/25))
            skipy=skipx
        else:
            skipx=int(np.round(lons.size/50))
            skipy=int(np.round(lons.size/100))
            
        if WANT_QUIVER:
            # normalize the wave direction vectors
            u=u/np.sqrt(u**2 + v**2);
            v=v/np.sqrt(u**2 + v**2);
            ax.quiver(lons[::skipx],lats[::skipy],
            	u[::skipy,::skipx],v[::skipy,::skipx],
                scale=33.,color='r',linewidth=0.05,
                transform=ccrs.PlateCarree(),zorder=2)
        if WANT_BARB:
            ax.barbs(lons[::skipx],lats[::skipy],
            	uwind[::skipy,::skipx],vwind[::skipy,::skipx],
                length=3,color='black',
                transform=ccrs.PlateCarree(),linewidth=0.3,zorder=3)
                
        # if the dataset is empty, create a dummy axes for the contour  
        # and hide it just to build a colorbar
                
        try:
            #cc=data2[pname].plot.contourf(levels=param['levels'],cmap=param['cmap'],ax=ax,
            #                              transform=ccrs.PlateCarree(),add_colorbar=False,zorder=0)
            
            # set up faceted colormap using Hendrik's levels and colors
            norm = colors.BoundaryNorm(boundaries=param['levels'], ncolors=len(param['levels'])-1)
            cc=data2[pname].plot.pcolormesh(cmap=param['cmap'],ax=ax,norm=norm,
                                            transform=ccrs.PlateCarree(),add_colorbar=False,zorder=0)
            #data2[pname].plot.contour(levels=param['levels'],ax=ax,linewidths=0.2,colors='k',
            #                          transform=ccrs.PlateCarree())
        except:
            data2[pname][0:2,0:2]=0.0
            ax2=fig.add_axes([0,0,0.8,0.8])
            cc=data2[pname].plot.contourf(levels=param['levels'],cmap=param['cmap'],ax=ax2,
            	add_colorbar=False,zorder=0)
            ax2.set_visible(False)
            plt.sca(ax)
                            
        #cbar=plt.colorbar(cc,ax=ax,ticks=param['levels'],
        #	orientation='horizontal',pad=0.1,shrink=0.9,aspect=0.9)
        cbar=plt.colorbar(cc,ax=ax,
        	orientation='horizontal',pad=0.1,shrink=0.9)
            #label=data2[pname].long_name)
        cbar.ax.tick_params(labelsize='x-small')
        cbar.ax.set_title(label=data2[pname].long_name+' ('+data2[pname].units+')', fontdict={'fontsize':'x-small','fontweight':'bold'},loc='center')
            
        # add buoys to regional plots
        if region_name != 'arctic' and region_name != 'antarctic' and buoys2.lon.size>0:
            ax.plot(buoys2.lon,buoys2.lat,marker='o',mfc='yellow',mew=0.2,mec='k',markersize=3.0,
            	transform=ccrs.PlateCarree(),linestyle='none')

        #ax.axis('image')
        ax.add_feature(cfeature.LAND)
        ax.coastlines('50m',linewidth=0.5)
        #ax.add_feature(cfeature.COASTLINE,linewidth=0.5)
        if region_name != 'arctic' and region_name != 'antarctic':
            gl=ax.gridlines(draw_labels=True)
            gl.xlabel_style = {'size': 'x-small'}
            gl.ylabel_style = {'size': 'x-small'}
            gl.top_labels=False
            gl.right_labels=False
        else:
            gl=ax.gridlines(draw_labels=False)
        title1='GFS-Wave ' 
        title2='{} {} t{:02n}z {:03n}h fcst\nvalid {}'.format(
        	region["name"].replace("_"," "),
            theDate.strftime('%Y%m%d'),
            cycle,
            fcst,
            pd.to_datetime(data.time.values).to_pydatetime().strftime('%Y%m%d %HZ'))
        #plt.title(title1+title2,fontsize='x-small',fontweight='bold')
        plt.title(title1+title2,fontdict={'fontsize':'x-small','fontweight':'bold'})
        fig.canvas.draw()        
        #fig.savefig(f'{imageDir}/plots/{region_name}_{param["name"]}_t{cycle:02n}z_f{fcst:03n}.png',dpi=dpi)
        
        # naming scheme set to match old grads images
        fig.savefig(f'{imageDir}/plots/{region_name}.{param["name"]}.f{fcst:03n}.png',dpi=dpi)
        
        # dump the buoy pixel locations once for each region
        # but only for the f000 sig. wave height
        if pname=='HTSGW_surface' and fcst==0:                
            buoys3=buoys2.to_dataframe()
            locs=buoys3[['lon','lat']].to_numpy()
            trans = ccrs.PlateCarree()._as_mpl_transform(ax)
            for iloc in locs:
                loc=trans.transform_point(iloc)
                try:
                    loc2=np.vstack((loc2,loc))
                except:
                    loc2=loc.copy()
            if loc2.ndim==1:
                loc2=loc2[np.newaxis,]                
            loc2=np.round(loc2)
            buoys3['lon']=loc2[:,0].astype('int')
            buoys3['lat']=loc2[:,1].astype('int')
            del loc2
            buoys3.to_csv(f'{imageDir}/buoy_locs/buoys.{region_name}',
            	header=True,index=False,sep=' ',columns=['id','lon','lat'])
        
        plt.close()
    return

#----------------------------------------------------------------------
if __name__=='__main__':
    
    theDate=pd.Timestamp(sys.argv[1])
    cycle=int(sys.argv[2])
    fcst=int(sys.argv[3])
    region=sys.argv[4]
    
    plot_map(theDate,cycle,fcst,region)
    
    sys.exit()
    #os._exit()                
