*DECK SAPCAT
      SUBROUTINE SAPCAT(IPSAP,IPRHS,NORIG,NPARN,MUPCPO,LGNCPO,LWARN)
*
*-----------------------------------------------------------------------
*
*Purpose:
* catenate a RHS saphyb into the output saphyb.
*
*Copyright:
* Copyright (C) 2008 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* IPSAP   pointer to the output saphyb.
* IPRHS   pointer to the rhs saphyb (contains the new calculations).
* NORIG   index of the elementary calculation associated to the
*         father node in the parameter tree.
* NPARN   number of global parameters in the output saphyb.
* MUPCPO  tuple of the new global parameters in the output saphyb.
* LGNCPO  LGNEW value of the new global parameters in the output
*         saphyb.
* LWARN   logical used in case if an elementary calculation in the RHS
*         is already present in saphyb. If LWARN=.true. a warning is
*         send and the saphyb values are kept, otherwise XABORT is
*         called (default).
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPSAP,IPRHS
      INTEGER NORIG,NPARN,MUPCPO(NPARN)
      LOGICAL LGNCPO(NPARN),LWARN
*----
*  LOCAL VARIABLES
*----
      PARAMETER (NDIMSA=50,MAXPAR=50,MAXVAL=1000)
      INTEGER IDATA(NDIMSA),NVALUE(2*MAXPAR),MUPLET(2*MAXPAR),
     1 MUPRHS(2*MAXPAR)
      CHARACTER HSMG*131,RECNAM*12,TEXT4*4,TEXT12*12,PARFMT(MAXPAR)*8,
     1 VCHAR(MAXVAL)*12,PARKEY(MAXPAR)*4,PARCPO(MAXPAR)*4,DIRNAM*12
      LOGICAL COMTRE,LGERR,LGNEW(MAXPAR)
*----
*  ALLOCATABLE ARRAYS
*----
      INTEGER, ALLOCATABLE, DIMENSION(:) :: MUOLD,IORRHS,JDEBAR,JARBVA,
     1 VINTE,IDEBAR,IARBVA,IORIGI
      REAL, ALLOCATABLE, DIMENSION(:) :: VREAL
      LOGICAL, ALLOCATABLE, DIMENSION(:) :: LGOLD
