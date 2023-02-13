C$$$
      SUBROUTINE CFL(ALAT,SPD,S10M,ZHGT)
C
C ... ROUGHNESS PARAMETER SPECIFICATION FOR VST TO Z0
C ... CARDONE ALA 1969
C     DATA A/7.3627E-04/, B/1.3045E-03/, C/-1.4534E-03/
C ... CARDONE ALA 1978
      DATA A/1.641E-04/, B/4.474E-04/, C/1.217E-04/
C
C       SPD INPUT (M/SEC)
C       ASD INPUT (C)
C ..... CONVERT TO MODEL ALGORITHM
C       UM (INPUT - FEET/SEC) WIND SPEED
C       ZM (INPUT - FT ) HEIGHT AT WHICH WIND IS INPUT
C       TD (INPUT - DEG,C) AIR-SEA TEMPERATURE DIFFERENCE
C       VST (INPUT - FPS) FRICTION VELOCITY
C       Z0 (OUTPUT - FT) ROUGHNESS LENGTH
C       SLN (OUTPUT - FT) STABILITY LENGTH
C      ****  NOTE: FOR NEUTRAL STABILITY: SET SLN = 0
C
C     ISP = 1  PRINT OUT SELECTED POINTS
      ISP = 1
C
C     CC = T/(K2 * G),    T=280K, K=0.4, G = 32FT/S2
      CC = 54.3478
C
C  COMBINE NORTHERN AND SOUTHERN FIELDS TO PRODUCE GLOBAL FIELDS
C    (1,1) IN GLOBAL FIELDS IS AT (90N,0E) AND GOES AROUND LATITUDE
C    CIRCLE TO THE EAST
C          LATITUDE         INDEX
C            90N               1
C            45N              19
C             0               37
C            45S              55
C            90S              73
C
C ****************************************************************
C
      IF(SPD.LE.0.0.or.spd.gt.60.0) then
         spd = 99.9
         s10m = 99.9
          return
c
      endif
C
      XLAT = ALAT
c     XLON = ALON
C ... HEIGHT FROM FIXED BUOY IS 3.8,4.0,5.0, 10.0, OR 13.8 METERS
      ZM = ZHGT/0.3048
C ... IN TROPICS IN BOUNDARY LAYER
C ... ASSUME CONSTANT FLUX TO 35M, AND CONSTANT WIND ABOVE
      IF(ABS(XLAT).LE.20.0.AND.(ZHGT.GT.13.8)) ZM = 35./0.3048
CCCCC IF(I.GT.73) XLON = (I-145)*2.5
C     UM = SPD(I,J)/0.3048
      UM = SPD /0.3048
      IF(UM.LT.0.0) UM = 0.0
C     TD = ASTD(I,J)
      TD = 0.0
C ... NO CORRECTION FOR STABLE CASE
      IF(TD.GT.0.) TD = 0.
      IF(TD.LT.-12.) TD =-12.
C     WRITE(6,601) UM,ZHGT,ZM,TD
  601 FORMAT(1H0,'CFL INPUT -   ','  UM',F5.1,
     *' ZHT',F5.1,'  ZM',F5.0,'  TD',F5.1)
C
      U10 = 0.0
      U20 = 0.0
      SLN = 0.0
      VST = .04*UM
C
      VSTN = VST
      IF(UM.LE.3.0) GO TO 12
      IF(VST.LE.0.0) GO TO 16
      Z0 = A/VST+B*VST**2+C
      IF(Z0.LT.0.0) GO TO 12
      ICNT = 0
C
C ... FIRST COMPUTE VST FOR NEUTRAL STABILITY
 1000 VSTN = (0.4*UM)/(ALOG(ZM/(A/VST+B*VST**2+C)))
      IF(VSTN.LT.0.0) VSTN = 0.0
      IF(ABS(VSTN-VST).LT.0.005) GO TO 1400
      VST = VSTN
      ICNT = ICNT + 1
      IF(ICNT.LT.25) GO TO 1000
      IF(ICNT.GE.25) WRITE(6,699)
  699 FORMAT(1H ,'CFL SOLUTION DOES NOT CONVERGE')
 1400 CONTINUE
