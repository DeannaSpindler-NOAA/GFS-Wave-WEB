C----------------------------------------------------------------------
c..     script sfcshp.sh
      PROGRAM READbufr
      CHARACTER*80 hstr,wada,others,CTWD,RECPT
      CHARACTER*8  SUBSET,itype(4),shipid,bname,CTEMP
      character*8 buoys(500),buoy,RAWRPT(255)
      character*10 string
      character*3 blnks
      character*1 dname(8)
      real*8 obs(10),obs1(10),obs2(6),name,seq(3,6),XTEMP,ARR(3,6)
      real seqenc(3,6)
      data hstr/'CLAT CLON YEAR MNTH DAYS HOUR MINU PMSL WDIR WSPD '/
      data wada/'SST1 TMDB POWV HOWV POWW HOWW '/
      data others/'TOCC TMDP MXGS XS10 PRWE HOVI '/
      real ahgt,ahgts(500),RTIME(2)
      integer*8 test,type,wdir,prwet,cld,fymd,fhr,
     *          rhr,rmins,odate
      DATA blnks/'   '/
c  ...             sfcship    dft-boy   fix-boy    c-man st
      data itype/'NC001001','NC001002','NC001003','NC001004'/
      equivalence(name,shipid)
      equivalence(XTEMP,CTEMP)
      equivalence(dname(1),bname)
c
C----------------------------------------------------------------------
               read(4,444)fymd
  444   format(i8,2x)
              write(6,445)fymd
  445   format(1x,i8)
c
             rewind 4
c
            ib = 0
   40    continue
            read(12,122,end=41)buoy,ahgt
              ib = ib + 1
               buoys(ib) = buoy
              ahgts(ib)  = ahgt
                   go to 40
  122 format(1x,a8,f4.1)
   41        continue
              rewind 12
c
C----------------------------------------------------------------------
         icnt = 0
      DO 1000 lubfr = 1,2
c
      CALL OPENBF(LUBFR,'IN',LUBFR)
1     DO WHILE (IREADMG(LUBFR,SUBSET,IDATE).EQ.0)
c          if(subset.eq.itype(1))type=1
            if(subset.eq.itype(2))type=2
             if(subset.eq.itype(3))type=3
c              if(subset.eq.itype(4))type=4
c
         DO WHILE (IREADSB(LUBFR).EQ.0)
C
c
            CALL UFBINT(LUBFR,OBS,10,1,IRET,HSTR)
             RECPT = ' RCHR RCMI '
            call UFBINT(LUBFR,RTIME,2,1,IRET,RECPT)
            call ufbint(lubfr,obs1,10,1,iret,wada)
            call ufbint(lubfr,obs2,6,1,iret,others)
                if(type.eq.2)then
                        string = ' BPID '
                            irpt = 2
                    elseif(type.eq.3) then
                        string = ' BPID '
                            irpt = 3
                 endif
c
c...  convert name from integer to characters
c
            call ufbint(lubfr,name,1,1,iret,string)
                   test = name
                  write(bname(1:5),'(i5.5)')test
                  write(bname(6:8),'(a3)')blnks
                   shipid = bname
c
c... fill seqence array with 99.9 when repeating seq missing ...
c
            do iseq=1,3
              do  jseq = 1,6
               seqenc(iseq,jseq) = 999.9
                seq(iseq,jseq) = 999.9
               enddo
             enddo
c
c... Look for toga fix buoys
c 
            if(type.eq.3) go to 88
c
         if(dname(3).eq.'0'.or.dname(3).eq.'1'.or.  
     *          dname(3).eq.'2'.or.dname(3).eq.'3') go to 89
            go to 98
c
   88       continue
c             
c...      get time sequences
c
             CTWD = ' TPMI WDRC WDSC '
             call UFBINT(lubfr,seq,3,6,kret,CTWD)
c
c... fill seqence array with 99.9 when repeating seq missing ...
c
            if(kret.lt.1)then
c
            do iseq=1,3
              do  jseq = 1,6
                seq(iseq,jseq) = 999.9
               enddo
             enddo
c
            endif
c
   89        continue 
c
c...    TOGA Platform
c
           if(type.eq.2)kret = 0
c               
             clat = obs(1)
             clon = obs(2)
