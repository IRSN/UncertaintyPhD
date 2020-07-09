*DECK PCRMAC
      SUBROUTINE PCRMAC(MAXNIS,IPMAC,IACCS,NMIX,NGRP,NGFF,IMPX,NCAL,
     1 TERP,NISO,HISO,CONC,LMIXC,XS_CALC,B2)
*
*-----------------------------------------------------------------------
*
*Purpose:
* build the macrolib by scanning the NCAL elementary calculations and
* weighting them with TERP factors.
*
*Copyright:
* Copyright (C) 2019 Ecole Polytechnique de Montreal
*
*Author(s): A. Hebert
*
*Parameters: input
* MAXNIS  maximum value of NISO(I) in user data.
* IPMAC   address of the output macrolib LCM object.
* IACCS   =0 macrolib is created; =1 ... is updated.
* NMIX    maximum number of material mixtures in the macrolib.
* NGRP    number of energy groups.
* NGFF    number of group form factors per energy group.
* IMPX    print parameter (equal to zero for no print).
* NCAL    number of elementary calculations in the PMAXS file.
* TERP    interpolation factors.
* NISO    number of user-selected isotopes.
* HISO    name of the user-selected isotopes.
* CONC    user-defined number density of the user-selected isotopes.
* LMIXC   flag set to .true. for fuel-map mixtures to process.
* XS_CALC pointers towards PMAXS elementary calculations.
* B2      buckling
*
*-----------------------------------------------------------------------
*
      USE GANLIB
      USE PCRDATA
      IMPLICIT NONE
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPMAC
      INTEGER MAXNIS,IACCS,NMIX,NGRP,NGFF,IMPX,NCAL,NISO(NMIX),
     1 HISO(2,NMIX,MAXNIS)
      REAL TERP(NCAL,NMIX),CONC(NMIX,MAXNIS),B2
      LOGICAL LMIXC(NMIX)
      TYPE(XSBLOCK_ITEM) XS_CALC(NCAL)
*----
*  LOCAL VARIABLES
*----
      INTEGER, PARAMETER::IOUT=6
      INTEGER, PARAMETER::MAXED=30
      INTEGER, PARAMETER::MAX1D=40
      INTEGER, PARAMETER::MAX2D=20
      INTEGER, PARAMETER::MAXIFX=5
      INTEGER, PARAMETER::MAXNFI=50
      INTEGER, PARAMETER::MAXNL=5
      INTEGER, PARAMETER::MAXRES=MAX1D-10
      INTEGER, PARAMETER::NSTATE=40
      REAL FLOTVA, WEIGHT
      INTEGER I0, I1D, I2D, IBM, ICAL, IDEL, IDF, IED, IGMAX, IGMIN,
     & IGR, ILONG, IL, IPOSDE, ISO, ITRAN, ITSTMP, ITYLCM, I, JGR,
     & KSO1, KSO, MAXMIX, N1D, N2D, NBISO, NDEL, NED,NF, NL, NTYPE
      INTEGER ISTATE(NSTATE),NFINF,IACCOLD
      REAL TMPDAY(3)
      LOGICAL LMAKE1(MAX1D),LMAKE2(MAX2D),LFAST
      CHARACTER TEXT8*8,TEXT12*12,HHISO*8,CM*2,HMAK1(MAX1D)*12,
     1 HMAK2(MAX2D)*12,HVECT(MAXED)*8
      TYPE(C_PTR) IPTMP,JPTMP,KPTMP,JPMAC,KPMAC