C ... THE NEUTRALLY STABLE WIND
      Z0 = A/VSTN + B*VSTN**2 + C
      UN10= (VSTN/0.4)*ALOG(33./Z0)
      UN10= UN10*.3048
      UN20= (VSTN/0.4)*ALOG(65./Z0)
      UN20= UN20*.3048
      UN50= (VSTN/0.4)*ALOG(140./Z0)
      UN50= UN50*.3048
C
      IF(ABS(TD).LE.1.0) GO TO 12
C
C ... THEN ESTIMATE SL, TO COMPUTE VST ITERATIVELY
C
 2000 SLG = VST**2*CC*(ALOG(33./(A/VST+B*VST**2+C)))/TD
      SLG = VST**2*CC*(ALOG(33./(A/VST+B*VST**2+C))-PSI(33./SLG))/TD
C
    1 VSTN = (0.4*UM)/(ALOG(ZM/(A/VST+B*VST**2+C))-PSI(ZM/SLG))
      IF(VSTN.LT.0.) VSTN = 0.0
      IF(ABS(VSTN-VST).LT.0.005) GO TO 4
      VST = VSTN
      GO TO 1
C
C ... NOW USE VSTN TO COMPUTE SL, ITERATIVELY
C
    4 SL = SLG
C     WRITE(6,694)
C 694 FORMAT(1H ,'STMT 4')
C
    5 SLN = CC*VSTN**2*(ALOG(33./(A/VSTN+B*VSTN**2+C))-PSI(33./SL))/TD
      IF(ABS(SLN-SL).LT.1.0) GO TO 8
      SL = SLN
      GO TO 5
C
    8 CONTINUE
C     WRITE(6,698)
C 698 FORMAT(1H ,'STNT 8')
      IF(ABS(SLN-SLG).LT.1.0) GO TO 12
      SLG = SLN
      GO TO 1
C
C ... NOW CALCULATE THE STABILITY DEPENDENT WIND AT 10M AND 20M
   12 Z0 = A/VSTN + B*VSTN**2 + C
C     WRITE(6,6912)
C6912 FORMAT(1H ,'STNT 12')
      IF(SLN.EQ.0.0) SSS=0.0
      IF(SLN.NE.0.0) SSS = PSI(33./SLN)
      U10 = (VSTN/0.4)*(ALOG(33./Z0) - SSS)
      U10 = U10*0.3048
      S10M  = U10
      IF(SLN.NE.0.0) SSS = PSI(65./SLN)
C .... SET SSS TO ZERO TO MAKE U20 THE EQUIVALENT WIND
      SSS = 0.0
      U20 = (VSTN/0.4)*(ALOG(65./Z0) - SSS)
      U20 = U20*0.3048
      IF(SLN.NE.0.0) SSS = PSI(140./SLN)
      U50 = (VSTN/0.4)*(ALOG(140./Z0)- SSS)
      U50 = U50*0.3048
      SU = 2.*VSTN
      IF(SLN.EQ.0.) ZONL =0.0
      IF(SLN.NE.0.0) ZONL = 33./SLN
      IF(ZONL.GT.0.5) ZONL = 0.5
      IF(ZONL.LT.-1.0) ZONL = -1.0
      SV10 = 1.75*VSTN - 0.25*VSTN*(ZONL)
      GUST10 = 3.*SQRT(SU**2 + SV10**2)*0.3048
      IF(SLN.EQ.0.) ZONL =0.0
      IF(SLN.NE.0.0) ZONL = 65./SLN
      IF(ZONL.GT.0.5) ZONL = 0.5
      IF(ZONL.LT.-1.0) ZONL = -1.0
      SV20 = 1.75*VSTN - 0.25*VSTN*(ZONL)
      GUST20 = 3.*SQRT(SU**2 + SV20**2)*0.3048
      S20M  = U20
      UM =UM*0.3048