*
      CALL LCMGET(IPRHS,'DIMSAP',IDATA)
      NMIL=IDATA(7)
      NPAR=IDATA(8)
      NLOC=IDATA(11)
      NVPR=IDATA(17) ! number of nodes in RHS
      NCALR=IDATA(19) ! number of calculations in RHS
      NG=IDATA(20)
      IF(NCALR.EQ.0) CALL XABORT('SAPCAT: NO CALCULATION IN RHS SAPHYB'
     1 //'.')
*
      CALL LCMGET(IPSAP,'DIMSAP',IDATA)
      NVPO=IDATA(17) ! initial number of nodes in LHS SAPHYB
      NCAL=IDATA(19) ! initial number of calculations in LHS SAPHYB
      IF(NPARN.GT.MAXPAR) CALL XABORT('SAPCAT: MAXPAR OVERFLOW.')
      IF(NCAL.EQ.0) THEN
*        COMPLETE STATE-VECTOR.
         IF(IDATA(7).EQ.0) THEN
            IDATA(7)=NMIL
         ELSE IF(NMIL.NE.IDATA(7)) THEN
            WRITE(HSMG,'(42HSAPCAT: ELEMENTARY CALCULATION WITH AN INV,
     1      22HALIB NB. OF MIXTURES =,I7,3H NE,I7,1H.)') NMIL,IDATA(7)
            CALL XABORT(HSMG)
         ENDIF
         IDATA(20)=NG
      ELSE
         IF(NMIL.NE.IDATA(7)) THEN
            WRITE(HSMG,'(42HSAPCAT: ELEMENTARY CALCULATION WITH AN INV,
     1      22HALIB NB. OF MIXTURES =,I7,3H NE,I7,1H.)') NMIL,IDATA(7)
            CALL XABORT(HSMG)
         ELSE IF(NG.NE.IDATA(20)) THEN
            WRITE(HSMG,'(42HSAPCAT: ELEMENTARY CALCULATION WITH AN INV,
     1      20HALIB NB. OF GROUPS =,I7,3H NE,I7,1H.)') NG,IDATA(20)
            CALL XABORT(HSMG)
         ENDIF
      ENDIF
      IF(NPAR.GT.NPARN) THEN
         WRITE(HSMG,'(42HSAPCAT: ELEMENTARY CALCULATION WITH AN INV,
     1   31HALIB NB. OF GLOBAL PARAMETERS =,I7,3H NE,I7,1H.)') NPAR,
     2   NPARN
         CALL XABORT(HSMG)
      ELSE IF(NLOC.NE.IDATA(11)) THEN
         WRITE(HSMG,'(42HSAPCAT: ELEMENTARY CALCULATION WITH AN INV,
     1   30HALIB NB. OF LOCAL PARAMETERS =,I7,3H NE,I7,1H.)') NLOC,
     2   IDATA(11)
         CALL XABORT(HSMG)
      ENDIF
*----
*  ADJUST THE SIZE OF THE OUTPUT SAPHYB AND UPDATE THE STATE-VECTOR
*----
      IDATA(19)=IDATA(19)+NCALR
      CALL LCMPUT(IPSAP,'DIMSAP',NDIMSA,1,IDATA)
*----
*  MAIN LOOP OVER THE NCALR ELEMENTARY CALCULATIONS OF THE RHS SAPHYB
*----
      ALLOCATE(MUOLD(NCALR*NPARN),LGOLD(NCALR*NPARN))
      NIDEM=0
      NCALS=NCAL
      DO 170 ICAL=1,NCALR
*----
*  COMPUTE THE MUPLET VECTOR FROM THE RHS SAPHYB
*----
      CALL LCMSIX(IPRHS,'paramarbre',1)
      CALL LCMLEN(IPRHS,'ARBVAL',MAXNVP,ITYLCM)
      CALL LCMLEN(IPRHS,'ORIGIN',MAXNCA,ITYLCM)
      ALLOCATE(IORRHS(MAXNCA))
      CALL LCMGET(IPRHS,'ORIGIN',IORRHS)
      ALLOCATE(JDEBAR(MAXNVP+1),JARBVA(MAXNVP))
      CALL LCMGET(IPRHS,'DEBARB',JDEBAR)
      CALL LCMGET(IPRHS,'ARBVAL',JARBVA)
      CALL LCMSIX(IPRHS,' ',2)
      DO 30 I=NVPR-NCALR+1,NVPR
      IF(JDEBAR(I+1).EQ.ICAL) THEN
         I0=I
         GO TO 40
      ENDIF
   30 CONTINUE
      CALL XABORT('SAPCAT: MUPLET ALGORITHM FAILURE 1.')
   40 MUPRHS(NPAR)=JARBVA(I0)
      DO 60 IPAR=NPAR-1,1,-1
      DO 50 I=1,NVPR-NCALR
      IF(JDEBAR(I+1).GT.I0) THEN
         I0=I
         GO TO 60
      ENDIF
   50 ENDDO
      CALL XABORT('SAPCAT: MUPLET ALGORITHM FAILURE 2.')
   60 MUPRHS(IPAR)=JARBVA(I0)
      DEALLOCATE(JARBVA,JDEBAR)
*----
*  RECOVER THE GLOBAL PARAMETERS
*----
      DO 70 I=1,NPARN
      MUPLET(I)=MUPCPO(I)
   70 LGNEW(I)=LGNCPO(I)
      CALL LCMSIX(IPSAP,'paramdescrip',1)
      CALL LCMGTC(IPSAP,'PARKEY',4,NPARN,PARCPO)
      CALL LCMSIX(IPSAP,' ',2)
      CALL LCMSIX(IPRHS,'paramdescrip',1)
      CALL LCMGTC(IPRHS,'PARKEY',4,NPAR,PARKEY)
      CALL LCMGTC(IPRHS,'PARFMT',8,NPAR,PARFMT)
      CALL LCMGET(IPRHS,'NVALUE',NVALUE)
      CALL LCMSIX(IPRHS,' ',2)
      DO 100 IPAR=1,NPAR
         DO 80 I0=1,NPARN
         IF(PARKEY(IPAR).EQ.PARCPO(I0)) THEN
            IPARN=I0
            GO TO 90
         ENDIF
   80    CONTINUE
         CALL XABORT('SAPCAT: UNABLE TO FIND '//PARKEY(IPAR)//'.')
   90    WRITE(RECNAM,'(''pval'',I8)') IPAR
         IVAL=MUPRHS(IPAR)
         CALL LCMSIX(IPRHS,'paramvaleurs',1)
         IF(PARFMT(IPAR).EQ.'FLOTTANT') THEN
            ALLOCATE(VREAL(NVALUE(IPAR)))
            CALL LCMGET(IPRHS,RECNAM,VREAL)
            FLOTT=VREAL(IVAL)
            DEALLOCATE(VREAL)
         ELSE IF(PARFMT(IPAR).EQ.'ENTIER') THEN
            ALLOCATE(VINTE(NVALUE(IPAR)))
            CALL LCMGET(IPRHS,RECNAM,VINTE)
            NITMA=VINTE(IVAL)
            DEALLOCATE(VINTE)
         ELSE IF(PARFMT(IPAR).EQ.'CHAINE') THEN
            IF(NVALUE(IPAR).GT.MAXVAL) CALL XABORT('SAPCAT: MAXVAL OVE'
     1      //'RFLOW.')
            CALL LCMGTC(IPRHS,RECNAM,12,NVALUE(IPAR),VCHAR)
            TEXT12=VCHAR(IVAL)
         ENDIF
         CALL LCMSIX(IPRHS,' ',2)
         CALL SAPPAV(IPSAP,IPARN,NPARN,PARFMT(IPAR),FLOTT,NITMA,TEXT12,
     1   MUPLET(IPARN),LGNEW(IPARN))
  100 CONTINUE
      DO 110 IPARN=1,NPARN
      MUOLD((ICAL-1)*NPARN+IPARN)=MUPLET(IPARN)
  110 LGOLD((ICAL-1)*NPARN+IPARN)=LGNEW(IPARN)
*----
*  UPDATE THE PARAMETER TREE IN THE OUTPUT SAPHYB
*----
      CALL LCMSIX(IPSAP,'paramarbre',1)
      CALL LCMLEN(IPSAP,'ARBVAL',ILONG,ITYLCM)
      IF(ILONG.EQ.0) THEN
         MAXNVP=20*(NPARN+1)
         ALLOCATE(IDEBAR(MAXNVP+1),IARBVA(MAXNVP))
         CALL XDISET(IDEBAR,MAXNVP+1,0)
         CALL XDISET(IARBVA,MAXNVP,0)
         IARBVA=0
         DO 140 I=1,NPARN
         IDEBAR(I)=I+1
  140    IARBVA(I+1)=1
         IDEBAR(NPARN+1)=NPARN+2
         IDEBAR(NPARN+2)=1
         NCALS=1
         NVPNEW=NPARN+1
      ELSE
         CALL LCMLEN(IPSAP,'ARBVAL',JLONG,ITYLCM)
         ALLOCATE(JDEBAR(JLONG+1),JARBVA(JLONG))
         CALL LCMGET(IPSAP,'DEBARB',JDEBAR)
         CALL LCMGET(IPSAP,'ARBVAL',JARBVA)
         DO 150 IPAR=1,NPARN
         IF(LGNEW(IPAR)) THEN
            II=IPAR
            GO TO 160
         ENDIF
  150    CONTINUE
         II=NPARN+1
  160    LGERR=COMTRE(NPARN,NVPO,JARBVA,JDEBAR,MUPLET,KK,I0,IORD,JJ,
     1   LAST)
         IF((II.GT.NPARN).AND.LGERR) THEN
            WRITE(TEXT4,'(I4)') IORD
            IF(LWARN) THEN
               WRITE(6,*)'SAPCAT: ELEMENTARY CALCULATION HAS THE ',
     1         'SAME PARAMETERS AS ELEMENTARY CALCULATION NB ',TEXT4
               DEALLOCATE(JARBVA,JDEBAR,IORRHS)
               CALL LCMSIX(IPSAP,' ',2)
               NIDEM=NIDEM+1
               GOTO 170
            ELSE
               CALL XABORT('SAPCAT: ELEMENTARY CALCULATION HAS THE '//
     1         'SAME PARAMETERS AS ELEMENTARY CALCULATION NB '//TEXT4)
            ENDIF
         ENDIF
*
*        Size of the new tree.
*
         NVPNEW=NVPO+NPARN+1-MIN(II,KK)
         IF(NVPNEW.GT.MAXNVP) MAXNVP=NVPNEW+MAXNVP
         ALLOCATE(IDEBAR(MAXNVP+1),IARBVA(MAXNVP))
         CALL XDISET(IDEBAR(NVPNEW+2),MAXNVP-NVPNEW,0)
         CALL XDISET(IARBVA(NVPNEW+1),MAXNVP-NVPNEW,0)
*
*        Update values and suppress old PARBRE.
*
         CALL COMARB(NPARN,NVPO,NVPNEW,JDEBAR,JARBVA,LGNEW,MUPLET,
     1   NCALS,IDEBAR,IARBVA)
         DEALLOCATE(JARBVA,JDEBAR)
      ENDIF
      IF(NCALS.NE.NCAL+ICAL-NIDEM) CALL XABORT('SAPCAT: INVALID NCALS.')
      NVPO=NVPNEW
      CALL LCMPUT(IPSAP,'NCALS',1,1,NCALS)
      CALL LCMPUT(IPSAP,'DEBARB',NVPNEW+1,1,IDEBAR)
      CALL LCMPUT(IPSAP,'ARBVAL',NVPNEW,1,IARBVA)
      DEALLOCATE(IARBVA,IDEBAR)
      IF(NCALS.EQ.1) THEN
         MAXNCA=1000
         ALLOCATE(IORIGI(MAXNCA))
         CALL XDISET(IORIGI,MAXNCA,0)
      ELSE
         CALL LCMLEN(IPSAP,'ORIGIN',MAXNCA,ITYLCM)
         IF(NCALS.GT.MAXNCA) MAXNCA=NCALS+MAXNCA
         ALLOCATE(IORIGI(MAXNCA))
         CALL XDISET(IORIGI,MAXNCA,0)
         CALL LCMGET(IPSAP,'ORIGIN',IORIGI)
      ENDIF
      IF(IORRHS(ICAL).EQ.0) THEN
         IORIGI(NCALS)=NORIG
      ELSE
         IORIGI(NCALS)=NCAL+IORRHS(ICAL)
      ENDIF
      CALL LCMPUT(IPSAP,'ORIGIN',MAXNCA,1,IORIGI)
      DEALLOCATE(IORIGI)
      CALL LCMSIX(IPSAP,' ',2)
      DEALLOCATE(IORRHS)
*----
*  RECOVER THE ELEMENTARY CALCULATION
*----
      WRITE(DIRNAM,'(''calc'',I8)') NCAL+ICAL-NIDEM
      CALL LCMSIX(IPSAP,DIRNAM,1)
      WRITE(DIRNAM,'(''calc'',I8)') ICAL
      CALL LCMSIX(IPRHS,DIRNAM,1)
      CALL LCMEQU(IPRHS,IPSAP)
      CALL LCMSIX(IPRHS,' ',2)
      CALL LCMSIX(IPSAP,' ',2)
  170 CONTINUE
* END OF LOOP ON ELEMENTARY CALCULATIONS. ********************
      DEALLOCATE(LGOLD,MUOLD)
      IDATA(17)=NVPO
      IDATA(19)=NCALS
      CALL LCMPUT(IPSAP,'DIMSAP',NDIMSA,1,IDATA)
      RETURN
      END
