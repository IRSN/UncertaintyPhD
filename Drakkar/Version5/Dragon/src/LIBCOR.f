*DECK LIBCOR
      SUBROUTINE LIBCOR (IPLIB,NGRO,ISOT,JSOT,HNAMIS1,HNAMIS2)
*
*-----------------------------------------------------------------------
*
*Purpose:
* Compute the correlation information between a pair of resonant
* isotopes.
*
*Copyright:
* Copyright (C) 2003 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* IPLIB   pointer to the internal library (L_LIBRARY signature).
* NGRO    number of energy groups.
* ISOT    position in list of the first isotope.
* JSOT    position in list of the second isotope.
* HNAMIS1 local name of the first isotope:
*         HNAMIS1(1:8)  is the local isotope name;
*         HNAMIS1(9:12) is a suffix function of the mixture index.
* HNAMIS2 local name of the second isotope
*         HNAMIS2(1:8)  is the local isotope name;
*         HNAMIS2(9:12) is a suffix function of the mixture index.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPLIB
      INTEGER NGRO,ISOT,JSOT
      CHARACTER HNAMIS1*12,HNAMIS2*12
*----
*  LOCAL VARIABLES
*----
      PARAMETER(MAXNPT=12)
      TYPE(C_PTR) JPLIB,IP1,IP2,JP1,JP2,KP1,KP2
      REAL SIGQT1(MAXNPT),SIGQT2(MAXNPT),WSLD1(MAXNPT**2),
     1 WSLD2(MAXNPT**2)
      DOUBLE PRECISION SUMA1,SUMB1,SUMA2,SUMB2
      INTEGER, ALLOCATABLE, DIMENSION(:) :: NFS1,NFS2
      REAL, ALLOCATABLE, DIMENSION(:) :: TBIN1,TBIN2,EBIN,DBIN,PROB1,
     1 PROB2
      DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:) :: COMOM
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(NFS1(NGRO),NFS2(NGRO))
*
      JPLIB=LCMGID(IPLIB,'ISOTOPESLIST')
      IP1=LCMGIL(JPLIB,ISOT) ! set ISOT-th isotope
      IP2=LCMGIL(JPLIB,JSOT) ! set JSOT-th isotope
      CALL LCMLEN(IP1,'BIN-NFS',LENGT1,ITYLCM)
      CALL LCMLEN(IP2,'BIN-NFS',LENGT2,ITYLCM)
      IF((LENGT1.EQ.0).OR.(LENGT1.NE.LENGT2)) CALL XABORT('LIBCOR: UNA'
     1 //'BLE TO FIND CONSISTENT BIN TYPE INFORMATION.')
      CALL LCMGET(IP1,'BIN-NFS',NFS1)
      CALL LCMGET(IP2,'BIN-NFS',NFS2)
      LBIN=0
      IGRMIN=1
      IGRMAX=NGRO
      DO 10 IGRP=NGRO,1,-1
      IF(NFS1(IGRP).NE.NFS2(IGRP)) CALL XABORT('INVALID BIN INFO.')
      IF((IGRMAX.EQ.IGRP).AND.(NFS1(IGRP).EQ.0)) IGRMAX=IGRP-1
   10 LBIN=LBIN+NFS1(IGRP)
      DO 20 IGRP=1,NGRO
      IF((IGRMIN.EQ.IGRP).AND.(NFS1(IGRP).EQ.0)) IGRMIN=IGRP+1
   20 CONTINUE
      ALLOCATE(TBIN1(LBIN),TBIN2(LBIN),EBIN(LBIN+1),DBIN(LBIN))
      CALL LCMGET(IP1,'BIN-ENERGY',EBIN)
      CALL LCMGET(IP1,'BIN-NTOT0',TBIN1)
      CALL LCMGET(IP2,'BIN-NTOT0',TBIN2)
      CALL LCMSIX(IP1,'PT-PHYS',1)
      CALL LCMSIX(IP2,'PT-PHYS',1)
*---
*  LOOP OVER THE RESONANT ENERGY GROUPS.
*---
      LBIN=0
      JP1=LCMGID(IP1,'GROUP')
      JP2=LCMGID(IP2,'GROUP')
      DO 120 IGRP=IGRMIN,IGRMAX
      SUMA1=0.0D0
      SUMB1=0.0D0
      SUMA2=0.0D0
      SUMB2=0.0D0
      DO 30 IGF=1,NFS1(IGRP)
      SIGTA=MAX(0.002,TBIN1(LBIN+IGF))
      SIGTB=MAX(0.002,TBIN2(LBIN+IGF))
      DELM=LOG(EBIN(LBIN+IGF)/EBIN(LBIN+IGF+1))
      SUMA1=SUMA1+TBIN1(LBIN+IGF)*DELM
      SUMB1=SUMB1+SIGTA*DELM
      SUMA2=SUMA2+TBIN2(LBIN+IGF)*DELM
      SUMB2=SUMB2+SIGTB*DELM
      TBIN1(LBIN+IGF)=SIGTA
      TBIN2(LBIN+IGF)=SIGTB
   30 DBIN(LBIN+IGF)=DELM
      DO 40 IGF=1,NFS1(IGRP)
      TBIN1(LBIN+IGF)=TBIN1(LBIN+IGF)*REAL(SUMA1/SUMB1)
   40 TBIN2(LBIN+IGF)=TBIN2(LBIN+IGF)*REAL(SUMA2/SUMB2)
*
      CALL LCMLEL(JP1,IGRP,N1,ITYLCM)
      CALL LCMLEL(JP2,IGRP,N2,ITYLCM)
      IF((N1.EQ.0).OR.(N2.EQ.0)) GO TO 120
      KP1=LCMGIL(JP1,IGRP)
      KP2=LCMGIL(JP2,IGRP)
      CALL LCMLEN(KP1,'SIGQT-SIGS',NQT1,ITYLCM)
      CALL LCMLEN(KP2,'SIGQT-SIGS',NQT2,ITYLCM)
      CALL LCMLEN(KP1,'PROB-TABLE',NQT10,ITYLCM)
      CALL LCMLEN(KP2,'PROB-TABLE',NQT20,ITYLCM)
      ALLOCATE(PROB1(NQT10),PROB2(NQT20))
      CALL LCMGET(KP1,'PROB-TABLE',PROB1)
      CALL LCMGET(KP2,'PROB-TABLE',PROB2)
      DO 50 I=1,NQT1
   50 SIGQT1(I)=PROB1(MAXNPT+I)
      DO 60 I=1,NQT2
   60 SIGQT2(I)=PROB2(MAXNPT+I)
*
      ALLOCATE(COMOM(NQT1*NQT2))
      CALL LIBCOM(NFS1(IGRP),DBIN(LBIN+1),TBIN1(LBIN+1),
     1 TBIN2(LBIN+1),NQT1,NQT2,COMOM)
      CALL LIBOMG(NQT1,1-NQT1/2,SIGQT1,NQT2,1-NQT2/2,SIGQT2,
     1 COMOM,WSLD1)
      DEALLOCATE(COMOM)
*---
*  CHECK NORMALIZATION OF THE CORRELATED WEIGHT MATRIX.
*---
      DO 80 I=1,NQT1
      SUM=0.0
      DO 70 J=1,NQT2
   70 SUM=SUM+WSLD1((J-1)*NQT1+I)
      IF(ABS(SUM-PROB1(I)).GT.1.0E-4) THEN
         CALL XABORT('LIBCOR: BAD NORMALIZATION EXCEPTION(1).')
      ENDIF
   80 CONTINUE
      DO 100 I=1,NQT2
      SUM=0.0
      DO 90 J=1,NQT1
   90 SUM=SUM+WSLD1((I-1)*NQT1+J)
      IF(ABS(SUM-PROB2(I)).GT.1.0E-4) THEN
         CALL XABORT('LIBCOR: BAD NORMALIZATION EXCEPTION(2).')
      ENDIF
  100 CONTINUE
      DEALLOCATE(PROB2,PROB1)
*
      CALL LCMPUT(KP1,HNAMIS2,NQT1*NQT2,2,WSLD1)
      DO 110 I=1,NQT1
      DO 110 J=1,NQT2
  110 WSLD2((I-1)*NQT2+J)=WSLD1((J-1)*NQT1+I)
      CALL LCMPUT(KP2,HNAMIS1,NQT2*NQT1,2,WSLD2)
  120 LBIN=LBIN+NFS1(IGRP)
*
      CALL LCMSIX(IP2,' ',2)
      CALL LCMSIX(IP1,' ',2)
      DEALLOCATE(DBIN,EBIN,TBIN2,TBIN1)
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(NFS2,NFS1)
      RETURN
      END