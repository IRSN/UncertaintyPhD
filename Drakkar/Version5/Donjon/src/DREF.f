*DECK DREF
      SUBROUTINE DREF(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
* set the source of an adjoint fixed source eigenvalue problem. The
* source is the gradient of the RMS power or absorption distribution.
*
*Copyright:
* Copyright (C) 2012 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input/output
* NENTRY  number of LCM objects or files used by the operator.
* HENTRY  name of each LCM object or file:
*         HENTRY(1): creation type(L_GPT);
*         HENTRY(2): read-only type(L_OPTIMIZE);
*         HENTRY(3): read-only type(L_FLUX);
*         HENTRY(4): read-only type(L_TRACKING).
*         HENTRY(5): read-only actual type(L_MACROLIB);
*         HENTRY(6): read-only reference type(L_MACROLIB);
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
      PARAMETER (NSTATE=40)
      TYPE(C_PTR) IPGRAD,IPDREF,IPMAC1,IPMAC2,IPFLX,IPTRK
      CHARACTER HSIGN*12,TEXT12*12
      INTEGER ISTATE(NSTATE)
      DOUBLE PRECISION DFLOTT,RMSD
      LOGICAL LNO,LRMS,LNEWT
      INTEGER, ALLOCATABLE, DIMENSION(:) :: MAT,KEY
      REAL, ALLOCATABLE, DIMENSION(:) :: VOL
*----
*  PARAMETER VALIDATION.
*----
      IF(NENTRY.NE.6) CALL XABORT('DREF: SIX PARAMETERS EXPECTED.')
      IF((IENTRY(1).NE.1).AND.(IENTRY(1).NE.2)) CALL XABORT('DREF: LCM'
     1 //' OBJECT EXPECTED AT LHS.')
      IF(JENTRY(1).NE.0) CALL XABORT('DREF: FIRST ENTRY IN CREATE MODE'
     1 //' EXPECTED.')
      IPDREF=KENTRY(1)
      IF((IENTRY(2).NE.1).AND.(IENTRY(2).NE.2)) CALL XABORT('DREF: LCM'
     1  //' OBJECT EXPECTED AT LHS.')
      IF(JENTRY(2).NE.1) CALL XABORT('DREF: SECOND ENTRY IN MODIFICATI'
     1  //'ON MODE EXPECTED.')
      IPGRAD=KENTRY(2)
      CALL LCMGTC(IPGRAD,'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_OPTIMIZE') THEN
         TEXT12=HENTRY(2)
         CALL XABORT('DREF: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1   '. L_OPTIMIZE EXPECTED.')
      ENDIF
      CALL LCMGET(IPGRAD,'STATE-VECTOR',ISTATE)
      LNEWT=ISTATE(8).EQ.4
      CALL LCMGET(IPGRAD,'DEL-STATE',ISTATE)
      ICONT=ISTATE(4)
      DO I=3,6
         IF((JENTRY(I).NE.2).OR.((IENTRY(I).NE.1).AND.(IENTRY(I).NE.2)))
     1   CALL XABORT('DREF: LCM OBJECT IN READ-ONLY MODE EXPECTED AT R'
     2   //'HS.')
      ENDDO
*----
*  RECOVER THE ACTUAL FLUX SOLUTION AND CORRESPONDING TRACKING.
*----
      CALL LCMGTC(KENTRY(3),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_FLUX') THEN
         TEXT12=HENTRY(3)
         CALL XABORT('DREF: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1   '. L_FLUX EXPECTED.')
      ENDIF
      IPFLX=KENTRY(3)
      CALL LCMGET(IPFLX,'STATE-VECTOR',ISTATE)
      NG=ISTATE(1)
      NUN=ISTATE(2)
      CALL LCMGTC(KENTRY(3+1),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_TRACK') THEN
         TEXT12=HENTRY(4)
         CALL XABORT('DREF: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1   '. L_TRACK EXPECTED.')
      ENDIF
      IPTRK=KENTRY(4)
      CALL LCMGET(IPTRK,'STATE-VECTOR',ISTATE)
      NREG=ISTATE(1)
      ITYPE=ISTATE(6)
      IELEM=ISTATE(9)
      ICHX=ISTATE(12)
      IF(ISTATE(2).NE.NUN) CALL XABORT('DREF: INVALID NUN.')
      CALL LCMGTC(IPTRK,'TRACK-TYPE',12,1,TEXT12)
      IF(TEXT12.NE.'TRIVAC') CALL XABORT('DREF: TRIVAC EXPECTED.')
      ALLOCATE(MAT(NREG),KEY(NREG),VOL(NREG))
      CALL LCMGET(IPTRK,'MATCOD',MAT)
      CALL LCMGET(IPTRK,'KEYFLX',KEY)
      CALL LCMGET(IPTRK,'VOLUME',VOL)
*----
*  RECOVER THE ACTUAL MACROLIB.
*----
      CALL LCMGTC(KENTRY(5),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.EQ.'L_MACROLIB') THEN
         IPMAC1=KENTRY(5)
      ELSE IF(HSIGN.EQ.'L_LIBRARY') THEN
         IPMAC1=LCMGID(KENTRY(5),'MACROLIB')
      ELSE
         TEXT12=HENTRY(5)
         CALL XABORT('DREF: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1   '. ACTUAL L_MACROLIB OR L_LIBRARY EXPECTED.')
      ENDIF
      CALL LCMGET(IPMAC1,'STATE-VECTOR',ISTATE)
      IF(ISTATE(1).NE.NG) CALL XABORT('DREF: INVALID NUMBER OF GROUPS.')
      NMIL=ISTATE(2)
      NFIS1=ISTATE(4)
      ILEAK1=ISTATE(9)
*----
*  RECOVER THE REFERENCE MACROLIB.
*----
      CALL LCMGTC(KENTRY(6),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.EQ.'L_MACROLIB') THEN
         IPMAC2=KENTRY(6)
      ELSE IF(HSIGN.EQ.'L_LIBRARY') THEN
         IPMAC2=LCMGID(KENTRY(6),'MACROLIB')
      ELSE
         TEXT12=HENTRY(6)
         CALL XABORT('DREF: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1   '. REFERENCE L_MACROLIB OR L_LIBRARY EXPECTED.')
      ENDIF
      CALL LCMGET(IPMAC2,'STATE-VECTOR',ISTATE)
      IF(ISTATE(1).NE.NG) THEN
         CALL XABORT('DREF: INVALID NUMBER OF REFERENCE GROUPS.')
      ELSE IF(ISTATE(2).NE.NMIL) THEN
         CALL XABORT('DREF: INVALID NUMBER OF REFERENCE MIXTURES.')
      ENDIF
      NFIS2=ISTATE(4)
      NALBP=ISTATE(8)
      ILEAK2=ISTATE(9)
      IDF=ISTATE(12)
      IF((NALBP.GT.0).AND.(ICHX.NE.2)) CALL XABORT('DREF: RAVIART-THOM'
     1 //'AS FINITE ELEMENTS EXPECTED.')
*----
*  READ INPUT PARAMETERS
*----
      IPRINT=1
      LNO=.FALSE.
      LRMS=.FALSE.
   10 CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
      IF(INDIC.EQ.10) GO TO 20
      IF(INDIC.NE.3) CALL XABORT('DREF: CHARACTER DATA EXPECTED')
      IF(TEXT12(1:4).EQ.'EDIT') THEN
        CALL REDGET(INDIC,IPRINT,FLOTT,TEXT12,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('DREF: INTEGER DATA EXPECTED FOR IP'
     1  //'RINT')
      ELSE IF(TEXT12.EQ.'NODERIV') THEN
        LNO=.TRUE.
        GO TO 10
      ELSE IF(TEXT12.EQ.'NEWTON') THEN
        LNEWT=.TRUE.
        GO TO 10
      ELSE IF(TEXT12(1:3).EQ.'RMS') THEN
        LRMS=.TRUE.
        GO TO 20
      ELSE IF(TEXT12(1:1).EQ.';') THEN
        IF(LRMS) RETURN
        GO TO 20
      ELSE 
        CALL XABORT('DREF: '//TEXT12//' IS AN INVALID KEYWORD')
      ENDIF
      GO TO 10
*----
*  COMPUTE THE GPT SOURCE
*----
   20 IF((ICONT.EQ.1).OR.(ICONT.EQ.2)) THEN
        CALL DRESOU(IPRINT,IPDREF,IPMAC1,IPMAC2,IPFLX,IPGRAD,NG,NREG,
     1  NMIL,NUN,MAT,KEY,VOL,LNO,RMSD)
        NFUNC=1
      ELSE IF(((ICONT.EQ.3).OR.(ICONT.EQ.4)).AND.LNEWT) THEN
*       NEWTONIAN SPH TECHNIQUE
        CALL DRENOU(IPRINT,IPDREF,IPMAC1,IPMAC2,IPFLX,IPTRK,IPGRAD,NG,
     1  NREG,ITYPE,IELEM,NMIL,NALBP,NUN,NFIS1,NFIS2,ILEAK1,ILEAK2,
     2  IDF,MAT,KEY,VOL,LNO,NFUNC,RMSD)
      ELSE IF((ICONT.EQ.3).OR.(ICONT.EQ.4).OR.(ICONT.EQ.5)) THEN
*       QUASI-NEWTONIAN SPH TECHNIQUE
        CALL DREKOU(IPRINT,IPDREF,IPMAC1,IPMAC2,IPFLX,IPTRK,IPGRAD,
     1  NG,NREG,ITYPE,IELEM,NMIL,NALBP,NUN,NFIS1,NFIS2,ILEAK1,ILEAK2,
     2  IDF,MAT,KEY,VOL,LNO,RMSD)
        NFUNC=1
      ENDIF
*
      DEALLOCATE(VOL,KEY,MAT)
*----
*  SAVE THE SIGNATURE AND STATE VECTOR
*----
      HSIGN='L_GPT'
      CALL LCMPTC(IPDREF,'SIGNATURE',12,1,HSIGN)
      CALL XDISET(ISTATE,NSTATE,0)
      ISTATE(1)=NG
      ISTATE(2)=NUN
      ISTATE(3)=0
      ISTATE(4)=NFUNC
      ISTATE(5)=NMIL
      ISTATE(6)=NG
      IF(IPRINT.GT.0) WRITE(6,100) (ISTATE(I),I=1,6)
      CALL LCMPUT(IPDREF,'STATE-VECTOR',NSTATE,1,ISTATE)
      IF(.NOT.LRMS) RETURN
*----
*  SEND BACK RMS ERROR TOWARDS CLE-2000
*----
      CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
      INDIC=-INDIC
      IF(INDIC.EQ.2) THEN
        CALL REDPUT(INDIC,NITMA,REAL(RMSD),TEXT12,DFLOTT)
      ELSE IF(INDIC.EQ.4) THEN
        CALL REDPUT(INDIC,NITMA,RMS,TEXT12,RMSD)
      ENDIF
      GO TO 10
*
  100 FORMAT(/8H OPTIONS/8H -------/
     1 7H NG    ,I8,28H   (NUMBER OF ENERGY GROUPS)/
     2 7H NUN   ,I8,40H   (NUMBER OF UNKNOWNS PER ENERGY GROUP)/
     3 7H NDIR  ,I8,35H   (NUMBER OF DIRECT FIXED SOURCES)/
     4 7H NCST  ,I8,36H   (NUMBER OF ADJOINT FIXED SOURCES)/
     5 7H NMIL  ,I8,34H   (NUMBER OF HOMOGENIZED REGIONS)/
     6 7H NG    ,I8,38H   (NUMBER OF CONDENSED ENERGY GROUPS))
      END