c
             rhr = rtime(1)
             rmins = rtime(2)
           iyear = obs(3)
           iyr = iyear
           mnth = obs(4)
           iday = obs(5)
           ihrn = obs(6)
           minu = obs(7)
           pmsl = obs(8)/100.
           wdir = obs(9)
           wspd = obs(10)
           sst = obs1(1) -273.15
           airt = obs1(2) - 273.15
           poww = obs1(3)
           howw = obs1(4)
           powv = obs1(5)
           howv = obs1(6)
           cld = obs2(1)
           dpd = obs2(2) -273.15
            wdgst = obs2(3)
            f10m = obs2(4)
            if(f10m.le.00.0.or.f10m.gt.60.0)f10m = -99.9
            prwet = obs2(5)
            pres = obs2(5)
            vist = obs2(6)/100.
            visb = obs2(6)/100.
c
             if(pmsl.lt.700.0.or.pmsl.gt.1200.0)pmsl = -99.9
             if(wspd.le.00.0.or.wspd.gt.60.0)wspd = -99.9
             if(wdir.lt.00.or.wdir.gt.360) wdir = -888
             if(wdir.eq.-888)wspd = -99.9
c   if wspd missing skip obs
c
c            if(wspd.lt.0.0.or.wspd.gt.60.0) go to 98
c
             if(sst.lt.-6.0.or.sst.gt.40.0) sst = -99.9
             if(airt.lt.-50.0.or.airt.gt.40.0) airt = -99.9
             if(poww.lt.0.00.or.poww.gt.30.0) poww = -99.9
             if(howw.lt.0.00.or.howw.gt.40.0)howw = -99.9
             if(powv.lt.0.00.or.powv.gt.40.0) powv = -99.9
             if(howv.lt.0.00.or.howv.gt.40.0)howv = -99.9
             if(cld.lt.00.or.cld.gt.100.00) cld = -99
              if(dpd.lt.-50.0.or.dpd.gt.40.0) dpd = -99.9
              if(wdgst.lt.0.0.or.wdgst.gt.100.0) wdgst = -99.9
              if(f10m.lt.0.0.or.f10m.gt.60.0) w10m = -99.9
              if(prwet.lt.00.or.prwet.gt.99) prwet = -99 
              if(visb.lt.00.or.visb.gt.5000.0) visb = -99.9
c
                sdir = float(wdir)
                sspd = wspd
c
c................................................................
c
c..      replace roundoff wspd & wdir with true values
c
               tdir = seq(2,1)
               tspd = seq(3,1)
               if(tdir.lt.0.00.or.tdir.gt.360.00)tdir = 888.0
               if(tspd.le.0.00.or.tspd.gt.60.0)  tspd =  99.9
c            print *,' tdir tspd wdir wspd ',tdir,tspd,wdir,wspd
c
                 if(tdir.ge.0.0.and.tdir.le.360.0)then
                    wdir = tdir
                 endif
c
                 if(tspd.gt.0.0.and.tspd.lt.60.0)then
                   wspd = tspd
                 endif
c
      do 30 num = 1,ib
              ahgt = ahgts(num)
              if(buoys(num).ne.shipid) go to 30
              call cfl(clat,wspd,w10m,ahgt)
                go to 31
   30    continue
 
              ahgt = 99.9
   31         continue
c.........
c
             if(w10m.le.0.00.or.w10m.gt.60.0)w10m = 99.9
             if(f10m.gt.0.0.and.f10m.lt.60.0)w10m = f10m
c
             qcsst = -99.9
              visb = -99.9
c
cccc           if(kret.ge.1) then
                icnt = icnt + 1
         if(mod(icnt,20).eq.0)then
          if(wspd.gt.0.00.and.wspd.lt.60.0)
     * write(6,601)shipid,clat,clon,tdir,tspd,sdir,sspd,f10m,ahgt,w10m
  601       format(1x,'org ',a8,7f8.2,1x,f4.1,f7.2)
         endif
c
c.. Update daily archive
c
        idateo=10000*iyr+100*mnth+iday
        write(9,66)idateo,ihrn,minu,shipid,
     *  clat,clon,pmsl,wdir,wspd,w10m,airt,sst,poww,howw,ahgt
   66   format(i8,1x,i2,1x,i2,1x,a8,3f7.1,1x,i4,7f7.2)
cCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCc
c ...   Save all callsign for qc configuration
c
c       write(20,201)shipid
c 201   format(a8)
c
c
c..    For tracking buoy platforms
c
c       if(ihrn.eq.00)then
c        odate = IYR  *1000000 + Mnth  *10000 + IDay  *100 + IHRn
c         write(19,119)odate,shipid,clat,clon
c 119   format(1x,i10,1x,a8,2f7.2)
c       endif
cCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC         
  98       continue
         ENDDO
      ENDDO
 999             continue
              call   closbf(lubfr)
1000   continue
c
                write(6,68)icnt
  68        format(1x,' total no reports =',i8)
c
        rewind 9
c      rewind 19
c       rewind 20
c
      STOP
      END
