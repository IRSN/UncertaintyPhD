*DECK FLDBMX
      FUNCTION FLDBMX(F,N,IBLSZ,ITER,IPTRK,IPSYS,IPFLUX) RESULT(X)
*
*-----------------------------------------------------------------------
*
*Purpose:
* multiplication of A^(-1)B times the harmonic flux in BIVAC.
*
*Copyright:
* Copyright (C) 2020 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* F       harmonic flux vector.
* N       number of unknowns in one harmonic.
* IBLSZ   block size of the Arnoldi Hessenberg matrix.
* ITER    Arnoldi iteration index.
* IPTRK   L_TRACK pointer to the tracking information.
* IPSYS   L_SYSTEM pointer to system matrices.
* IPFLUX  L_FLUX pointer to the solution.
*
*Parameters: output
* X       result of the multiplication.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER, INTENT(IN) :: N,IBLSZ,ITER
      COMPLEX(KIND=8), DIMENSION(N,IBLSZ), INTENT(IN) :: F
      COMPLEX(KIND=8), DIMENSION(N,IBLSZ) :: X
      TYPE(C_PTR) IPTRK,IPSYS,IPFLUX
*----
*  LOCAL VARIABLES
*----
      PARAMETER(NSTATE=40)
      INTEGER ISTATE(NSTATE)
      REAL EPSCON(5),TIME(2)
      CHARACTER TEXT12*12,HSMG*131
*----
*  ALLOCATABLE ARRAYS
*----
      REAL, DIMENSION(:), ALLOCATABLE :: WORK1,WORK2
      REAL, DIMENSION(:,:), ALLOCATABLE :: GAF1,GRAD
*
*     TIME(1) : CPU TIME FOR THE SOLUTION OF LINEAR SYSTEMS.
*     TIME(2) : CPU TIME FOR BILINEAR PRODUCT EVALUATIONS.
      CALL LCMGET(IPFLUX,'CPU-TIME',TIME)
      CALL KDRCPU(TK1)
*----
*  RECOVER INFORMATION FROM IPTRK, IPSYS AND IPFLUX
*----
      CALL LCMGET(IPTRK,'STATE-VECTOR',ISTATE)
      NEL=ISTATE(1)
      NUN=ISTATE(2)
      NLF=ISTATE(14)
      CALL LCMGET(IPSYS,'STATE-VECTOR',ISTATE)
      NGRP=ISTATE(1)
      LL4=ISTATE(2)
      ITY=ISTATE(4)
      NBMIX=ISTATE(7)
      NAN=ISTATE(8)
      IF(ITY.EQ.11) LL4=LL4*NLF/2 ! SPN cases
      CALL LCMGET(IPFLUX,'STATE-VECTOR',ISTATE)
      ICL1=ISTATE(8)
      ICL2=ISTATE(9)
      IREBAL=ISTATE(10)
      MAXINR=ISTATE(11)
      NADI=ISTATE(13)
      IMPX=ISTATE(40)
      CALL LCMGET(IPFLUX,'EPS-CONVERGE',EPSCON)
      EPSINR=EPSCON(1)
      IF(LL4*NGRP.NE.N) CALL XABORT('FLDBMX: INCONSISTENT UNKNOWNS.')
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(WORK1(NUN),WORK2(NUN),GAF1(NUN,NGRP),GRAD(NUN,NGRP))
*----
*  MAIN LOOP OVER MODES.
*----
      IF(IMPX.GT.10) THEN
        WRITE(6,'(/49H FLDBMX: MATRIX MULTIPLICATION AT IRAM ITERATION=,
     1  I5)') ITER
      ENDIF
      DO 110 IMOD=1,IBLSZ