*----
*  ALLOCATABLE ARRAYS
*----
      INTEGER, ALLOCATABLE, DIMENSION(:) :: IJJ,NJJ,IPOS,ISOMI
      REAL, ALLOCATABLE, DIMENSION(:) :: GAR4,XVOLM,WORK1,WORK2
      REAL, ALLOCATABLE, DIMENSION(:,:) :: FLUX
      REAL, ALLOCATABLE, DIMENSION(:,:,:) :: GAR1
      REAL, ALLOCATABLE, DIMENSION(:,:,:,:) :: GAR2,GAR3
      LOGICAL, ALLOCATABLE, DIMENSION(:) :: MASKL
      INTEGER, POINTER, DIMENSION(:) :: ISONA
      REAL, POINTER, DIMENSION(:) :: DENIS,FLOT
      TYPE(C_PTR) ISONA_PTR,DENIS_PTR,FLOT_PTR
      DATA HMAK1 / 'FLUX-INTG','NTOT0','OVERV','DIFF','DIFFX','DIFFY',
     1             'DIFFZ','FLUX-INTG-P1','NTOT1','H-FACTOR',MAXRES*' '/
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(IJJ(NMIX),NJJ(NMIX),IPOS(NMIX))
      ALLOCATE(FLUX(NGRP,2),GAR1(NMIX,NGRP,MAX1D),
     1 GAR2(NMIX,MAXNFI,NGRP,MAX2D),GAR3(NMIX,NGRP,NGRP,MAXNL),
     2 GAR4(NMIX*NGRP))
*
      IACCOLD=IACCS ! for ADF and GFF 
      NTYPE=0
      NFINF=0
*----
*  MACROLIB INITIALIZATION
*----
      IF(IACCS.EQ.0) THEN
*        PMAXS values:
         NL=1
         NF=0
         ITRAN=0
         NDEL=NDLAY