C
      IF(ISP.NE.1) GO TO 40
      ICON = 0
C     IF(MOD(J,4).NE.0.OR.MOD(I,4).NE.0) GO TO 40
C     IF((J.GE.11.AND.J.LE.63).AND.(I.GE.53.AND.I.LE.93)) ICON =1
C     IF(ICON.EQ.0) GO TO 40
C     WRITE(6,608) XLAT,XLON,UN10,U10,GUST10,UN20,U20,GUST20
  608 FORMAT(1H ,'LAT=',F5.1,' LON=',F6.1,'  UN10, U10, GUST10',3F6.1,
     *'   UN20, U20, GUST20',3F6.1)
C     WRITE(6,603) UM,UN50,U50
  603 FORMAT(1H ,'UM',F5.1,' UN50, U50',3F5.1)
C     WRITE(6,602) VST,Z0,TD,SLN
  602 FORMAT(1H ,'CFL OUTPUT - VST',F6.2,'  Z0',F7.4,'  TD',F5.1,
     *'  SLN',F6.1)
   40 CONTINUE
C
      IF(VSTN.GT.0.0) GO TO  100
   16 Z0 = 0.0
      SLN = 0.0
      IF(VSTN.EQ.0.0) GO TO 100
      VST = 0.4*UM
      VSTN = VST
      GO TO 12
C
  100 CONTINUE
C
      RETURN
      END
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C                .      .    .                                       .
C SUBPROGRAM:    PSI         FUNCTION - STABILITY CORRECTION
C   PRGMMR: WILLIAM GEMMILL  ORG: W/NMC21    DATE: 87-04-21
C
C ABSTRACT: PSI IS THE STABILITY CORRECTION TO THE WIND PROFILE IN
C   THE CONSTANT FLUX LAYER.  IT IS A FUNCTION OF Z/L WHICH THE HEIGHT
C   OF THE WIND DIVIDED BY THE MONIN-OBUKOFF STABILITY LENGTH.
C
C PROGRAM HISTORY LOG:
C   87-04-21  GEMMILL     ORIGINATOR
C
C USAGE:    CALL PSI(P)
C   INPUT ARGUMENT LIST:
C     P        - THE RATIO  OF WIND HEIGHT TO STABILITY LENGTH
C
C   OUTPUT ARGUMENT:
C     PSI(P)   - THE STABILITY CORRECTION
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  NAS
C
C$$$
      FUNCTION PSI(P)
      IF(P) 5,6,40
    5 S = SHR(P)
      SA = 1. - S
      SB = 1. + S
      PSI = SA - 2.*ATAN(SA/SB)+ALOG(SB*SB*(1.+S*S)/(2.*S)**3)
      RETURN
    6 PSI = 0.0
      RETURN
   40 PSI = -5.*ASINH(1.4*P)
      RETURN
      END
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C                .      .    .                                       .
C SUBPROGRAM:    SHR         FUNCTION - NON-DIMENSIONAL WIND SHEAR
C   PRGMMR: WILLIAM GEMMILL  ORG: W/NMC21    DATE: 87-04-21
C
C ABSTRACT: SHR IS THE NON-DIMENSIONAL SHEAR FUNCTION. IT IS A FUNCTION
C   OF Z/L WHICH THE HEIGHT OF THE WIND DIVIDED BY THE MONIN-OBUKOFF
C   STABILITY LENGHT.
C
C PROGRAM HISTORY LOG:
C   87-04-21  GEMMILL     ORIGINATOR
C
C USAGE:    CALL SHR(P)
C   INPUT ARGUMENT LIST:
C     PS       - Z/L
C
C   OUTPUT ARGUMENT:
C     SHR(P)   - THE NON-DIMENSIONAL WIND SHEAR
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  NAS
C
C$$$
      FUNCTION SHR(PS)
      IF(PS) 5,20,40
    5 SS = 1.
      P3 = -36.*PS
      P5 = -54.*PS
   10 SHR = SS*(3.*SS+P3+SS**(-3))/(4.*SS + P5)
      IF(ABS(SHR-SS).LT.1.0E-4) RETURN
      SS = SHR
      GO TO 10
   20 SHR = 1.0
      RETURN
   40 SHR = 1. + 7.0*PS/SQRT(1. + 1.96*PS*PS)
      RETURN
      END
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C                .      .    .                                       .
C SUBPROGRAM:    ACOSH1      FUNCTION - ACCURATE ACOSH
C   PRGMMR: WILLIAM GEMMILL  ORG: W/NMC21    DATE: 87-04-21
C
C ABSTRACT: ACOSH1 IS A FUNCTION TO PROVIDE ACCURATE FOR SMALL VALUES
C   OF X IN THE ACOSH.
C
C PROGRAM HISTORY LOG:
C   87-04-21  GEMMILL     ORIGINATOR
C
C USAGE:    CALL ACOSH1(X)
C   INPUT ARGUMENT LIST:
C     X        - INPUT VARIABLE TO THE ACOSH FUNCTION
C
C   OUTPUT ARGUMENT:
C     ACOSH1(X)- THE VALUE OF THE ACOSH FUNCTION FOR A GIVEN X
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  NAS
C
C$$$
      FUNCTION ACOSH1(X)
