*DECK NEWMAC
      SUBROUTINE NEWMAC(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
*Purpose:
* create a new macrolib which includes the devices properties.
*
*Copyright:
* Copyright (C) 2007 Ecole Polytechnique de Montreal.
*
*Author(s): D. Sekki
*
*Parameters: input/output
* NENTRY  number of LCM objects or files used by the operator.
* HENTRY  name of each LCM object or file:
*         HENTRY(1): create type(L_MACROLIB);
*         HENTRY(2): modification type(L_MATEX);
*         HENTRY(3): read-only type(L_MACROLIB);
*         HENTRY(4): read-only type(L_DEVICE).
* IENTRY  type of each LCM object or file:
*         =1 LCM memory object; =2 XSM file; =3 sequential binary file;
*         =4 sequential ascii file.
* JENTRY  access of each LCM object or file:
*         =0 the LCM object or file is created;
*         =1 the LCM object or file is open for modifications;
*         =2 the LCM object or file is open in read-only mode.
* KENTRY  LCM object address or file unit number.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER      NENTRY,IENTRY(NENTRY),JENTRY(NENTRY)
      TYPE(C_PTR)  KENTRY(NENTRY)
      CHARACTER    HENTRY(NENTRY)*12
*----
*  LOCAL VARIABLES
*----
      PARAMETER(NSTATE=40)
      CHARACTER HSIGN*12,TEXT*12,HSMG*131
      INTEGER ISTATE(NSTATE)
      DOUBLE PRECISION DFLOT
      TYPE(C_PTR) IPMAC,IPMTX,IPMAC2,IPDEV,JPMAC,KPMAC
      REAL, ALLOCATABLE, DIMENSION(:) :: HFAC
*----
*  PARAMETER VALIDATION
*----
      IF(NENTRY.NE.4)CALL XABORT('@NEWMAC: 4 PARAMETERS EXPECTED')
      IF((IENTRY(1).NE.1).AND.(IENTRY(1).NE.2))CALL XABORT('@NEWMA'
     1 //'C: LCM OBJECT EXPECTED AT LHS.')
      IF(JENTRY(1).NE.0)CALL XABORT('@NEWMAC: CREATE MODE EXPECTED'
     1 //' FOR L_MACROLIB AT LHS.')
      IPMAC=KENTRY(1)
*     L_MATEX
      IF((IENTRY(2).NE.1).AND.(IENTRY(2).NE.2))CALL XABORT('@NEWMA'
     1 //'C: LCM OBJECT EXPECTED AT RHS.')
      IF(JENTRY(2).NE.1)CALL XABORT('@NEWMAC: MODIFICATION MODE EX'
     1 //'PECTED FOR L_MATEX OBJECT.')
      CALL LCMGTC(KENTRY(2),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_MATEX')THEN
        TEXT=HENTRY(2)
        CALL XABORT('@NEWMAC: SIGNATURE OF '//TEXT//' IS '//HSIGN//
     1  '. L_MATEX EXPECTED AT RHS.')
      ENDIF
      IPMTX=KENTRY(2)
      DO IEN=3,NENTRY
      IF((IENTRY(IEN).NE.1).AND.(IENTRY(IEN).NE.2))CALL XABORT('@N'
     1 //'EWMAC: LCM OBJECT EXPECTED AT RHS.')
      IF(JENTRY(IEN).NE.2)CALL XABORT('@NEWMAC: READ-ONLY MODE EXP'
     1 //'ECTED FOR THE LCM OBJECTS AT RHS.')
      ENDDO
*     L_MACROLIB
      CALL LCMGTC(KENTRY(3),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_MACROLIB')THEN
        TEXT=HENTRY(3)
        CALL XABORT('@NEWMAC: SIGNATURE OF '//TEXT//' IS '//HSIGN//
     1  '. L_MACROLIB EXPECTED AT RHS.')
      ENDIF
      IPMAC2=KENTRY(3)
*     L_DEVICE
      CALL LCMGTC(KENTRY(4),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_DEVICE')THEN
        TEXT=HENTRY(4)
        CALL XABORT('@NEWMAC: SIGNATURE OF '//TEXT//' IS '//HSIGN//
     1  '. L_DEVICE EXPECTED AT RHS.')
      ENDIF
      IPDEV=KENTRY(4)
*----
*  RECOVER STATE-VECTOR INFORMATION
*----
      CALL XDISET(ISTATE,NSTATE,0)
*     MACROLIB-INFO
      CALL LCMGET(IPMAC2,'STATE-VECTOR',ISTATE)
      NGRP=ISTATE(1)
      NMIX=ISTATE(2)
      NL=ISTATE(3)
      NDEL=ISTATE(7)
      LEAK=ISTATE(9)
      CALL XDISET(ISTATE,NSTATE,0)
*     MATEX-INFO
      CALL LCMGET(IPMTX,'STATE-VECTOR',ISTATE)
      IF(NMIX.NE.ISTATE(2)) THEN
        WRITE(HSMG,'(45H@NEWMAC: FOUND DIFFERENT NUMBER OF MIXTURES I,
     1  12HN MACROLIB (,I8,13H) AND MATEX (,I8,2H).)') NMIX,ISTATE(2)
        CALL XABORT(HSMG)
      ENDIF
      NEL=ISTATE(7)
      LX=ISTATE(8)
      LY=ISTATE(9)
      LZ=ISTATE(10)
*----
*  READ INPUT DATA
*----
      IMPX=1
      XFAC=2.0
   10 CALL REDGET(ITYP,NITMA,FLOT,TEXT,DFLOT)
      IF(ITYP.EQ.10) GO TO 20
      IF(ITYP.NE.3)CALL XABORT('@NEWMAC: CHARACTER DATA EXPECTED(1)')
      IF(TEXT.EQ.'EDIT') THEN
*        READ PRINTING INDEX
         CALL REDGET(ITYP,IMPX,FLOT,TEXT,DFLOT)
         IF(ITYP.NE.1)CALL XABORT('@NEWMAC: INTEGER FOR EDIT EXPECTED')
      ELSE IF (TEXT.EQ.'XFAC') THEN
*        SET CORRECTIVE FACTOR FOR DELTA SIGMAS
         CALL REDGET(ITYP,NITMA,XFAC,TEXT,DFLOT)
         IF(ITYP.NE.2)CALL XABORT('@NEWMAC: REAL DATA EXPECTED')
      ELSE IF(TEXT.EQ.';') THEN
         GO TO 20
      ELSE
         CALL XABORT('@NEWMAC: INVALID KEYWORD '//TEXT)
      ENDIF
      GO TO 10
*----
*  CREATE NEW MACROLIB
*----
   20 IF(IMPX.GT.4)THEN
        CALL LCMLIB(IPMAC2)
        CALL LCMLIB(IPMTX)
        CALL LCMLIB(IPDEV)
      ENDIF
      CALL LCMEQU(IPMAC2,IPMAC)
      IF(IMPX.GT.2)CALL LCMLIB(IPMAC)
      CALL NEWMDV(IPMTX,IPMAC,IPMAC2,IPDEV,NMIX,NGRP,NL,NDEL,LEAK,
     1 NEL,LX,LY,LZ,XFAC,IMPX)
*----
*  RECOVER H-FACTOR
*----
      ALLOCATE(HFAC(NMIX*NGRP))
      JPMAC=LCMGID(IPMAC,'GROUP')
      DO JGR=1,NGRP
      KPMAC=LCMGIL(JPMAC,JGR)
      CALL LCMLEN(KPMAC,'H-FACTOR',LENGT,ITYP)
      IF(LENGT.EQ.0)CALL XABORT('@NEWMAC: UNABLE TO FIND H-F'
     1 //'ACTOR BLOCK DATA IN THE NEW MACROLIB.')
      CALL LCMGET(KPMAC,'H-FACTOR',HFAC((JGR-1)*NMIX+1))
      ENDDO
      CALL LCMPUT(IPMTX,'H-FACTOR',NMIX*NGRP,2,HFAC)
      DEALLOCATE(HFAC)
      IF(IMPX.GT.0) CALL LCMLIB(IPMAC)
      RETURN
      END
