*DECK DEVDRV
      SUBROUTINE DEVDRV(IPDEV,IPMTX,IGEO,NMIX,NTOT,LIMIT)
*
*-----------------------------------------------------------------------
*
*Purpose:
* read specifications for the rod-devices from the input file.
*
*Copyright:
* Copyright (C) 2007 Ecole Polytechnique de Montreal.
*
*Author(s): D. Sekki and A. Hebert
*
*Parameters: input
* IPDEV  pointer to device information.
* IPMTX  pointer to matex information.
* IGEO   index related to the reactor geometry.
* NMIX   old maximum number of material mixtures.
* NTOT   old total number of all mixtures.
* LIMIT  core limiting coordinates.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPDEV,IPMTX
      INTEGER IGEO,NMIX,NTOT
      REAL LIMIT(6)
*----
*  LOCAL VARIABLES
*----
      PARAMETER(NSTATE=40,IOUT=6,MAXPRT=10)
      CHARACTER TEXT*12,HSMG*131
      TYPE(C_PTR) JPDEV,KPDEV
      INTEGER ISTATE(NSTATE),NRGRP,DMIX(2,MAXPRT)
      DOUBLE PRECISION DFLOT
      INTEGER, ALLOCATABLE, DIMENSION(:) :: MIX
*----
*  CORE LIMITS
*----
      CALL LCMPUT(IPDEV,'CORE-LIMITS',6,2,LIMIT)
*----
*  READ INPUT DATA
*----
      IMPX=1
      CALL REDGET(ITYP,NITMA,FLOT,TEXT,DFLOT)
      IF(ITYP.NE.3)CALL XABORT('@DEVDRV: CHARACTER DATA EXPECTED(1).')
      IF(TEXT.NE.'EDIT')GOTO 10
