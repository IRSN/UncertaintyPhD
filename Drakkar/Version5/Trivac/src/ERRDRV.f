*DECK ERRDRV
      SUBROUTINE ERRDRV(IPMAC1,IPMAC2,NREG,NREG2,NGRP,HREAC,ERAMAX,
     1 ERASUM,ERQMAX,ERQSUM)
*
*-----------------------------------------------------------------------
*
*Purpose:
* perform reaction rate statistics between two extended macrolibs.
*
*Copyright:
* Copyright (C) 2002 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* IPMAC1  pointer to the reference extended macrolib.
* IPMAC2  pointer to the approximate extended macrolib.
* NREG    number of regions in the macrolib.
* NREG2   number of regions used for statistics.
* NGRP    number of energy groups in the macrolib.
* HREAC   nuclear reaction used to compute power map
*
*Parameters: output
* ERAMAX  maximum relative error on absorption rates.
* ERASUM  average relative error on absorption rates.
* ERQMAX  maximum relative error on QUANDRY powers.
* ERQSUM  average relative error on QUANDRY powers.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPMAC1,IPMAC2
      INTEGER NREG,NGRP
      REAL ERAMAX,ERASUM,ERQMAX,ERQSUM
      CHARACTER HREAC*8
*----
*  LOCAL VARIABLES
*----
      PARAMETER (NSTATE=40)
      CHARACTER HSMG*131
      INTEGER IDATA(NSTATE)
      TYPE(C_PTR) JPMAC1,KPMAC1,JPMAC2,KPMAC2
      REAL, DIMENSION(:), ALLOCATABLE :: VOL1,VOL2,TOTAL,GAR,FLUX,
     1 QUAN1,QUAN2,TRABS1,TRABS2
      REAL, DIMENSION(:,:), ALLOCATABLE :: TRA1,TRA2,XABS1,XABS2
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(TRA1(NREG,NGRP),TRA2(NREG,NGRP),XABS1(NREG,NGRP),
     1 XABS2(NREG,NGRP),VOL1(NREG),VOL2(NREG),TOTAL(NREG),GAR(NREG),
     2 FLUX(NREG),QUAN1(NREG),QUAN2(NREG),TRABS1(NREG),TRABS2(NREG))
*----
*  RECOVER REFERENCE REACTION RATES:
*----
      CALL LCMGET(IPMAC1,'STATE-VECTOR',IDATA)
      IF((NREG.NE.IDATA(2)).OR.(NGRP.NE.IDATA(1))) THEN
         CALL XABORT('ERRDRV: INVALID VALUE OF NREG OR NGRP.')
      ENDIF
      CALL LCMGET(IPMAC1,'VOLUME',VOL1)
      VOL1T=0.0
      PWR1T=0.0
      DO 10 I=1,NREG2
      TRABS1(I)=0.0
      QUAN1(I)=0.0
      VOL1T=VOL1T+VOL1(I)
   10 CONTINUE
      CALL ERRABS(IPMAC1,NREG2,NREG,NGRP,XABS1)
      JPMAC1=LCMGID(IPMAC1,'GROUP')
      DO 35 IGR=1,NGRP
      KPMAC1=LCMGIL(JPMAC1,IGR)
      CALL LCMGET(KPMAC1,'NTOT0',TOTAL)
      CALL LCMGET(KPMAC1,'SIGW00',GAR)
      CALL LCMGET(KPMAC1,'FLUX-INTG',FLUX)
      DO 20 I=1,NREG2
      TRA1(I,IGR)=(TOTAL(I)-GAR(I))*FLUX(I)/VOL1(I)
      TRABS1(I)=TRABS1(I)+XABS1(I,IGR)*FLUX(I)/VOL1(I)
   20 CONTINUE
      CALL LCMLEN(KPMAC1,HREAC,ILONG,ITYLCM)
      IF(ILONG.EQ.0) THEN
         WRITE(HSMG,'(32HERRDRV: UNABLE TO FIND REACTION ,A,1H.)') HREAC
         CALL XABORT(HSMG)
      ENDIF
      CALL LCMGET(KPMAC1,HREAC,GAR)
      DO 30 I=1,NREG2
      QUAN1(I)=QUAN1(I)+GAR(I)*FLUX(I)
      PWR1T=PWR1T+QUAN1(I)
   30 CONTINUE
   35 CONTINUE