*----
*  COMPUTE B TIMES THE FLUX.
*----
      DO 40 IGR=1,NGRP
      DO 10 I=1,LL4
      GAF1(I,IGR)=0.0
   10 CONTINUE
      DO 30 JGR=1,NGRP
      WRITE(TEXT12,'(1HB,2I3.3)') IGR,JGR
      CALL LCMLEN(IPSYS,TEXT12,ILONG,ITYLCM)
      IF(ILONG.EQ.0) GO TO 30
      DO 15 I=1,LL4
      IOF=(JGR-1)*LL4+I
      WORK1(I)=REAL(F(IOF,IMOD),KIND=4)
      IF(ABS(AIMAG(F(IOF,IMOD))).GT.1.0E-8) THEN
        WRITE(HSMG,'(13HFLDBMX: FLUX(,2I8,2H)=,1P,2E12.4,
     1  12H IS COMPLEX.)') IOF,IMOD,F(IOF,IMOD)
        CALL XABORT(HSMG)
      ENDIF
   15 CONTINUE
      CALL MTLDLM(TEXT12,IPTRK,IPSYS,LL4,ITY,WORK1,WORK2)
      DO 20 I=1,LL4
      GAF1(I,IGR)=GAF1(I,IGR)+WORK2(I)
   20 CONTINUE
   30 CONTINUE
   40 CONTINUE
      CALL KDRCPU(TK2)
      TIME(2)=TIME(2)+(TK2-TK1)
*----
*  COMPUTE A^(-1)B WITHOUT UP-SCATTERING.
*----
      DO 80 IGR=1,NGRP
      CALL KDRCPU(TK1)
      DO 50 I=1,LL4
      GRAD(I,IGR)=GAF1(I,IGR)
   50 CONTINUE
      DO 70 JGR=1,IGR-1
      WRITE(TEXT12,'(1HA,2I3.3)') IGR,JGR
      CALL LCMLEN(IPSYS,TEXT12,ILONG,ITYLCM)
      IF(ILONG.EQ.0) GO TO 70
      CALL MTLDLM(TEXT12,IPTRK,IPSYS,LL4,ITY,GRAD(1,JGR),WORK2)
      DO 60 I=1,LL4
      GRAD(I,IGR)=GRAD(I,IGR)+WORK2(I)
   60 CONTINUE
   70 CONTINUE
      CALL KDRCPU(TK2)
      TIME(2)=TIME(2)+(TK2-TK1)
*
      CALL KDRCPU(TK1)
      WRITE(TEXT12,'(1HA,2I3.3)') IGR,IGR
      IF(ITY.EQ.11) THEN
*       SIMPLIFIED PN BIVAC TRACKING.
        IF(NAN.EQ.0) CALL XABORT('FLDBMX: SPN-ONLY ALGORITHM.')
        CALL FLDBSS(TEXT12,IPTRK,IPSYS,LL4,NBMIX,NAN,GRAD(1,IGR),NADI)
      ELSE
        CALL MTLDLS(TEXT12,IPTRK,IPSYS,LL4,ITY,GRAD(1,IGR))
      ENDIF
      CALL KDRCPU(TK2)
      TIME(1)=TIME(1)+(TK2-TK1)
   80 CONTINUE
*----
*  PERFORM THERMAL (UP-SCATTERING) ITERATIONS.
*----
      IF((IREBAL.EQ.1).OR.(NLF.GT.2)) THEN
        CALL FLDBHR(IPTRK,IPSYS,.FALSE.,LL4,ITY,NUN,NGRP,ICL1,ICL2,IMPX,
     1  MAXINR,EPSINR,TIME(1),TIME(2),GRAD)
      ENDIF
      DO 100 IGR=1,NGRP
      DO 90 I=1,LL4
      IOF=(IGR-1)*LL4+I
      X(IOF,IMOD)=GRAD(I,IGR)
   90 CONTINUE
  100 CONTINUE
*----
*  END OF LOOP OVER MODES.
*----
  110 CONTINUE
      CALL LCMPUT(IPFLUX,'CPU-TIME',2,2,TIME)
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(GRAD,GAF1,WORK2,WORK1)
      RETURN
      END FUNCTION FLDBMX