*     PRINTING INDEX
      CALL REDGET(ITYP,IMPX,FLOT,TEXT,DFLOT)
      IF(ITYP.NE.1)CALL XABORT('@DEVDRV: INTEGER FOR EDIT EXPECTED.')
      CALL REDGET(ITYP,NITMA,FLOT,TEXT,DFLOT)
      IF(ITYP.NE.3)CALL XABORT('@DEVDRV: CHARACTER DATA EXPECTED(2).')
   10 IF(TEXT.NE.'NUM-ROD')CALL XABORT('@DEVDRV: KEYWORD NUM-ROD EX'
     1 //'PECTED.')
*     TOTAL NUMBER OF RODS
      CALL REDGET(ITYP,NROD,FLOT,TEXT,DFLOT)
      IF(ITYP.NE.1)CALL XABORT('@DEVDRV: INTEGER TOTAL NUMBER OF ROD'
     1 //'S EXPECTED.')
      IF(NROD.LT.1)CALL XABORT('@DEVDRV: WRONG TOTAL NUMBER OF RODS <1')
      IF(IMPX.GT.1)WRITE(IOUT,1003) LIMIT(1),LIMIT(3),LIMIT(5),LIMIT(2),
     1 LIMIT(4),LIMIT(6)
      IF(IMPX.GT.0)WRITE(IOUT,1000) NROD
*
      MAXTOT=NTOT+NROD*2*MAXPRT
      ALLOCATE(MIX(MAXTOT))
      CALL XDISET(MIX,MAXTOT,0)
      CALL LCMGET(IPMTX,'MAT',MIX)
*----
*  READ OPTION
*----
      NRGRP=0
      IMODE=1
      JPDEV=LCMLID(IPDEV,'DEV_ROD',NROD)
   30 CALL REDGET(ITYP,NITMA,FLOT,TEXT,DFLOT)
      IF(TEXT.EQ.'ROD')THEN
*       READ INDIVIDUAL ROD DATA
        CALL DEVGET(JPDEV,NROD,LIMIT,IMPX)
      ELSE IF(TEXT.EQ.'CREATE')THEN
*       CREATE ROD-GROUPS
        CALL REDGET(ITYP,NITMA,FLOT,TEXT,DFLOT)
        IF(TEXT.NE.'ROD-GR') CALL XABORT('@DEVDRV: KEYWORD ROD-GR EX'
     1  //'PECTED.')
        CALL REDGET(ITYP,NRGRP,FLOT,TEXT,DFLOT)
        IF(ITYP.NE.1) CALL XABORT('@DEVDRV: INTEGER NUMBER OF ROD-GR'
     1  //'OUPS EXPECTED.')
        IF(NRGRP.LT.1) CALL XABORT('@DEVDRV: WRONG NUMBER OF GROUPS <1')
        CALL DEVDGD(IPDEV,NROD,NRGRP,IMPX)
        GO TO 40
      ELSE IF(TEXT.EQ.'FADE')THEN
        IMODE=1
      ELSE IF(TEXT.EQ.'MOVE')THEN
        IMODE=2
      ELSE IF(TEXT.EQ.';') THEN
        GOTO 40
      ELSE
        WRITE(HSMG,'(26H@DEVDRV: INVALID KEYWORD (,A,2H).)') TEXT
        CALL XABORT(HSMG)
      ENDIF
      GOTO 30
*----
*  VALIDATE ROD DATA AND SET MIXTURE INDICES
*----
   40 IOFSET=0
      DO 60 ID=1,NROD
      CALL LCMLEL(JPDEV,ID,LENGT,ITYLCM)
      IF(LENGT.EQ.0) THEN
        WRITE(HSMG,'(18H@DEVDRV: ROD INDEX,I5,16H IS NOT DEFINED.)') ID
        CALL XABORT(HSMG)
      ENDIF
      KPDEV=LCMGIL(JPDEV,ID)
      CALL LCMGET(KPDEV,'ROD-PARTS',NPART)
      IF(NPART.GT.MAXPRT) CALL XABORT('@DEVDRV: MAXPRT OVERFLOW.')
      CALL LCMGET(KPDEV,'ROD-MIX',DMIX)
      DO 50 IPART=1,NPART
      DO 50 I=1,2
      IOFSET=IOFSET+1
      IF(IOFSET.GT.MAXTOT) CALL XABORT('@DEVDRV: MAXTOT OVERFLOW.')
      MIX(NTOT+IOFSET)=DMIX(I,IPART)
   50 DMIX(I,IPART)=NMIX+IOFSET
      CALL LCMPUT(KPDEV,'ROD-MIX',2*NPART,1,DMIX)
   60 CONTINUE
*----
*  STATE-VECTORS
*----
      CALL XDISET(ISTATE,NSTATE,0)
      ISTATE(1)=IGEO
      ISTATE(2)=NROD
      ISTATE(3)=NRGRP
      ISTATE(6)=IMODE
      CALL LCMPUT(IPDEV,'STATE-VECTOR',NSTATE,1,ISTATE)
      IF(IMPX.GT.1)CALL LCMLIB(IPDEV)
*     UPDATE MATEX
      CALL XDISET(ISTATE,NSTATE,0)
      CALL LCMGET(IPMTX,'STATE-VECTOR',ISTATE)
      ISTATE(2)=NMIX+IOFSET
      ISTATE(5)=NTOT+IOFSET
      CALL LCMPUT(IPMTX,'MAT',NTOT+IOFSET,1,MIX)
      CALL LCMPUT(IPMTX,'STATE-VECTOR',NSTATE,1,ISTATE)
      DEALLOCATE(MIX)
      IF(IMPX.GT.4) CALL LCMLIB(IPMTX)
      RETURN
*
 1000 FORMAT(/1X,'DEVDRV: GIVEN TOTAL NUMBER OF ROD-DEVICES:',
     1 I5//' **  READING INPUT DATA FOR RODS  **')
 1003 FORMAT(//5X,'---  REACTOR CORE LIMITS  ---'//
     1 1X,'Xmin',F10.4,5X,'Ymin',F10.4,5X,'Zmin',F10.4/
     2 1X,'Xmax',F10.4,5X,'Ymax',F10.4,5X,'Zmax',F10.4/)
      END
