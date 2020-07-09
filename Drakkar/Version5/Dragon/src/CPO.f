*DECK CPO
      SUBROUTINE CPO(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
*Purpose:
* creation and construction of a Compo database object.
*
*Copyright:
* Copyright (C) 2007 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
*Author(s): G. Marleau
*
*Parameters: input/output
* NENTRY  number of LCM objects or files used by the operator.
* HENTRY  name of each LCM object or file:
*         HENTRY(1): Create or modification L_COMPO database object;
*         HENTRY(2): Read-only type(L_EDIT);
*         HENTRY(3): Read-only type(L_BURNUP).
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
      IMPLICIT NONE
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER      NENTRY,IENTRY(NENTRY),JENTRY(NENTRY)
      TYPE(C_PTR)  KENTRY(NENTRY)
      CHARACTER    HENTRY(NENTRY)*12
*----
*  LOCAL VARIABLES
*----
      INTEGER       IOUT,NSTATE,NDPROC,MAXNED,IBURN
      CHARACTER     NAMSBR*6
      PARAMETER    (IOUT=6,NSTATE=40,NDPROC=20,MAXNED=50,
     >              NAMSBR='CPO   ')
*----
*  ALLOCATABLE ARRAYS
*----
      INTEGER, ALLOCATABLE, DIMENSION(:) :: IDBS,ISOCPO,ISOEXT,ISOORD,
     > NBIMRG,IDIMIX,ICOMIX,ISOTMP,IMXTMP
      REAL, ALLOCATABLE, DIMENSION(:) :: VOLME,ENERG,TIME,BURN,WIR
*----
*  INPUT DATA
*----
      INTEGER       ITYPLU,INTLIR
      CHARACTER     CARLIR*12
      REAL          REALIR
      DOUBLE PRECISION DBLLIR
*----
*  LOCAL PARAMETERS
*----
      TYPE(C_PTR)   IPLIB,IPCPO,IPEDIT,IPDEPL
      CHARACTER     HVECT(MAXNED)*8,CURNAM*12,CDIRO*12,TEXT12*12,
     >              TEXT4*4,HSIGN*12,NAMCPO*8
      LOGICAL       LB2,LBURN
      INTEGER       CTITRE(18),ISTATE(NSTATE),ISTATM(NSTATE)
      INTEGER       NBMICR,NXXXZ,NL,NIFISS,NGCOND,NMERGE,NEDMAC,IST,
     >              NPROC,IEN,IKLIB,MXBURN,LENGT,MAXMRG,ITYLCM,ITEXT4,
     >              ILOCAL,I,IKDEPL,IKEDIT,MAXISM,ILEAKS,ITRANC,NOLD,
     >              ILCMLN,IBR,IPBR,MAXISO,IPRINT,NISCPO,NSBS,IEXTRC,
     >              NISEXT
*----
* PARAMETER VALIDATION.
*----
      TEXT4='    '
      READ(TEXT4,'(A4)') ITEXT4
      IF(NENTRY.LT.2) CALL XABORT(NAMSBR//
     >': AT LEAST TWO DATA STRUCTURES EXPECTED.')
      IF((IENTRY(1).NE.1).AND.(IENTRY(1).NE.2)) CALL XABORT(NAMSBR//
     >': LINKED LIST OR XSM FILE EXPECTED AT LHS.')
      IF((IENTRY(1).NE.1).AND.(IENTRY(1).NE.2)) CALL XABORT(NAMSBR//
     >': LINKED LIST OR XSM FILE EXPECTED AT LHS.')
      IPCPO=KENTRY(1)
      IF(JENTRY(1).EQ.0) THEN
        HSIGN='L_COMPO'
        CALL LCMPTC(IPCPO,'SIGNATURE',12,1,HSIGN)
      ELSE
        CALL LCMGTC(IPCPO,'SIGNATURE',12,1,HSIGN)
        IF(HSIGN.NE.'L_COMPO') THEN
          TEXT12=HENTRY(1)
          CALL XABORT(NAMSBR//
     >    ': SIGNATURE OF '//TEXT12//' IS '//HSIGN//' L_COMPO EXPECTED')
        ENDIF
      ENDIF
*----
*  SCAN ENTRY FOR EDIT, BURNUP AND LIB
*----
      IPEDIT=C_NULL_PTR
      IKEDIT=0
      IPDEPL=C_NULL_PTR
      IKDEPL=0
      IPLIB=C_NULL_PTR
      IKLIB=0
      DO 100 IEN=2,NENTRY
        TEXT12=HENTRY(IEN)
        IF(JENTRY(IEN).NE.2) CALL XABORT(NAMSBR//
     >  ': DATA STRUCTURE '//TEXT12//' NOT IN READ-ONLY MODE')
        IF(IENTRY(IEN).EQ.1.OR.IENTRY(IEN).EQ.2) THEN
          CALL LCMGTC(KENTRY(IEN),'SIGNATURE',12,1,HSIGN)
          IF(HSIGN.EQ.'L_EDIT'.AND.IKEDIT.EQ.0) THEN
            IPEDIT=KENTRY(IEN)
            IKEDIT=IEN
          ELSE IF(HSIGN.EQ.'L_BURNUP'.AND.IKDEPL.EQ.0) THEN
            IPDEPL=KENTRY(IEN)
            IKDEPL=IEN
          ENDIF
        ENDIF
 100  CONTINUE
      IF(IKEDIT.EQ.0) CALL XABORT(NAMSBR//
     >': NO DATA STRUCTURE WITH SIGNATURE L_EDIT FOUND.')
      IF(IKDEPL.EQ.0) THEN
        MXBURN=1
      ELSE
        CALL LCMLEN(IPDEPL,'DEPL-TIMES',MXBURN,ITYLCM)
        IF(MXBURN.EQ.0) CALL XABORT(NAMSBR//
     >  ': NO DEPL-TIMES DIRECTORY ON BURNUP DATA STRUCTURE')
      ENDIF
      ALLOCATE(IDBS(MXBURN))
*----
*   RECOVER THE TITLE.
*----
      CALL LCMLEN(IPEDIT,'TITLE',LENGT,ITYLCM)
      IF(LENGT.GT.0) THEN
        CALL LCMGET(IPEDIT,'TITLE',CTITRE)
      ELSE
        DO 101 I=1,18
          CTITRE(I)=ITEXT4
 101    CONTINUE
      ENDIF
*----
*  GET EDIT INFORMATION FOR MEMORY ALLOCATION OF
*  NUMBER OF ISOTOPES
*----
      CALL XDISET(ISTATE,NSTATE,0)
      CALL LCMGET(IPEDIT,'STATE-VECTOR',ISTATE)
      MAXMRG=ISTATE(1)
      MAXISM=ISTATE(13)
      MAXISO=MAXMRG*MAXISM
      ALLOCATE(ISOCPO(3*MAXISO),ISOEXT(3*MAXISO),ISOORD(MAXISO))
      CALL XDISET(ISOCPO,3*MAXISO,ITEXT4)
      CALL XDISET(ISOEXT,3*MAXISO,ITEXT4)
      CALL XDISET(ISOORD,MAXISO,0)
*----
*  READ CPO DATA.
*----
      IPRINT=1
      IEXTRC=0
      NISEXT=0
      NISCPO=0
      NSBS=-1
      LBURN=.FALSE.
      LB2=.FALSE.
      ILEAKS=0
      ITRANC=1
      CURNAM='REF-CASE0001'
      NAMCPO='COMPO'
      ILOCAL=0
 110  CONTINUE
      CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
      IF(ITYPLU.EQ.10) GO TO 115
 120  CONTINUE
      IF(ITYPLU.NE.3) CALL XABORT(NAMSBR//
     >': KEYWORD EXPECTED')
      IF(CARLIR.EQ.';') THEN
        GO TO 115
      ELSE IF(CARLIR.EQ.'EDIT') THEN
        CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
        IF(ITYPLU.NE.1) CALL XABORT(NAMSBR//
     >  ': EDIT LEVEL EXPECTED')
        IPRINT=INTLIR
      ELSE IF(CARLIR.EQ.'B2') THEN
        LB2=.TRUE.
      ELSE IF(CARLIR.EQ.'STEP') THEN
        CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
        IF(ITYPLU.NE.3) CALL XABORT(NAMSBR//
     >  ': STEP NAME EXPECTED')
        CURNAM=CARLIR
        NSBS=0
      ELSE IF(CARLIR.EQ.'NOTR') THEN
        ITRANC=0
      ELSE IF(CARLIR.EQ.'GLOB') THEN
        ILOCAL=0
      ELSE IF(CARLIR.EQ.'LOCA') THEN
        ILOCAL=1
      ELSE IF(CARLIR.EQ.'BURNUP') THEN
        IF(IKDEPL.EQ.0) CALL XABORT(NAMSBR//
     >  ': A BURNUP DATA STRUCTURE IS REQUIRED ')
        LBURN=.TRUE.
        CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
        IF(ITYPLU.NE.3) CALL XABORT(NAMSBR//
     >  ': BURNUP NAME EXPECTED')
        CURNAM=CARLIR
        NSBS=MXBURN
        DO 111 IBR=1,NSBS
          IDBS(IBR)=IBR
 111    CONTINUE
      ELSE IF(CARLIR.EQ.'EXTRACT') THEN
        CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
        IF(ITYPLU.NE.3) CALL XABORT(NAMSBR//
     >  ': ISOTOPE EXTRACTION NAME EXPECTED')
        IF(CARLIR.EQ.'ALL') THEN
*----
*  FOR EXTRACT ALL, RECOVER ISOTOPE NAMES FROM EDIT STRUCTURE
*----
          IEXTRC=2
          NISEXT=MAXISO
          NISCPO=MAXISO
        ELSE
          IEXTRC=1
          NISCPO=NISCPO+1
          IF(NISCPO.GT.MAXISO) CALL XABORT(NAMSBR//
     >    ': TOO MANY EXTRACTION ISOTOPES')
          READ(CARLIR,'(3A4)') (ISOCPO(I),I=3*(NISCPO-1)+1,3*NISCPO)
 130      CONTINUE
          CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
          IF(ITYPLU.NE.3) CALL XABORT(NAMSBR//
     >    ': ISOTOPE NAME TO EXTRACT EXPECTED')
          IF((CARLIR.EQ.'EXTRACT').OR.(CARLIR.EQ.'EXPORT').OR.
     >       (CARLIR.EQ.'NAME')   .OR.(CARLIR.EQ.'ESBS')  .OR.
     >       (CARLIR.EQ.';')) GO TO 120
          NISEXT=NISEXT+1
          IF(NISEXT.GT.MAXISO) CALL XABORT(NAMSBR//
     >    ': TOO MANY ISOTOPES TO EXTRACT')
          READ(CARLIR,'(3A4)') (ISOEXT(I),I=3*(NISEXT-1)+1,3*NISEXT)
          ISOORD(NISEXT)=NISCPO
          GO TO 130
        ENDIF
      ELSE IF(CARLIR.EQ.'ESBS') THEN
        IF(.NOT.LBURN) CALL XABORT(NAMSBR//
     >  ': OPTION ESBS VALID ONLY WITH BURNUP OPTION.')
        CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
        IF(ITYPLU.NE.3) CALL XABORT(NAMSBR//
     >  ': KEYWORD FOLLOWING ESBS MISSING')
        IF(CARLIR.EQ.'NBUR') THEN
          CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
          IF(ITYPLU.NE.1) CALL XABORT(NAMSBR//
     >    ': INTEGER EXPECTED(2).')
          NSBS=INTLIR
          IPBR=0
          NOLD=0
          DO 112 IBR=1,NSBS
            CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
            IF(ITYPLU.NE.1) CALL XABORT(NAMSBR//
     >      ': INTEGER  EXPECTED(3).')
            IF(INTLIR.GT.MXBURN.OR.INTLIR.LT.1) THEN
              WRITE(IOUT,7000) NAMSBR,INTLIR,MXBURN
            ELSE IF(INTLIR.LE.NOLD) THEN
              WRITE(IOUT,7001) NAMSBR,NOLD,INTLIR
            ELSE
              IDBS(IPBR+1)=INTLIR
              NOLD=INTLIR
              IPBR=IPBR+1
            ENDIF
 112      CONTINUE
          NSBS=IPBR
        ELSE
          CALL XABORT(NAMSBR//': NBUR KEY WORD EXPECTED.')
        ENDIF
      ELSE IF(CARLIR.EQ.'NAME') THEN
        CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
        IF(ITYPLU.NE.3) CALL XABORT(NAMSBR//
     >  ': CPO NAME EXPECTED')
        NAMCPO=CARLIR(:8)
      ELSE
        CALL XABORT(NAMSBR//
     >  ': '//CARLIR//' IS AN INVALID KEY WORD.')
      ENDIF
      GO TO 110
*----
*  CREATE THE COMPO
*----
 115  CONTINUE
      IF(LBURN) THEN
        WRITE(CDIRO,'(A8,I4.4)') CURNAM(1:8),IDBS(1)
      ELSE
        CDIRO=CURNAM
      ENDIF
      CALL LCMLEN(IPEDIT,CDIRO,ILCMLN,ITYLCM)
      IF(ILCMLN.EQ.0) THEN
        CALL LCMLIB(IPEDIT)
        CALL XABORT(NAMSBR//': MISSING '//CDIRO//' DIRECTORY')
      ENDIF
      CALL LCMSIX(IPEDIT,CDIRO,1)
      CALL LCMSIX(IPEDIT,'MACROLIB',1)
      CALL XDISET(ISTATE,NSTATE,0)
      CALL LCMGET(IPEDIT,'STATE-VECTOR',ISTATE)
      NGCOND=ISTATE(1)
      NMERGE=ISTATE(2)
      NL=ISTATE(3)
      NIFISS=ISTATE(4)
      NEDMAC=ISTATE(5)
      IF(ITRANC.EQ.1) THEN
        ITRANC=ISTATE(6)
      ENDIF
      IF((ITRANC.EQ.1).AND.(IPRINT.GT.0)) THEN
        WRITE(IOUT,6020)
      ENDIF
      ILEAKS=ISTATE(9)
      IF(LB2.AND.ILEAKS.EQ.0) CALL XABORT(NAMSBR//
     >': MISSING B2 INFO.')
      ALLOCATE(VOLME(NMERGE),ENERG(NGCOND+1))
      CALL LCMGET(IPEDIT,'ENERGY',ENERG)
      CALL LCMGET(IPEDIT,'VOLUME',VOLME)
      IF(NEDMAC.GT.0) THEN
        CALL LCMGTC(IPEDIT,'ADDXSNAME-P0',8,NEDMAC,HVECT)
      ENDIF
      CALL LCMSIX(IPEDIT,' ',2)
      IF(IPRINT.GE.1) THEN
        IF(ILEAKS.EQ.1) THEN
          WRITE(IOUT,6000) NAMSBR,CURNAM,NGCOND,NMERGE,NSBS,
     >                     NL,ILEAKS
        ELSE IF(ILEAKS.EQ.2) THEN
          WRITE(IOUT,6000) NAMSBR,CURNAM,NGCOND,NMERGE,NSBS,
     >                     NL,ILEAKS
        ELSE
          WRITE(IOUT,6000) NAMSBR,CURNAM,NGCOND,NMERGE,NSBS,
     >                     NL,ILEAKS
        ENDIF
      ENDIF
*----
*  PREPARE ISOTOPES
*----
      CALL LCMLEN(IPEDIT,'ISOTOPESMIX',NBMICR,ITYLCM)
      ALLOCATE(NBIMRG(NMERGE))
      IF(IEXTRC.GE.1.AND.NBMICR.GT.0) THEN
        NXXXZ=MAX(NBMICR,1)
        ALLOCATE(IDIMIX(NMERGE*NXXXZ),ICOMIX(NMERGE*MAXISM),
     >  ISOTMP(3*NXXXZ),IMXTMP(NXXXZ))
        CALL LCMGET(IPEDIT,'ISOTOPESUSED',ISOTMP)
        CALL LCMGET(IPEDIT,'ISOTOPESMIX',IMXTMP)
        CALL XDISET(IDIMIX,NMERGE*NBMICR,0)
        CALL CPOISO(IPRINT,IEXTRC,NMERGE,MAXISO,MAXISM,NBMICR,
     >              NISCPO,NISEXT,ISOCPO,ISOEXT,ISOORD,ISOTMP,
     >              IMXTMP,IDIMIX,NBIMRG,ICOMIX)
      ELSE
        NXXXZ=MAX(NBMICR,1)
        CALL XDISET(NBIMRG,NMERGE,0)
        ALLOCATE(IDIMIX(NMERGE*NXXXZ),ICOMIX(NMERGE*NXXXZ),
     >  ISOTMP(3*NXXXZ),IMXTMP(NXXXZ))
        NISCPO=0
      ENDIF
      DEALLOCATE(ISOORD,ISOEXT)
      CALL LCMSIX(IPEDIT,' ',2)
*----
*  TEST IF OTHER BURNUP STEP CONSISTENT WITH FIRST BURNUP STEP
*----
      DO 160 IBURN=2,NSBS
        WRITE(CDIRO,'(A8,I4.4)') CURNAM(1:8),IDBS(IBURN)
        CALL LCMLEN(IPEDIT,CDIRO,ILCMLN,ITYLCM)
        IF(ILCMLN.EQ.0) THEN
          WRITE(IOUT,7002) NAMSBR,CDIRO
          IDBS(IBURN)=0
        ELSE
          CALL LCMSIX(IPEDIT,CDIRO,1)
          CALL LCMSIX(IPEDIT,'MACROLIB',1)
          CALL XDISET(ISTATM,NSTATE,0)
          CALL LCMGET(IPEDIT,'STATE-VECTOR',ISTATM)
          CALL LCMSIX(IPEDIT,'MACROLIB',2)
          CALL LCMSIX(IPEDIT,CDIRO,2)
          DO 170 IST=1,NSTATE
            IF(ISTATE(IST).NE.ISTATM(IST)) THEN
             WRITE(IOUT,7003) NAMSBR,CURNAM(1:8),IDBS,CDIRO
              IDBS(IBURN)=0
              GO TO 175
            ENDIF
 170      CONTINUE
 175      CONTINUE
        ENDIF
 160  CONTINUE
      ALLOCATE(TIME(MXBURN),BURN(MXBURN),WIR(MXBURN))
      IF(LBURN) THEN
        CALL LCMGET(IPDEPL,'DEPL-TIMES',TIME)
      ELSE
        TIME=0.0
      ENDIF
*----
*  CALL CPODRV
*----
      NPROC=NDPROC+NL+1
      CALL CPODRV(IPCPO ,IPEDIT,IPDEPL,IPRINT,CURNAM,CTITRE,
     >            NAMCPO,NGCOND,NMERGE,NBMICR,NIFISS,MXBURN,
     >            NL    ,NISCPO,NPROC ,ILEAKS,NXXXZ ,NEDMAC,
     >            HVECT ,NSBS  ,ILOCAL,ISOCPO,ISOTMP,IDIMIX,
     >            NBIMRG,ICOMIX,VOLME, ENERG ,TIME  ,BURN  ,
     >            WIR   ,IDBS  )
*----
*  RELEASE MAIN MEMORY
*----
      DEALLOCATE(WIR,BURN,TIME,IMXTMP,ISOTMP,ICOMIX,NBIMRG,IDIMIX,
     > ENERG,VOLME,ISOCPO,IDBS)
      RETURN
*----
*  PRINT FORMAT
*----
 6000 FORMAT(1X,A6,
     >     ': RECOVER INFORMATION FROM DIRECTORY = ',A12/
     > 10X,'             NUMBER OF GROUPS  =',I5/
     > 10X,'             NUMBER OF COMPOS  =',I5/
     > 10X,'             NUMBER OF BURNUPS =',I5/
     > 10X,'             LEGENDRE ORDERS   =',I5/
     > 10X,'             LEAKAGE OPTION    =',I5)
 6020 FORMAT(' TRANSPORT CORRECTED CROSS SECTIONS')
*----
*  WARNING FORMAT
*----
 7000 FORMAT(1X,A6,': ****** WARNING ******'/
     >       ' ILLEGAL BURNUP STEP NUMBER'/
     >       ' CURRENT BURNUP STEP - SKIPPED     = ',I10/
     >       ' NUMBER OF BURNUP STEP AVAILABLE   = ',I10/
     >       ' **************************')
 7001 FORMAT(1X,A6,': ****** WARNING ******'/
     >       ' BURNUP STEPS MUST BE ORDERED INCREASINGLY '/
     >       ' PREVIOUS BURNUP STEP REQUESTED    = ',I10/
     >       ' CURRENT BURNUP STEP - SKIPPED     = ',I10/
     >       ' **************************')
 7002 FORMAT(1X,A6,': ****** WARNING ******'/
     >       ' BURNUP STEP DOES NOT EXISTS '/
     >       ' CURRENT BURNUP STEP - SKIPPED     = ',A12/
     >       ' **************************')
 7003 FORMAT(1X,A6,': ****** WARNING ******'/
     >       ' INCONSISTENT BURNUP STEP '/
     >       ' REFERENCE BURNUP STEP             = ',A8,I4.4/
     >       ' CURRENT BURNUP STEP - SKIPPED     = ',A12/
     >       ' **************************')
      END
