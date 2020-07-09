*DECK MACXSI
      SUBROUTINE MACXSI (IPLIST,IND,NMIXT,NGRP,NDG,NL,IMPX,NBMIX,JND)
*
*-----------------------------------------------------------------------
*
*Purpose:
* input macroscopic cross sections in Trivac.
*
*Copyright:
* Copyright (C) 2007 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* IPLIST  LCM pointer to the macrolib.
* IND     =1: the macrolib is created;
*         =2: an existing macrolib is modified.
* NMIXT   maximum number of material mixtures.
* NGRP    number of energy groups.
* NDG     number of delayed precursor groups.
* NL      number of Legendre orders (=1 for isotropic scattering).
* IMPX    print level.
*
*Parameters: output
* NBMIX   number of mixtures.
* JND     REDGET flag (=1 ';' encountered; =2 'STEP' encountered).
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPLIST
      INTEGER IND,NMIXT,NGRP,NDG,NL,IMPX,NBMIX,JND
*----
*  LOCAL VARIABLES
*----
      LOGICAL LTO,LFI,LCH,LOV,LD,LDX,LDY,LDZ,LHF,LSC,LSO,LDI,LBI
      DOUBLE PRECISION DFLOTT
      CHARACTER CM*2,TEXT4*4,TEXT8*8,TEXT*8
      TYPE(C_PTR) JPLIST,KPLIST
      REAL, DIMENSION(:), ALLOCATABLE :: WORK
      REAL, DIMENSION(:,:), ALLOCATABLE :: TOTAL,ZNUG,CHI,OVERV,DIFFX,
     1 DIFFY,DIFFZ,H,S
      REAL, DIMENSION(:,:,:), ALLOCATABLE :: NUSDL,CHDL
      REAL, DIMENSION(:,:,:,:), ALLOCATABLE :: SCAT
      INTEGER, DIMENSION(:), ALLOCATABLE :: IPOS
      INTEGER, DIMENSION(:,:,:), ALLOCATABLE :: IJJ,NJJ
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(TOTAL(NMIXT,NGRP),ZNUG(NMIXT,NGRP),CHI(NMIXT,NGRP),
     1 NUSDL(NMIXT,NDG,NGRP),CHDL(NMIXT,NDG,NGRP),OVERV(NMIXT,NGRP),
     2 DIFFX(NMIXT,NGRP),DIFFY(NMIXT,NGRP),DIFFZ(NMIXT,NGRP),
     3 H(NMIXT,NGRP),S(NMIXT,NGRP),SCAT(NMIXT,NL,NGRP,NGRP),
     4 WORK(NMIXT*NGRP))
      ALLOCATE(IJJ(NMIXT,NL,NGRP),NJJ(NMIXT,NL,NGRP),IPOS(NMIXT))
*
      IF(NMIXT.EQ.0) CALL XABORT('MACXSI: ZERO NUMBER OF MIXTURES.')
      IF(NGRP.EQ.0) CALL XABORT('MACXSI: ZERO NUMBER OF GROUPS.')
      NBMIX=0
      LTO=.FALSE.
      LFI=.FALSE.
      LCH=.FALSE.
      LOV=.FALSE.
      LD=.FALSE.
      LDX=.FALSE.
      LDY=.FALSE.
      LDZ=.FALSE.
      LHF=.FALSE.
      LSC=.FALSE.
      LSO=.FALSE.
      LDI=.FALSE.
      LBI=.FALSE.
      DO 13 IGR=1,NGRP
      DO 12 IBM=1,NMIXT
      TOTAL(IBM,IGR)=0.0
      ZNUG(IBM,IGR)=0.0
      CHI(IBM,IGR)=0.0
      DIFFX(IBM,IGR)=0.0
      DIFFY(IBM,IGR)=0.0
      DIFFZ(IBM,IGR)=0.0
      H(IBM,IGR)=0.0
      S(IBM,IGR)=0.0
      DO 11 IL=1,NL
      IJJ(IBM,IL,IGR)=IGR
      NJJ(IBM,IL,IGR)=1
      DO 10 JGR=1,NGRP
      SCAT(IBM,IL,JGR,IGR)=0.0
   10 CONTINUE
   11 CONTINUE
   12 CONTINUE
   13 CONTINUE
      IF(IND.EQ.2) THEN