*----
*  RECOVER APPROXIMATE REACTION RATES:
*----
      CALL LCMGET(IPMAC2,'STATE-VECTOR',IDATA)
      IF((NREG.NE.IDATA(2)).OR.(NGRP.NE.IDATA(1))) THEN
         CALL XABORT('ERRDRV: INVALID VALUE OF NREG OR NGRP.')
      ENDIF
      CALL LCMGET(IPMAC2,'VOLUME',VOL2)
      VOL2T=0.0
      PWR2T=0.0
      DO 50 I=1,NREG2
      TRABS2(I)=0.0
      QUAN2(I)=0.0
      VOL2T=VOL2T+VOL2(I)
   50 CONTINUE
      CALL ERRABS(IPMAC2,NREG2,NREG,NGRP,XABS2)
      JPMAC2=LCMGID(IPMAC2,'GROUP')
      DO 80 IGR=1,NGRP
      KPMAC2=LCMGIL(JPMAC2,IGR)
      CALL LCMGET(KPMAC2,'NTOT0',TOTAL)
      CALL LCMGET(KPMAC2,'SIGW00',GAR)
      CALL LCMGET(KPMAC2,'FLUX-INTG',FLUX)
      DO 60 I=1,NREG2
      TRA2(I,IGR)=(TOTAL(I)-GAR(I))*FLUX(I)/VOL2(I)
      TRABS2(I)=TRABS2(I)+XABS2(I,IGR)*FLUX(I)/VOL2(I)
   60 CONTINUE
      IF(ILONG.NE.0) THEN
         CALL LCMGET(KPMAC2,HREAC,GAR)
         DO 70 I=1,NREG2
         QUAN2(I)=QUAN2(I)+GAR(I)*FLUX(I)
         PWR2T=PWR2T+QUAN2(I)
   70    CONTINUE
      ENDIF
   80 CONTINUE
*----
*  COMPUTE QUANDRY TYPE NORMALIZED POWER DENSITIES.
*----
      IF(ILONG.GT.0) THEN
         DO 90 I=1,NREG2
         IF(VOL1(I).NE.0.0) QUAN1(I)=QUAN1(I)/VOL1(I)
         IF(VOL2(I).NE.0.0) QUAN2(I)=QUAN2(I)/VOL2(I)
         IF(PWR1T.NE.0.0) QUAN1(I)=QUAN1(I)*VOL1T/PWR1T
         IF(PWR2T.NE.0.0) QUAN2(I)=QUAN2(I)*VOL2T/PWR2T
   90    CONTINUE
      ENDIF
*----
*  PRINT STATISTICS ON GROUPWISE REMOVAL RATES.
*----
      WRITE(6,'(/47H ERRDRV: STATISTICS ON GROUPWISE REMOVAL RATES:)')
      SUMREF=0.0
      SUM=0.0
      DO 125 IGR=1,NGRP
      DO 120 I=1,NREG2
      SUMREF=SUMREF+TRA1(I,IGR)*VOL1(I)
      SUM=SUM+TRA2(I,IGR)*VOL2(I)
  120 CONTINUE
  125 CONTINUE
      DO 150 IGR=1,NGRP
      WRITE (6,'(/17H PROCESSING GROUP,I3)') IGR
      ERGMAX=0.0
      ERGSUM=0.0
      VOLTOT=0.0
      DO 130 I=1,NREG2
      TRA2(I,IGR)=TRA2(I,IGR)*(SUMREF/SUM)*(VOL2T/VOL1T)
      IF(TRA1(I,IGR).NE.0.0) THEN
         VOLTOT=VOLTOT+VOL1(I)
         GAR(I)=100.0*(TRA2(I,IGR)-TRA1(I,IGR))/TRA1(I,IGR)
      ELSE
         GAR(I)=0.0
      ENDIF
      ERGSUM=ERGSUM+VOL1(I)*ABS(GAR(I))
      ERGMAX=MAX(ERGMAX,ABS(GAR(I)))
  130 CONTINUE
      ERGSUM=ERGSUM/VOLTOT
      WRITE (6,'(/8X,9HREFERENCE,7X,6HAPPROX,7X,5HERROR)')
      DO 140 I=1,NREG2
      WRITE (6,'(4X,I4,1X,1P,2E13.5,0P,F9.3,2H %)') I,TRA1(I,IGR),
     1 TRA2(I,IGR),GAR(I)
  140 CONTINUE
      WRITE (6,'(/10X,14HMAXIMUM ERROR=,F9.3,2H %,F9.2,2H %,F9.1,2H %)')
     1 ERGMAX,ERGMAX,ERGMAX
      WRITE (6,'(10X,14HAVERAGE ERROR=,F9.3,2H %,F9.2,2H %,F9.1,2H %/)')
     1 ERGSUM,ERGSUM,ERGSUM
  150 CONTINUE