C     ACOSH1(X) = AR COSH (X+1)
      DATA SM,BIG/8.94E-8,2010./
      IF(X) 10,11,12
   10 ACOSH1 = -1000.
      RETURN
   11 ACOSH1 = 0.0
      RETURN
   12 IF(X.GT.SM) GO TO 13
      ACOSH1= SQRT(2.*X)
      RETURN
   13 XX = X
      AA = 1.
   14 IF(XX-0.25) 15,16,17
   15 XX = 2.*XX*(2. + XX)
      AA = 0.5*AA
      GO TO 14
   16 ACOSH1 = 0.6931471806*AA
      RETURN
   17 IF(XX.GT.BIG) GO TO 18
      ACOSH1 = ALOG(XX + 1. + SQRT(XX*(XX+2.)))*AA
      RETURN
   18 ACOSH1 = 0.6931471806+ALOG(XX+1.)
      RETURN
      END
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C                .      .    .                                       .
C SUBPROGRAM:    ASINH       FUNCTION - ACCURATE ASINH
C   PRGMMR: WILLIAM GEMMILL  ORG: W/NMC21    DATE: 87-04-21
C
C ABSTRACT: ASINH IS A FUNCTION TO PROVIDE ACCURATE VAULES FOR ASINH
C   AT SMALL X
C
C PROGRAM HISTORY LOG:
C   87-04-21  GEMMILL     ORIGINATOR
C
C USAGE:    CALL ASINH(X)
C   INPUT ARGUMENT LIST:
C     X        - INPUT VARIABLE TO THE ASINH FUNCTION
C
C   OUTPUT ARGUMENT:
C     ASINH(X)- THE VALUE OF THE ASINH FUNCTION FOR A GIVEN X
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C   MACHINE:  NAS
C
C$$$
      FUNCTION ASINH(X)
      DATA SM,BIG/4.47E-8,2047.5/,VBG/2011./
      IF(X.GE.VBG) GO TO 16
      IF(X.LE.-VBG) GO TO 17
      XX = X*X
      IF(XX.GT.SM) GO TO 10
      ASINH = X
      RETURN
   10 AA = 1.
      IF(X.LT.0.0) AA =-1.
   11 IF(XX-0.5625) 12,13,14
   12 XX = 4.0*XX*(1. + XX)
      AA = 0.5*AA
      GO TO 11
   13 ASINH = 0.6931471806*AA
      RETURN
   14 IF(XX.GE.BIG) GO TO 15
      ASINH = ALOG(SQRT(XX) + SQRT(XX+1.))*AA
      RETURN
   15 ASINH = ALOG(2.*SQRT(XX + 0.5))*AA
      RETURN
   16 ASINH = 0.6931471806+ALOG(X)
      RETURN
   17 ASINH =-0.6931471806 - ALOG(-X)
      RETURN
      END