*        RECOVER THE EXISTING MACROLIB DATA.
         JPLIST=LCMLID(IPLIST,'GROUP',NGRP)
         DO 40 JGR=1,NGRP
         KPLIST=LCMDIL(JPLIST,JGR)
         CALL LCMLEN(KPLIST,'NTOT0',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) THEN
            CALL LCMGET(KPLIST,'NTOT0',TOTAL(1,JGR))
         ELSE IF(ILENGT.NE.0) THEN
            CALL XABORT('MACXSI: INVALID INPUT MACROLIB(1).')
         ENDIF
         CALL LCMLEN(KPLIST,'NUSIGF',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'NUSIGF',ZNUG(1,JGR))
         CALL LCMLEN(KPLIST,'CHI',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'CHI',CHI(1,JGR))
         DO 900 I=1,NDG
         WRITE(TEXT,'(A6,I2.2)') 'NUSIGF',I
         CALL LCMLEN(KPLIST,TEXT,ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,TEXT,NUSDL(1,I,JGR))
         WRITE(TEXT,'(A3,I2.2)') 'CHI',I
         CALL LCMLEN(KPLIST,TEXT,ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,TEXT,CHDL(1,I,JGR))
 900     CONTINUE        
         CALL LCMLEN(KPLIST,'OVERV',ILENGT,ITYLCM)         
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'OVERV',OVERV(1,JGR))
         CALL LCMLEN(KPLIST,'DIFF',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'DIFF',DIFFX(1,JGR))
         CALL LCMLEN(KPLIST,'DIFFX',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'DIFFX',DIFFX(1,JGR))
         CALL LCMLEN(KPLIST,'DIFFY',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'DIFFY',DIFFY(1,JGR))
         CALL LCMLEN(KPLIST,'DIFFZ',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'DIFFZ',DIFFZ(1,JGR))
         CALL LCMLEN(KPLIST,'H-FACTOR',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'H-FACTOR',H(1,JGR))
         CALL LCMLEN(KPLIST,'FIXE',ILENGT,ITYLCM)
         IF(ILENGT.EQ.NMIXT) CALL LCMGET(KPLIST,'FIXE',S(1,JGR))
         DO 30 IL=1,NL
         WRITE (CM,'(I2.2)') IL-1
         CALL LCMLEN(KPLIST,'SCAT'//CM,ILENGT,ITYLCM)
         IF(ILENGT.GT.NMIXT*NL*NGRP*NGRP) THEN
            CALL XABORT('MACXSI: INVALID INPUT MACROLIB(2).')
         ELSE IF(ILENGT.GT.0) THEN
            CALL LCMGET(KPLIST,'SCAT'//CM,WORK)
            CALL LCMGET(KPLIST,'NJJS'//CM,NJJ(1,IL,JGR))
            CALL LCMGET(KPLIST,'IJJS'//CM,IJJ(1,IL,JGR))
            IPOSDE=0
            DO 25 IBM=1,NMIXT
            IJJ0=IJJ(IBM,IL,JGR)
            DO 20 IGR=IJJ0,IJJ0-NJJ(IBM,IL,JGR)+1,-1
            IPOSDE=IPOSDE+1
            SCAT(IBM,IL,IGR,JGR)=WORK(IPOSDE)
   20       CONTINUE
   25       CONTINUE
         ENDIF
   30    CONTINUE
   40    CONTINUE
      ENDIF
*
   50 CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
      IF(INDIC.NE.3) CALL XABORT('MACXSI: CHARACTER DATA EXPECTED(1).')
      IF(TEXT4.EQ.'MIX') THEN
   60    CALL REDGET(INDIC,IBM,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('MACXSI: INTEGER DATA EXPECTED.')
         IF(IBM.GT.NMIXT) CALL XABORT('MACXSI: INVALID MIX INDEX.')
         NBMIX=MAX(NBMIX,IBM)
   70    CALL REDGET(INDIC,NITMA,FLOTT,TEXT8,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('MACXSI: CHARACTER DATA EXPECTED.')
         IF((TEXT8.EQ.'TOTAL').OR.(TEXT8.EQ.'NTOT0')) THEN
            LTO=.TRUE.
            DO 80 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,TOTAL(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
   80       CONTINUE
         ELSE IF(TEXT8.EQ.'NUSIGF') THEN
            LFI=.TRUE.
            DO 90 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,ZNUG(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
   90       CONTINUE
         ELSE IF(TEXT8.EQ.'CHI') THEN
            LCH=.TRUE.
            DO 95 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,CHI(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
   95       CONTINUE
         ELSE IF(TEXT8.EQ.'NUSIGD') THEN
            LDI=.TRUE.
            DO 896 I=1,NDG
            DO 895 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,NUSDL(IBM,I,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  895       CONTINUE
  896       CONTINUE
         ELSE IF(TEXT8.EQ.'CHDL') THEN
            LBI=.TRUE.
            DO 996 I=1,NDG
            DO 995 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,CHDL(IBM,I,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  995       CONTINUE
  996       CONTINUE
         ELSE IF(TEXT8.EQ.'OVERV') THEN
            LOV=.TRUE.
            DO 96 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,OVERV(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
            IF(OVERV(IBM,IGR).EQ.0.) CALL XABORT('MACXSI: INVALID VELO'
     1      //'CITY VALUE.')
   96       CONTINUE
         ELSE IF(TEXT8.EQ.'DIFF') THEN
            LD=.TRUE.
            DO 97 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,DIFFX(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
   97       CONTINUE
         ELSE IF(TEXT8.EQ.'DIFFX') THEN
            LDX=.TRUE.
            DO 100 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,DIFFX(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  100       CONTINUE
         ELSE IF(TEXT8.EQ.'DIFFY') THEN
            LDY=.TRUE.
            DO 110 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,DIFFY(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  110       CONTINUE
         ELSE IF(TEXT8.EQ.'DIFFZ') THEN
            LDZ=.TRUE.
            DO 120 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,DIFFZ(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  120       CONTINUE
         ELSE IF(TEXT8.EQ.'H-FACTOR') THEN
            LHF=.TRUE.
            DO 130 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,H(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  130       CONTINUE
         ELSE IF(TEXT8.EQ.'SCAT') THEN
            LSC=.TRUE.
            DO 142 IL=1,NL
            DO 141 JGR=1,NGRP
            CALL REDGET(INDIC,NJJ(IBM,IL,JGR),FLOTT,TEXT4,DFLOTT)
            IF(INDIC.NE.1) CALL XABORT('MACXSI: INTEGER DATA EXPECTED.')
            CALL REDGET(INDIC,IJJ(IBM,IL,JGR),FLOTT,TEXT4,DFLOTT)
            IF(INDIC.NE.1) CALL XABORT('MACXSI: INTEGER DATA EXPECTED.')
            IJJ0=IJJ(IBM,IL,JGR)
            DO 140 IGR=IJJ0,IJJ0-NJJ(IBM,IL,JGR)+1,-1
*           SCAT(MIXTURE,LEGENDRE,PRIMARY,SECONDARY)
            CALL REDGET(INDIC,NITMA,SCAT(IBM,IL,IGR,JGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  140       CONTINUE
  141       CONTINUE
  142       CONTINUE
         ELSE IF(TEXT8.EQ.'FIXE') THEN
            LSO=.TRUE.
            DO 150 IGR=1,NGRP
            CALL REDGET(INDIC,NITMA,S(IBM,IGR),TEXT4,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('MACXSI: REAL DATA EXPECTED.')
  150       CONTINUE
         ELSE IF(TEXT8.EQ.'MIX') THEN
            GO TO 60
         ELSE IF(TEXT8.EQ.';') THEN
            JND=1
            GO TO 160
         ELSE IF(TEXT8.EQ.'STEP') THEN
            JND=2
            GO TO 160
         ELSE
            CALL XABORT('MACXSI: INVALID KEY-WORD(1).')
         ENDIF
         GO TO 70
      ELSE
         CALL XABORT('MACXSI: INVALID KEY-WORD(2).')
      ENDIF
      GO TO 50
*
  160 JPLIST=LCMLID(IPLIST,'GROUP',NGRP)
      DO 210 JGR=1,NGRP
      KPLIST=LCMDIL(JPLIST,JGR)
      IF(LTO) CALL LCMPUT(KPLIST,'NTOT0',NMIXT,2,TOTAL(1,JGR))
      IF(LFI) CALL LCMPUT(KPLIST,'NUSIGF',NMIXT,2,ZNUG(1,JGR))
      IF(LCH) CALL LCMPUT(KPLIST,'CHI',NMIXT,2,CHI(1,JGR))
      IF(LOV) CALL LCMPUT(KPLIST,'OVERV',NMIXT,2,OVERV(1,JGR))
      IF(LD) THEN
         CALL LCMPUT(KPLIST,'DIFF',NMIXT,2,DIFFX(1,JGR))
      ELSE
         IF(LDX) CALL LCMPUT(KPLIST,'DIFFX',NMIXT,2,DIFFX(1,JGR))
         IF(LDY) CALL LCMPUT(KPLIST,'DIFFY',NMIXT,2,DIFFY(1,JGR))
         IF(LDZ) CALL LCMPUT(KPLIST,'DIFFZ',NMIXT,2,DIFFZ(1,JGR))
      ENDIF
      IF(LHF) CALL LCMPUT(KPLIST,'H-FACTOR',NMIXT,2,H(1,JGR))
      IF(LSO) CALL LCMPUT(KPLIST,'FIXE',NMIXT,2,S(1,JGR))
      IF(LDI) THEN
         DO 170 I=1,NDG
         WRITE(TEXT,'(A6,I2.2)') 'NUSIGF',I
         CALL LCMPUT(KPLIST,TEXT,NMIXT,2,NUSDL(1,I,JGR))
  170    CONTINUE     
      ENDIF
      IF(LBI) THEN
         DO 180 I=1,NDG
         WRITE(TEXT,'(A3,I2.2)') 'CHI',I
         CALL LCMPUT(KPLIST,TEXT,NMIXT,2,CHDL(1,I,JGR))
  180    CONTINUE     
      ENDIF
      IF(LSC) THEN
         DO 200 IL=1,NL
         WRITE (CM,'(I2.2)') IL-1
         IPOSDE=0
         DO 195 IBM=1,NMIXT
         J2=JGR
         J1=JGR
         DO 185 IGR=1,NGRP
         IF(SCAT(IBM,IL,IGR,JGR).NE.0.0) THEN
           J2=MAX(J2,IGR)
           J1=MIN(J1,IGR)
         ENDIF
  185    CONTINUE
         NJJ(IBM,IL,JGR)=J2-J1+1
         IJJ(IBM,IL,JGR)=J2
         IPOS(IBM)=IPOSDE+1
         DO 190 IGR=IJJ(IBM,IL,JGR),IJJ(IBM,IL,JGR)-NJJ(IBM,IL,JGR)+1,-1
         IPOSDE=IPOSDE+1
         WORK(IPOSDE)=SCAT(IBM,IL,IGR,JGR)
  190    CONTINUE
  195    CONTINUE
         CALL LCMPUT(KPLIST,'SCAT'//CM,IPOSDE,2,WORK)
         CALL LCMPUT(KPLIST,'IPOS'//CM,NMIXT,1,IPOS)
         CALL LCMPUT(KPLIST,'NJJS'//CM,NMIXT,1,NJJ(1,IL,JGR))
         CALL LCMPUT(KPLIST,'IJJS'//CM,NMIXT,1,IJJ(1,IL,JGR))
         CALL LCMPUT(KPLIST,'SIGW'//CM,NMIXT,2,SCAT(1,IL,JGR,JGR))
  200    CONTINUE
      ENDIF
      IF(IMPX.GT.1) CALL LCMLIB(KPLIST)
  210 CONTINUE
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(TOTAL,ZNUG,CHI,NUSDL,CHDL,OVERV,DIFFX,DIFFY,DIFFZ,H,S,
     1 SCAT,WORK)
      DEALLOCATE(IJJ,NJJ,IPOS)
      RETURN
      END