*----
*  PRINT STATISTICS ON CONDENSED ABSORPTION RATES.
*----
      WRITE(6,'(/40H ERRDRV: STATISTICS ON ABSORPTION RATES:)')
      SUMREF=0.0
      SUM=0.0
      DO 160 I=1,NREG2
      SUMREF=SUMREF+TRABS1(I)*VOL1(I)
      SUM=SUM+TRABS2(I)*VOL2(I)
  160 CONTINUE
      ERAMAX=0.0
      ERASUM=0.0
      VOLTOT=0.0
      DO 165 I=1,NREG2
      TRABS2(I)=TRABS2(I)*(SUMREF/SUM)*(VOL2T/VOL1T)
      IF(TRABS1(I).NE.0.0) THEN
         VOLTOT=VOLTOT+VOL1(I)
         GAR(I)=100.0*(TRABS2(I)-TRABS1(I))/TRABS1(I)
      ELSE
         GAR(I)=0.0
      ENDIF
      ERASUM=ERASUM+VOL1(I)*ABS(GAR(I))
      ERAMAX=MAX(ERAMAX,ABS(GAR(I)))
  165 CONTINUE
      ERASUM=ERASUM/VOLTOT
      WRITE (6,'(/8X,9HREFERENCE,7X,6HAPPROX,7X,5HERROR)')
      DO 170 I=1,NREG2
      WRITE (6,'(4X,I4,1X,1P,2E13.5,0P,F9.3,2H %)') I,TRABS1(I),
     1 TRABS2(I),GAR(I)
  170 CONTINUE
      WRITE (6,'(/10X,14HMAXIMUM ERROR=,F9.3,2H %,F9.2,2H %,F9.1,2H %)')
     1 ERAMAX,ERAMAX,ERAMAX
      WRITE (6,'(10X,14HAVERAGE ERROR=,F9.3,2H %,F9.2,2H %,F9.1,2H %/)')
     1 ERASUM,ERASUM,ERASUM
*----
*  PRINT STATISTICS ON QUANDRY TYPE NORMALIZED POWER DENSITIES.
*----
      IF(ILONG.NE.0) THEN
         WRITE(6,'(/48H ERRDRV: STATISTICS ON QUANDRY TYPE NORMALIZED P,
     1   15HOWER DENSITIES:)')
         ERQMAX=0.0
         ERQSUM=0.0
         VOLTOT=0.0
         DO 180 I=1,NREG2
         ERR=ABS(VOL1(I)/VOL1T-VOL2(I)/VOL2T)
         IF(ERR.GT.1.0E-4*ABS(VOL1(I)/VOL1T)) THEN
            WRITE(HSMG,'(37HERRDRV: INCONSISTENT VOLUME IN REGION,I5,
     1      3H BY,F7.2,2H %)') I,ERR*100.0
            CALL XABORT(HSMG)
         ENDIF
         GAR(I)=0.0
         IF(QUAN1(I).EQ.0.0) GO TO 180
         VOLTOT=VOLTOT+VOL1(I)
         GAR(I)=100.0*(QUAN2(I)-QUAN1(I))/QUAN1(I)
         ERQSUM=ERQSUM+VOL1(I)*ABS(QUAN1(I)-QUAN2(I))/QUAN1(I)
         ERQMAX=MAX(ERQMAX,ABS(GAR(I)))
  180    CONTINUE
         IF(VOLTOT.NE.0.0) ERQSUM=100.0*ERQSUM/VOLTOT
         WRITE(6,'(/8X,9HREFERENCE,7X,6HAPPROX,7X,5HERROR)')
         DO 190 I=1,NREG2
         IF((QUAN1(I).NE.0.0).OR.(QUAN2(I).NE.0.0)) THEN
            WRITE(6,'(4X,I4,1X,1P,2E13.5,0P,F9.3,2H %)') I,QUAN1(I),
     1      QUAN2(I),GAR(I)
         ENDIF
  190    CONTINUE
         WRITE(6,200) ERQMAX,ERQMAX,ERQMAX
         WRITE(6,210) ERQSUM,ERQSUM,ERQSUM
      ENDIF
*----
*  PRINT STATISTICS ON K-EFFECTIVE.
*----
      CALL LCMLEN(IPMAC1,'K-EFFECTIVE',LENGT,ITYLCM)
      IF(LENGT.EQ.1) THEN
         CALL LCMGET(IPMAC1,'K-EFFECTIVE',FKEFF1)
         CALL LCMGET(IPMAC2,'K-EFFECTIVE',FKEFF2)
         WRITE(6,'(/5X,22HREFERENCE K-EFFECTIVE=,F9.6/8X,11HAPPROX K-EF,
     1   8HFECTIVE=,F9.6,8H  ERROR=,F9.1,4H PCM)') FKEFF1,FKEFF2,
     2   (FKEFF2-FKEFF1)*1.0E5
      ENDIF
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(XABS2,XABS1,TRA1,TRA2,VOL1,VOL2,TOTAL,GAR,FLUX,QUAN2,
     1 QUAN1,TRABS2,TRABS1)
      RETURN
*
  200 FORMAT(10X,14HMAXIMUM ERROR=,F9.3,2H %,F9.2,2H %,F9.1,2H %)
  210 FORMAT(10X,14HAVERAGE ERROR=,F9.3,2H %,F9.2,2H %,F9.1,2H %)
      END