*         IDF=NTDF
*         NGFF=NRODS
         IDF=0
         NGFF=0
         NED=1
         HVECT(1)='H-FACTOR'
         IF(NXST.GE.7) THEN
           NED=2
           HVECT(2)='NFTOT'
         ENDIF
         IF(NXST.EQ.8) THEN
           NED=3
           HVECT(3)='DETEC'
         ENDIF
         TEXT12='L_MACROLIB'
         CALL LCMPTC(IPMAC,'SIGNATURE',12,1,TEXT12)
         ISTATE(:NSTATE)=0
         ISTATE(1)=NGRP
         ISTATE(2)=NMIX
         ISTATE(3)=NL
         ISTATE(5)=NED
         ISTATE(6)=ITRAN
         ISTATE(7)=NDEL
         ISTATE(12)=IDF
         ISTATE(16)=NGFF
         CALL LCMPUT(IPMAC,'STATE-VECTOR',NSTATE,1,ISTATE)
         CALL LCMPTC(IPMAC,'ADDXSNAME-P0',8,NED,HVECT)
      ELSE
         CALL LCMGTC(IPMAC,'SIGNATURE',12,1,TEXT12)
         IF(TEXT12.NE.'L_MACROLIB') THEN
          CALL XABORT('PCRMAC: SIGNATURE IS '//TEXT12//'. L_MACROLIB E'
     1    //'XPECTED.')
         ENDIF
         CALL LCMGET(IPMAC,'STATE-VECTOR',ISTATE)
         IF(ISTATE(1).NE.NGRP) THEN
            CALL XABORT('PCRMAC: INVALID NUMBER OF ENERGY GROUPS(2).')
         ELSE IF(ISTATE(2).NE.NMIX) THEN
            CALL XABORT('PCRMAC: INVALID NUMBER OF MIXTURES(2).')
         ENDIF
         NL=ISTATE(3)
         NF=ISTATE(4)
         NED=ISTATE(5)
         NDEL=ISTATE(7)
         IDF=ISTATE(12)
         NGFF=ISTATE(16)
         IF(NED.GT.MAXED) CALL XABORT('PCRMAC: MAXED OVERFLOW(2).')
         IF(NED.GT.0) CALL LCMGTC(IPMAC,'ADDXSNAME-P0',8,NED,HVECT)
         IF(IDF.EQ.1) THEN
           NTYPE=1
         ELSE IF((IDF.EQ.2).AND.(IACCOLD.NE.0)) THEN
           CALL LCMSIX(IPMAC,'ADF',1)
           CALL LCMGET(IPMAC,'NTYPE',NTYPE)
           CALL LCMSIX(IPMAC,' ',2)
         ENDIF
         IF((NGFF.NE.0).AND.(IACCOLD.NE.0)) THEN
           CALL LCMSIX(IPMAC,'GFF',1)
           CALL LCMLEN(IPMAC,'FINF_NUMBER ',NFINF,ITYLCM)
           IF(NFINF.GT.MAXIFX) CALL XABORT('PCRMAC: MAXIFX OVERFLOW.')
           CALL LCMSIX(IPMAC,' ',2)
         ENDIF
      ENDIF
      N1D=10+NED+NL
      N2D=2*(NDEL+1)
      IF(NL.GT.MAXNL) CALL XABORT('PCRMAC: MAXNL OVERFLOW.')
      IF(N1D.GT.MAX1D) CALL XABORT('PCRMAC: MAX1D OVERFLOW.')
      IF(N2D.GT.MAX2D) CALL XABORT('PCRMAC: MAX2D OVERFLOW.')
      LMAKE1(:N1D)=.FALSE.
      LMAKE2(:N2D)=.FALSE.
      GAR1(:NMIX,:NGRP,:N1D)=0.0
      GAR2(:NMIX,:MAXNFI,:NGRP,:N2D)=0.0
      GAR3(:NMIX,:NGRP,:NGRP,:NL)=0.0
      DO 20 IED=1,NED
   20 HMAK1(10+IED)=HVECT(IED)
      DO 30 IL=1,NL
      WRITE(CM,'(I2.2)') IL-1
   30 HMAK1(10+NED+IL)='SIGS'//CM
      HMAK2(1)='NUSIGF'
      HMAK2(2)='CHI'
      DO 40 IDEL=1,NDEL
      WRITE(TEXT8,'(6HNUSIGF,I2.2)') IDEL
      HMAK2(2+2*(IDEL-1)+1)=TEXT8
      WRITE(TEXT8,'(3HCHI,I2.2)') IDEL
      HMAK2(2+2*(IDEL-1)+2)=TEXT8
   40 CONTINUE
*----
*  READ EXISTING MACROLIB INFORMATION
*----
      ALLOCATE(XVOLM(NMIX))
      XVOLM(:NMIX)=0.0
      IF(IACCS.NE.0) THEN   ! IACCS
        CALL LCMGET(IPMAC,'VOLUME',XVOLM)
        JPMAC=LCMGID(IPMAC,'GROUP')
        DO 80 IGR=1,NGRP
        KPMAC=LCMGIL(JPMAC,IGR)
        DO 60 I1D=1,N1D
        CALL LCMLEN(KPMAC,HMAK1(I1D),ILONG,ITYLCM)
        IF(ILONG.NE.0) THEN
          LMAKE1(I1D)=.TRUE.
          CALL LCMGET(KPMAC,HMAK1(I1D),GAR1(1,IGR,I1D))
          DO 50 IBM=1,NMIX
          IF(LMIXC(IBM)) GAR1(IBM,IGR,I1D)=0.0
   50     CONTINUE
        ENDIF
   60   CONTINUE
        DO 65 I2D=1,N2D
        CALL LCMLEN(KPMAC,HMAK2(I2D),ILONG,ITYLCM)
        IF(ILONG.NE.0) THEN
          LMAKE2(I2D)=.TRUE.
          CALL LCMGET(KPMAC,HMAK2(I2D),GAR2(1,1,IGR,I2D))
          DO 64 I=1,NF
          DO 64 IBM=1,NMIX
          IF(LMIXC(IBM)) GAR2(IBM,I,IGR,I2D)=0.0
   64     CONTINUE
        ENDIF
   65   CONTINUE
        DO 80 IL=1,NL
        WRITE(CM,'(I2.2)') IL-1
        ILONG=1
        IF(IL.GT.1) CALL LCMLEN(KPMAC,'SCAT'//CM,ILONG,ITYLCM)
        IF(ILONG.NE.0) THEN
          CALL LCMGET(KPMAC,'SCAT'//CM,GAR4)
          CALL LCMGET(KPMAC,'NJJS'//CM,NJJ)
          CALL LCMGET(KPMAC,'IJJS'//CM,IJJ)
          CALL LCMGET(KPMAC,'IPOS'//CM,IPOS)
          DO 70 IBM=1,NMIX
          IPOSDE=IPOS(IBM)
          DO 70 JGR=IJJ(IBM),IJJ(IBM)-NJJ(IBM)+1,-1
          GAR3(IBM,JGR,IGR,IL)=GAR4(IPOSDE)
          IF(LMIXC(IBM)) GAR3(IBM,JGR,IGR,IL)=0.0
   70     IPOSDE=IPOSDE+1
        ENDIF
   80   CONTINUE
      ENDIF   ! IACCS
*----
*  OVERALL ELEMENTARY CALCULATION LOOP
*----
      LFAST=.TRUE.
      DO 85 IBM=1,NMIX
   85 LFAST=LFAST.AND.((.NOT.LMIXC(IBM)).OR.(NISO(IBM).EQ.0))
      DO 210 ICAL=1,NCAL
      IPTMP=C_NULL_PTR
      DO 200 IBM=1,NMIX
      WEIGHT=TERP(ICAL,IBM)
      IF((.NOT.LMIXC(IBM)).OR.(WEIGHT.EQ.0.0)) GO TO 200
*----
*  PRODUCE AN ELEMENTARY MACROLIB (IF IPTMP=C_NULL_PTR)
*----
      IF(.NOT.C_ASSOCIATED(IPTMP)) THEN
        CALL LCMOP(IPTMP,'*ELEMENTARY*',0,1,0)
        CALL PCRONE(IMPX,ICAL,IPTMP,NCAL,NGRP,XS_CALC)
        IF(IMPX.GT.0) THEN
          WRITE(IOUT,'(33H PCRMAC: PMAXS ACCESS FOR MIXTURE,I8,5H AND ,
     1    11HCALCULATION,I8,9H. WEIGHT=,1P,E12.4)') IBM,ICAL,WEIGHT
          IF(IMPX.GT.50) CALL LCMLIB(IPTMP)
        ENDIF
        CALL LCMGET(IPTMP,'STATE-VECTOR',ISTATE)
        NBISO=ISTATE(2)
        IF(ISTATE(1).NE.1) CALL XABORT('PCRMAC: INVALID NUMBER OF MATE'
     1  //'RIAL MIXTURES IN THE PMAXS FILE.')
        IF(ISTATE(3).NE.NGRP) CALL XABORT('PCRMAC: INVALID NUMBER OF E'
     1  //'NERGY GROUPS IN THE PMAXS FILE.')
        ALLOCATE(MASKL(NGRP))
        MASKL(:NGRP)=.TRUE.
        CALL LCMGPD(IPTMP,'ISOTOPESUSED',ISONA_PTR)
        CALL LCMGPD(IPTMP,'ISOTOPESDENS',DENIS_PTR)
        CALL C_F_POINTER(ISONA_PTR,ISONA,(/ NBISO /))
        CALL C_F_POINTER(DENIS_PTR,DENIS,(/ NBISO /))
        DO 110 ISO=1,NBISO
        WRITE(TEXT8,'(2A4)') (ISONA(3*(ISO-1)+I0),I0=1,2)
        KSO1=0
        DO 90 KSO=1,NISO(IBM) ! user-selected isotope
        WRITE(HHISO,'(2A4)') (HISO(I0,IBM,KSO),I0=1,2)
        IF(TEXT8.EQ.HHISO) THEN
          KSO1=KSO
          GO TO 100
        ENDIF
   90   CONTINUE
  100   IF(KSO1.GT.0) DENIS(ISO)=CONC(IBM,KSO1)
  110   CONTINUE
        MAXMIX=1
        ITSTMP=0
        TMPDAY(1)=0.0
        TMPDAY(2)=0.0
        TMPDAY(3)=0.0
        ALLOCATE(ISOMI(NBISO))
        ISOMI(:NBISO)=1
        CALL LIBMIX(IPTMP,MAXMIX,NGRP,NBISO,ISONA,ISOMI,DENIS,
     1              .TRUE.,MASKL,ITSTMP,TMPDAY)
        CALL LCMPPD(IPTMP,'ISOTOPESDENS',NBISO,2,DENIS_PTR)
        DEALLOCATE(ISOMI,MASKL)
      ENDIF
*----
*  PERFORM INTERPOLATION
*----
      CALL LCMSIX(IPTMP,'MACROLIB',1)
      CALL LCMGET(IPTMP,'STATE-VECTOR',ISTATE)
      IF(NF.EQ.0) NF=ISTATE(4)
      IF(NF.GT.MAXNFI) CALL XABORT('PCRMAC: MAXNFI OVERFLOW.')
      IF(ISTATE(1).NE.NGRP) THEN
         CALL XABORT('PCRMAC: INVALID NUMBER OF ENERGY GROUPS(3).')
      ELSE IF(ISTATE(2).NE.1)THEN
         CALL XABORT('PCRMAC: INVALID NUMBER OF MIXTURES(3).')
      ELSE IF(ISTATE(3).NE.NL) THEN
         CALL XABORT('PCRMAC: INVALID NUMBER OF LEGENDRE ORDERS(3).')
      ELSE IF((ISTATE(4).NE.0).AND.(ISTATE(4).NE.NF)) THEN
         CALL XABORT('PCRMAC: INVALID NUMBER OF FISSILE ISOTOPES(3).')
      ELSE IF((ISTATE(5).NE.NED).AND.(ISTATE(5).GT.0)) THEN
         CALL XABORT('PCRMAC: INVALID NUMBER OF EDIT REACTIONS(3).')
      ELSE IF((ISTATE(7).NE.NDEL).AND.(ISTATE(7).GT.0)) THEN
         CALL XABORT('PCRMAC: INVALID NUMBER OF PRECURSOR GROUPS(3).')
      ENDIF
      JPTMP=LCMGID(IPTMP,'GROUP')
      DO 190 IGR=1,NGRP
      KPTMP=LCMGIL(JPTMP,IGR)
      DO 170 I1D=1,N1D
      CALL LCMLEN(KPTMP,HMAK1(I1D),ILONG,ITYLCM)
      IF(ILONG.NE.0) THEN
        IF(ILONG.NE.1) CALL XABORT('PCRMAC: FLOTVA OVERFLOW.')
        LMAKE1(I1D)=.TRUE.
        CALL LCMGET(KPTMP,HMAK1(I1D),FLOTVA)
        GAR1(IBM,IGR,I1D)=GAR1(IBM,IGR,I1D)+WEIGHT*FLOTVA
      ENDIF
  170 CONTINUE
      IF(ISTATE(4).GT.0) THEN
        DO 175 I2D=1,N2D
        CALL LCMLEN(KPTMP,HMAK2(I2D),ILONG,ITYLCM)
        IF(ILONG.NE.0) THEN
          IF(ILONG.NE.NF) CALL XABORT('PCRMAC: FLOT OVERFLOW.')
          LMAKE2(I2D)=.TRUE.
          CALL LCMGPD(KPTMP,HMAK2(I2D),FLOT_PTR)
          CALL C_F_POINTER(FLOT_PTR,FLOT,(/ ILONG /))
          DO 174 I=1,NF
  174     GAR2(IBM,I,IGR,I2D)=GAR2(IBM,I,IGR,I2D)+WEIGHT*FLOT(I)
        ENDIF
  175   CONTINUE
      ENDIF
      DO 190 IL=1,NL
      WRITE(CM,'(I2.2)') IL-1
      ILONG=1
      IF(IL.GT.1) CALL LCMLEN(KPTMP,'SCAT'//CM,ILONG,ITYLCM)
      IF(ILONG.NE.0) THEN
        CALL LCMGET(KPTMP,'SCAT'//CM,GAR4)
        CALL LCMGET(KPTMP,'NJJS'//CM,NJJ)
        CALL LCMGET(KPTMP,'IJJS'//CM,IJJ)
        CALL LCMGET(KPTMP,'IPOS'//CM,IPOS)
        IPOSDE=IPOS(1)
        DO 180 JGR=IJJ(1),IJJ(1)-NJJ(1)+1,-1
        GAR3(IBM,JGR,IGR,IL)=GAR3(IBM,JGR,IGR,IL)+WEIGHT*GAR4(IPOSDE)
  180   IPOSDE=IPOSDE+1
      ENDIF
  190 CONTINUE
      CALL LCMSIX(IPTMP,' ',2)
      IF(.NOT.LFAST) CALL LCMCL(IPTMP,2)
  200 CONTINUE
      IF(C_ASSOCIATED(IPTMP)) CALL LCMCL(IPTMP,2)
  210 CONTINUE
*----
*  WRITE INTERPOLATED MACROLIB INFORMATION
*----
      CALL LCMPUT(IPMAC,'VOLUME',NMIX,2,XVOLM)
      DEALLOCATE(XVOLM)
      JPMAC=LCMLID(IPMAC,'GROUP',NGRP)
      DO 360 IGR=1,NGRP
      KPMAC=LCMDIL(JPMAC,IGR)
      DO 320 I1D=1,N1D
      IF(LMAKE1(I1D)) THEN
        CALL LCMPUT(KPMAC,HMAK1(I1D),NMIX,2,GAR1(1,IGR,I1D))
      ENDIF
  320 CONTINUE
      DO 325 I2D=1,N2D
      IF(LMAKE2(I2D).AND.(NF.GT.0)) THEN
        CALL LCMPUT(KPMAC,HMAK2(I2D),NMIX*NF,2,GAR2(1,1,IGR,I2D))
      ENDIF
  325 CONTINUE
      DO 360 IL=1,NL
      WRITE(CM,'(I2.2)') IL-1
      IPOSDE=0
      DO 350 IBM=1,NMIX
      IPOS(IBM)=IPOSDE+1
      IGMIN=IGR
      IGMAX=IGR
      DO 330 JGR=1,NGRP
      IF(GAR3(IBM,JGR,IGR,IL).NE.0.0) THEN
        IGMIN=MIN(IGMIN,JGR)
        IGMAX=MAX(IGMAX,JGR)
      ENDIF
  330 CONTINUE
      IJJ(IBM)=IGMAX
      NJJ(IBM)=IGMAX-IGMIN+1
      DO 340 JGR=IGMAX,IGMIN,-1
      IPOSDE=IPOSDE+1
  340 GAR4(IPOSDE)=GAR3(IBM,JGR,IGR,IL)
  350 CONTINUE
      IF(IPOSDE.GT.0) THEN
        CALL LCMPUT(KPMAC,'SCAT'//CM,IPOSDE,2,GAR4)
        CALL LCMPUT(KPMAC,'NJJS'//CM,NMIX,1,NJJ)
        CALL LCMPUT(KPMAC,'IJJS'//CM,NMIX,1,IJJ)
        CALL LCMPUT(KPMAC,'IPOS'//CM,NMIX,1,IPOS)
        CALL LCMPUT(KPMAC,'SIGW'//CM,NMIX,2,GAR3(1,IGR,IGR,IL))
      ENDIF
  360 CONTINUE
      IACCS=1
*----
*  UPDATE STATE-VECTOR
*----
      CALL LCMGET(IPMAC,'STATE-VECTOR',ISTATE)
      ISTATE(4)=MAX(ISTATE(4),NF)
      IF(LMAKE1(4)) ISTATE(9)=1
      IF(LMAKE1(5)) ISTATE(9)=2
      CALL LCMPUT(IPMAC,'STATE-VECTOR',NSTATE,1,ISTATE)
*----
*  INCLUDE LEAKAGE IN THE MACROLIB (USED ONLY FOR NON-REGRESSION TESTS)
*----
      IF(B2.NE.0.0) THEN
        IF(IMPX.GT.0) WRITE(6,'(/34H PCRMAC: INCLUDE LEAKAGE IN THE MA,
     1  11HCROLIB (B2=,1P,E12.5,2H).)') B2
        JPMAC=LCMGID(IPMAC,'GROUP')
        ALLOCATE(WORK1(NMIX),WORK2(NMIX))
        DO 520 IGR=1,NGRP
          KPMAC=LCMGIL(JPMAC,IGR)
          CALL LCMGET(KPMAC,'NTOT0',WORK1)
          CALL LCMGET(KPMAC,'DIFF',WORK2)
          DO 510 IBM=1,NMIX
            IF(LMIXC(IBM)) WORK1(IBM)=WORK1(IBM)+B2*WORK2(IBM)
  510     CONTINUE
          CALL LCMPUT(KPMAC,'NTOT0',NMIX,2,WORK1)
  520   CONTINUE
        DEALLOCATE(WORK2,WORK1)
      ENDIF
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(GAR4,GAR3,GAR2,GAR1,FLUX)
      DEALLOCATE(IPOS,NJJ,IJJ)
      RETURN
      END
