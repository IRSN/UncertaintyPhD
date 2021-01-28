*DECK FLDDRV
      SUBROUTINE FLDDRV (CMODUL,IPTRK,IPSYS,REC,NEL,LL4,ITY,NUN,NBMIX,
     1 MAT,VOL,IDL,NGRP,TITR,LREL,IPFLUX)
*
*-----------------------------------------------------------------------
*
*Purpose:
* solution of the neutron flux as an eigenvalue problem.
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
* CMODUL  name of the assembly door ('BIVAC' or 'TRIVAC').
* IPTRK   L_TRACK pointer to the tracking information.
* IPSYS   L_SYSTEM pointer to system matrices.
* REC     flux recovery flag:
*         .true.: recover the existing solution as initial estimate;
*         .false.: use a uniform initial estimate.
* NEL     total number of finite elements.
* LL4     order of the system matrices.
* ITY     type of solution (2: classical Trivac; 3: Thomas-Raviart).
* NUN     total number of unknowns per group.
* NBMIX   number of material mixtures.
* MAT     index-number of the mixture type assigned to each volume.
* VOL     volumes.
* IDL     position of the average flux component associated with each
*         volume.
* NGRP    number of energy groups.
* TITR    title.
* LREL    flag set to .true. if a RHS estimate of the solution is
*         available.
* IPFLUX  L_FLUX pointer to the solution.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      CHARACTER CMODUL*12,TITR*72
      TYPE(C_PTR) IPTRK,IPSYS,IPFLUX
      INTEGER NEL,LL4,ITY,NUN,NBMIX,MAT(NEL),IDL(NEL),NGRP
      REAL VOL(NEL)
      LOGICAL REC,LREL
*----
*  LOCAL VARIABLES
*----
      INTERFACE
        FUNCTION FLDBMX(F,N,IBLSZ,ITER,IPTRK,IPSYS,IPFLUX) RESULT(X)
          USE GANLIB
          INTEGER, INTENT(IN) :: N,IBLSZ,ITER
          COMPLEX(KIND=8), DIMENSION(N,IBLSZ), INTENT(IN) :: F
          COMPLEX(KIND=8), DIMENSION(N,IBLSZ) :: X
          TYPE(C_PTR) IPTRK,IPSYS,IPFLUX
        END FUNCTION FLDBMX
      END INTERFACE
      INTERFACE
        FUNCTION FLDTMX(F,N,IBLSZ,ITER,IPTRK,IPSYS,IPFLUX) RESULT(X)
          USE GANLIB
          INTEGER, INTENT(IN) :: N,IBLSZ,ITER
          COMPLEX(KIND=8), DIMENSION(N,IBLSZ), INTENT(IN) :: F
          COMPLEX(KIND=8), DIMENSION(N,IBLSZ) :: X
          TYPE(C_PTR) IPTRK,IPSYS,IPFLUX
        END FUNCTION FLDTMX
      END INTERFACE
      PARAMETER (NSTATE=40,IOUT=6)
      CHARACTER TEXT4*4,HSMG*131
      DOUBLE PRECISION DFLOTT
      LOGICAL ADJ,RAND
      INTEGER ISTATE(NSTATE)
      REAL EPSCON(5),RELAX
      REAL, DIMENSION(:), ALLOCATABLE :: FKEFFV
      REAL, DIMENSION(:,:), ALLOCATABLE :: EVECT
      REAL, DIMENSION(:,:,:), ALLOCATABLE :: EV,AD
      COMPLEX, DIMENSION(:), ALLOCATABLE :: CFKEFFV
      COMPLEX, DIMENSION(:,:,:), ALLOCATABLE :: CEV
      TYPE(C_PTR) JPFLUX,KPFLUX,MPFLUX,NPFLUX
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(EVECT(NUN,NGRP))
*
*-----------------------------------------------------------------------
* INFORMATION RECOVERED FROM L_SYSTEM AT IPSYS:
*  'A  1  1'  : SYSTEM MATRIX RELATED TO FAST LEAKAGE AND REMOVAL.
*  'A  2  2'  : SYSTEM MATRIX RELATED TO THERMAL LEAKAGE AND REMOVAL.
*  'A  1  2'  : SYSTEM MATRIX RELATED TO UP-SCATTERING.
*  'A  2  1'  : SYSTEM MATRIX RELATED TO DOWN-SCATTERING.
*  'B  1  1'  : SYSTEM MATRIX RELATED TO FAST FISSION.
*  'B  1  2'  : SYSTEM MATRIX RELATED TO THERMAL FISSION.
*-----------------------------------------------------------------------
*
*----
*  READ THE INPUT DATA
*----
      IMPX=1
      IMPH=0
      RAND=.FALSE.
      IF(REC) THEN
*        RECOVER EXISTING OPTIONS.
         CALL LCMGET(IPFLUX,'STATE-VECTOR',ISTATE)
         ADJ=MOD(ISTATE(3)/10,10).EQ.1
         LMOD=ISTATE(4)
         ICL1=ISTATE(8)
         ICL2=ISTATE(9)
         IREBAL=ISTATE(10)
         MAXINR=ISTATE(11)
         MAXOUT=ISTATE(12)
         NADI=ISTATE(13)
         IBLSZ=ISTATE(14)
         NSTARD=ISTATE(15)
         CALL LCMGET(IPFLUX,'EPS-CONVERGE',EPSCON)
         EPSINR=EPSCON(1)
         EPSOUT=EPSCON(2)
         EPSMSR=EPSCON(4)
         RELAX=EPSCON(5)
      ELSE
*        DEFAULT OPTIONS.
         ADJ=.FALSE.
         LMOD=0
         ICL1=3
         ICL2=3
         MAXINR=0
         IREBAL=0
         MAXOUT=200
         IBLSZ=0
         NSTARD=0
         CALL LCMGET(IPTRK,'STATE-VECTOR',ISTATE)
         NADI=ISTATE(33)
         EPSINR=1.0E-5
         EPSOUT=1.0E-4
         EPSMSR=1.0E-6
         RELAX=1.0
      ENDIF
*
   10 CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
      IF(INDIC.EQ.10) GO TO 50
   20 IF(INDIC.NE.3) CALL XABORT('FLDDRV: CHARACTER DATA EXPECTED.')
      IF(TEXT4.EQ.'EDIT') THEN
        CALL REDGET(INDIC,IMPX,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(3).')
      ELSE IF((TEXT4.EQ.'VAR1').OR.(TEXT4.EQ.'ACCE')) THEN
        CALL REDGET(INDIC,ICL1,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(1).')
        CALL REDGET(INDIC,ICL2,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(2).')
      ELSE IF(TEXT4.EQ.'IRAM') THEN
        CALL REDGET(INDIC,IBLSZ,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(3).')
        CALL REDGET(INDIC,LMOD,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(4).')
        NADI=MAX(NADI,5)
        CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) THEN
          IF((ITY.EQ.2).OR.(ITY.EQ.3).OR.(ITY.EQ.11).OR.(ITY.EQ.13))
     1    NADI=MAX(NADI,20)
          GO TO 20
        ENDIF
        IF(CMODUL.EQ.'BIVAC') CALL XABORT('FLDDRV: NSTARD OPTION NOT A'
     1  //'VAILABLE WITH BIVAC.')
        NSTARD=NITMA
        NADI=MAX(NADI,20)
      ELSE IF(TEXT4.EQ.'EPSG') THEN
        CALL REDGET(INDIC,NITMA,EPSMSR,TEXT4,DFLOTT)
        IF(INDIC.NE.2) CALL XABORT('FLDDRV: REAL DATA EXPECTED.')
      ELSE IF(TEXT4.EQ.'ADI') THEN
        CALL REDGET(INDIC,NADI,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(5).')
      ELSE IF(TEXT4.EQ.'ADJ') THEN
        ADJ=.TRUE.
      ELSE IF(TEXT4.EQ.'EXTE') THEN
   30   CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.EQ.1) THEN
          MAXOUT=NITMA
        ELSE IF(INDIC.EQ.2) THEN
          EPSOUT=FLOTT
        ELSE
          GO TO 20
        ENDIF
        GO TO 30
      ELSE IF(TEXT4.EQ.'THER') THEN
        IREBAL=1
   40   CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.EQ.1) THEN
          MAXINR=NITMA
        ELSE IF(INDIC.EQ.2) THEN
          EPSINR=FLOTT
        ELSE
          GO TO 20
        ENDIF
        GO TO 40
      ELSE IF(TEXT4.EQ.'MONI') THEN
        CALL REDGET(INDIC,LMOD,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(6).')
        IF(LMOD.LE.0) CALL XABORT('FLDDRV: INVALID VALUE OF LMOD.')
      ELSE IF(TEXT4.EQ.'RAND') THEN
        RAND=.TRUE.
      ELSE IF(TEXT4.EQ.'HIST') THEN
        CALL REDGET(INDIC,IMPH,FLOTT,TEXT4,DFLOTT)
        IF(INDIC.NE.1) CALL XABORT('FLDDRV: INTEGER DATA EXPECTED(7).')
      ELSE IF(TEXT4.EQ.'RELA') THEN
        IF(.NOT.LREL) CALL XABORT('FLDDRV: ENTRY L_FLUX IN MODIFICATIO'
     1  //'N MODE EXPECTED FOR RELAX KEYWORD.')
        CALL REDGET(INDIC,NITMA,RELAX,TEXT4,DFLOTT)
        IF(INDIC.NE.2) CALL XABORT('FLDDRV: REAL DATA EXPECTED.')
      ELSE IF(TEXT4.EQ.';') THEN
        GO TO 50
      ELSE
        CALL XABORT('FLDDRV: '//TEXT4//' IS AN INVALID KEY WORD.')
      ENDIF
      GO TO 10
*----
*  FLUXES INITIALIZATION
*----
   50 IF(REC.AND.(IMPH.EQ.0)) THEN
         CALL LCMLEN(IPFLUX,'FLUX',ILONG,ITYLCM)
         IF(ILONG.NE.NGRP) CALL XABORT('FLDDRV: UNABLE TO RECOVER ''FLU'
     1   //'X''.')
         JPFLUX=LCMGID(IPFLUX,'FLUX')
         DO 60 IGR=1,NGRP
         CALL LCMGDL(JPFLUX,IGR,EVECT(1,IGR))
   60    CONTINUE
      ELSE
*        INITIAL ESTIMATE OF THE DIRECT FLUXES.
         CALL XDRSET(EVECT,NGRP*NUN,1.0)
      ENDIF
*
      DNORM=1.0
      ANORM=1.0
      IF((LMOD.GT.0).AND.(IBLSZ.EQ.0)) THEN
*        BI-ORTHOGONAL HARMONIC CALCULATION.
         IF(CMODUL.NE.'TRIVAC') CALL XABORT('FLDDRV: HARMONIC CALCULAT'
     1   //'ION IS ONLY POSSIBLE WITH TRIVAC.')
         ALLOCATE(FKEFFV(LMOD),EV(NUN,NGRP,LMOD),AD(NUN,NGRP,LMOD))
         CALL FLDMON(IPTRK,IPSYS,IPFLUX,LL4,ITY,NUN,NGRP,LMOD,ICL1,
     1   ICL2,IMPX,IMPH,TITR,EPSOUT,NADI,MAXOUT,MAXINR,EPSINR,RAND,
     2   FKEFFV,EV,AD)
         JPFLUX=LCMLID(IPFLUX,'MODE',LMOD)
         DO 90 IMOD=1,LMOD
*        CREATE A DIRECTORY AT IMOD-TH LIST ELEMENT.
         KPFLUX=LCMDIL(JPFLUX,IMOD)
*        PUT NODES IN DIRECTORY KPFLUX.
         CALL LCMPUT(KPFLUX,'K-EFFECTIVE',1,2,FKEFFV(IMOD))
         CALL LCMPUT(KPFLUX,'K-INFINITY',1,2,FKEFFV(IMOD))
         MPFLUX=LCMLID(KPFLUX,'FLUX',NGRP)
         NPFLUX=LCMLID(KPFLUX,'AFLUX',NGRP)
*        STORE FLUX AND ADJOINT FLUX IN THE IGR-TH COMPONENT OF EACH
*        LIST.
         DO 70 IGR=1,NGRP
         CALL FLDTRI(IPTRK,NEL,NUN,EV(1,IGR,IMOD),MAT,VOL,IDL)
         CALL FLDTRI(IPTRK,NEL,NUN,AD(1,IGR,IMOD),MAT,VOL,IDL)
   70    CONTINUE
         IF(IMOD.EQ.1) THEN
           CALL FLDNOR(IPSYS,NUN,NGRP,NEL,NBMIX,MAT,VOL,IDL,'DIRE',
     1     EV(1,1,IMOD),DNORM)
           CALL FLDNOR(IPSYS,NUN,NGRP,NEL,NBMIX,MAT,VOL,IDL,'ADJO',
     1     AD(1,1,IMOD),ANORM)
         ELSE
           EV(:NUN,:NGRP,IMOD)=EV(:NUN,:NGRP,IMOD)*DNORM
           AD(:NUN,:NGRP,IMOD)=AD(:NUN,:NGRP,IMOD)*DNORM
         ENDIF
         IF(LREL) THEN
           CALL FLDREL(RELAX,MPFLUX,NGRP,NUN,EV(1,1,IMOD)) 
           CALL FLDREL(RELAX,NPFLUX,NGRP,NUN,AD(1,1,IMOD)) 
         ENDIF
         DO 80 IGR=1,NGRP
         CALL LCMPDL(MPFLUX,IGR,NUN,2,EV(1,IGR,IMOD))
         CALL LCMPDL(NPFLUX,IGR,NUN,2,AD(1,IGR,IMOD))
   80    CONTINUE
   90    CONTINUE
         CALL LCMPUT(IPFLUX,'K-EFFECTIVE',1,2,FKEFFV(1))
         DEALLOCATE(AD,EV,FKEFFV)
         IF(IMPX.GT.1) THEN
*          TEST ORTHOGONALITY OF EIGENVECTORS.
           CALL FLDORT(IPSYS,IPFLUX,NUN,NGRP,LMOD)
         ENDIF
      ELSE IF(IBLSZ.GT.0) THEN
*        IMPLICIT RESTARTED ARNOLDI METHOD (IRAM).
         IF(LMOD.EQ.0) CALL XABORT('FLDDRV: LMOD>0 EXPECTED WITH IRAM.')
         ALLOCATE(CFKEFFV(LMOD),CEV(NUN,NGRP,LMOD))
         EPSCON(1)=EPSINR
         EPSCON(4)=EPSMSR
         CALL LCMPUT(IPFLUX,'EPS-CONVERGE',5,2,EPSCON)
         CALL XDISET(ISTATE,NSTATE,0)
         ISTATE(3)=1
         ISTATE(8)=ICL1
         ISTATE(9)=ICL2
         ISTATE(10)=IREBAL
         ISTATE(11)=MAXINR
         ISTATE(13)=NADI
         ISTATE(15)=NSTARD
         ISTATE(40)=IMPX
*
*        DIRECT CALCULATION
         CALL LCMPUT(IPFLUX,'STATE-VECTOR',NSTATE,1,ISTATE)
         IF(CMODUL.EQ.'BIVAC') THEN
           CALL FLDARN(FLDBMX,IPTRK,IPSYS,IPFLUX,LL4,NUN,NGRP,LMOD,
     1     IBLSZ,.FALSE.,IMPX,EPSOUT,MAXOUT,CEV,CFKEFFV)
         ELSE IF(CMODUL.EQ.'TRIVAC') THEN
           CALL FLDARN(FLDTMX,IPTRK,IPSYS,IPFLUX,LL4,NUN,NGRP,LMOD,
     1     IBLSZ,.FALSE.,IMPX,EPSOUT,MAXOUT,CEV,CFKEFFV)
         ENDIF
         JPFLUX=LCMLID(IPFLUX,'MODE',LMOD)
         DO 120 IMOD=1,LMOD
         IF(AIMAG(CFKEFFV(IMOD)).NE.0.0) THEN
           WRITE(HSMG,'(7HFLDDRV:,I4,27H-TH DIRECT MODE IS COMPLEX.)')
     1     IMOD
           WRITE(IOUT,'(A)') HSMG
           IF(IMOD.EQ.1)CALL XABORT('FLDDRV: COMPLEX FUNDAMENTAL MODE.')
           GO TO 120
         ENDIF
*        CREATE A DIRECTORY AT IMOD-TH LIST ELEMENT.
         KPFLUX=LCMDIL(JPFLUX,IMOD)
*        PUT NODES IN DIRECTORY KPFLUX.
         EVECT(:NUN,:NGRP)=REAL(CEV(:NUN,:NGRP,IMOD))
         CALL LCMPUT(KPFLUX,'K-EFFECTIVE',1,2,REAL(CFKEFFV(IMOD)))
         CALL LCMPUT(KPFLUX,'K-INFINITY',1,2,REAL(CFKEFFV(IMOD)))
*        STORE FLUX IN THE IGR-TH COMPONENT OF EACH LIST.
         DO 100 IGR=1,NGRP
         IF(CMODUL.EQ.'BIVAC') THEN
           CALL FLDBIV(IPTRK,NEL,NUN,EVECT(1,IGR),MAT,VOL,IDL)
         ELSE IF(CMODUL.EQ.'TRIVAC') THEN
           CALL FLDTRI(IPTRK,NEL,NUN,EVECT(1,IGR),MAT,VOL,IDL)
         ENDIF
  100    CONTINUE
         IF(IMOD.EQ.1) THEN
           CALL FLDNOR(IPSYS,NUN,NGRP,NEL,NBMIX,MAT,VOL,IDL,'DIRE',
     1     EVECT,DNORM)
         ELSE
           EVECT(:NUN,:NGRP)=EVECT(:NUN,:NGRP)*DNORM
         ENDIF
         MPFLUX=LCMLID(KPFLUX,'FLUX',NGRP)
         IF(LREL) CALL FLDREL(RELAX,MPFLUX,NGRP,NUN,EVECT) 
         DO 110 IGR=1,NGRP
         CALL LCMPDL(MPFLUX,IGR,NUN,2,EVECT(1,IGR))
  110    CONTINUE
  120    CONTINUE
         CALL LCMPUT(IPFLUX,'K-EFFECTIVE',1,2,REAL(CFKEFFV(1)))
         IF(.NOT.ADJ) GO TO 160
*
*        ADJOINT CALCULATION
         IF(CMODUL.NE.'TRIVAC') CALL XABORT('FLDDRV: ADJOINT CALCULATI'
     1   //'ON IS ONLY POSSIBLE WITH TRIVAC.')
         ISTATE(3)=10
         CALL LCMPUT(IPFLUX,'STATE-VECTOR',NSTATE,1,ISTATE)
         CALL FLDARN(FLDTMX,IPTRK,IPSYS,IPFLUX,LL4,NUN,NGRP,LMOD,IBLSZ,
     1   .TRUE.,IMPX,EPSOUT,MAXOUT,CEV,CFKEFFV)
         JPFLUX=LCMLID(IPFLUX,'MODE',LMOD)
         DO 150 IMOD=1,LMOD
         IF(AIMAG(CFKEFFV(IMOD)).NE.0.0) THEN
           WRITE(HSMG,'(7HFLDDRV:,I4,28H-TH ADJOINT MODE IS COMPLEX.)')
     1     IMOD
           CALL XABORT(HSMG)
         ENDIF
*        CREATE A DIRECTORY AT IMOD-TH LIST ELEMENT.
         KPFLUX=LCMDIL(JPFLUX,IMOD)
*        PUT NODES IN DIRECTORY KPFLUX.
         EVECT(:NUN,:NGRP)=REAL(CEV(:NUN,:NGRP,IMOD))
         CALL LCMPUT(KPFLUX,'AK-EFFECTIVE',1,2,REAL(CFKEFFV(IMOD)))
         CALL LCMPUT(KPFLUX,'AK-INFINITY',1,2,REAL(CFKEFFV(IMOD)))
*        STORE FLUX IN THE IGR-TH COMPONENT OF EACH LIST.
         DO 130 IGR=1,NGRP
           CALL FLDTRI(IPTRK,NEL,NUN,EVECT(1,IGR),MAT,VOL,IDL)
  130    CONTINUE
         IF(IMOD.EQ.1) THEN
           CALL FLDNOR(IPSYS,NUN,NGRP,NEL,NBMIX,MAT,VOL,IDL,'ADJO',
     1     EVECT,ANORM)
         ELSE
           EVECT(:NUN,:NGRP)=EVECT(:NUN,:NGRP)*ANORM
         ENDIF
         NPFLUX=LCMLID(KPFLUX,'AFLUX',NGRP)
         IF(LREL) CALL FLDREL(RELAX,NPFLUX,NGRP,NUN,EVECT) 
         DO 140 IGR=1,NGRP
         CALL LCMPDL(NPFLUX,IGR,NUN,2,EVECT(1,IGR))
  140    CONTINUE
  150    CONTINUE
  160    DEALLOCATE(CEV,CFKEFFV)
         IF(ADJ.AND.(IMPX.GT.1)) THEN
*          TEST ORTHOGONALITY OF EIGENVECTORS.
           CALL FLDORT(IPSYS,IPFLUX,NUN,NGRP,LMOD)
         ENDIF
      ELSE
*        DIRECT NEUTRON FLUX CALCULATION WITH SVAT.
         IF(CMODUL.EQ.'BIVAC') THEN
           CALL FLDSMB(IPTRK,IPSYS,IPFLUX,LL4,ITY,NUN,NGRP,ICL1,ICL2,
     1     IMPX,IMPH,TITR,EPSOUT,MAXOUT,MAXINR,EPSINR,EVECT,FKEFF)
           DO 210 IGR=1,NGRP
           CALL FLDBIV(IPTRK,NEL,NUN,EVECT(1,IGR),MAT,VOL,IDL)
  210      CONTINUE
         ELSE IF(CMODUL.EQ.'TRIVAC') THEN
           CALL FLDDIR(IPTRK,IPSYS,IPFLUX,LL4,ITY,NUN,NGRP,ICL1,ICL2,
     1     IMPX,IMPH,TITR,EPSOUT,NADI,MAXOUT,MAXINR,EPSINR,EVECT,FKEFF)
           DO 220 IGR=1,NGRP
           CALL FLDTRI(IPTRK,NEL,NUN,EVECT(1,IGR),MAT,VOL,IDL)
  220      CONTINUE
         ENDIF
         CALL FLDNOR(IPSYS,NUN,NGRP,NEL,NBMIX,MAT,VOL,IDL,'DIRE',EVECT,
     1   DNORM)
         CALL LCMPUT(IPFLUX,'K-EFFECTIVE',1,2,FKEFF)
         CALL LCMPUT(IPFLUX,'K-INFINITY',1,2,FKEFF)
         JPFLUX=LCMLID(IPFLUX,'FLUX',NGRP)
         IF(LREL) CALL FLDREL(RELAX,JPFLUX,NGRP,NUN,EVECT)        
         DO 230 IGR=1,NGRP
         CALL LCMPDL(JPFLUX,IGR,NUN,2,EVECT(1,IGR))
  230    CONTINUE
         IF(.NOT.ADJ) GO TO 280
*
         IF(CMODUL.NE.'TRIVAC') CALL XABORT('FLDDRV: ADJOINT CALCULATI'
     1   //'ON IS ONLY POSSIBLE WITH TRIVAC.')
*        ADJOINT FLUX INITIALIZATION.
         IF(REC.AND.(IMPH.EQ.0)) THEN
           CALL LCMLEN(IPFLUX,'AFLUX',ILONG,ITYLCM)
           IF(ILONG.NE.NGRP) CALL XABORT('FLDDRV: UNABLE TO RECOVER AF'
     1     //'LUX.')
           JPFLUX=LCMGID(IPFLUX,'AFLUX')
           DO 240 IGR=1,NGRP
           CALL LCMGDL(JPFLUX,IGR,EVECT(1,IGR))
  240      CONTINUE
         ELSE
*          INITIAL ESTIMATE OF THE ADJOINT FLUXES.
           CALL XDRSET(EVECT,NGRP*NUN,1.0)
         ENDIF
*
         CALL FLDADJ(IPTRK,IPSYS,IPFLUX,LL4,ITY,NUN,NGRP,ICL1,ICL2,IMPX,
     1   EPSOUT,NADI,MAXOUT,MAXINR,EPSINR,EVECT,FKEFF)
         CALL LCMPUT(IPFLUX,'AK-EFFECTIVE',1,2,FKEFF)
         CALL LCMPUT(IPFLUX,'AK-INFINITY',1,2,FKEFF)
         JPFLUX=LCMLID(IPFLUX,'AFLUX',NGRP)
         DO 260 IGR=1,NGRP
         CALL FLDTRI(IPTRK,NEL,NUN,EVECT(1,IGR),MAT,VOL,IDL)
  260    CONTINUE
         CALL FLDNOR(IPSYS,NUN,NGRP,NEL,NBMIX,MAT,VOL,IDL,'ADJO',EVECT,
     1   ANORM)
         IF(LREL) CALL FLDREL(RELAX,JPFLUX,NGRP,NUN,EVECT)        
         DO 270 IGR=1,NGRP
         CALL LCMPDL(JPFLUX,IGR,NUN,2,EVECT(1,IGR))
  270    CONTINUE
      ENDIF
*----
* SET STATE-VECTOR AND EPS-CONVERGE
*----
  280 CALL XDISET(ISTATE,NSTATE,0)
      ISTATE(1)=NGRP
      ISTATE(2)=NUN
      ISTATE(3)=1
      IF(ADJ) ISTATE(3)=11
      ISTATE(4)=LMOD
      ISTATE(5)=0
      ISTATE(6)=2
      ISTATE(7)=0
      ISTATE(8)=ICL1
      ISTATE(9)=ICL2
      ISTATE(10)=IREBAL
      ISTATE(11)=MAXINR
      ISTATE(12)=MAXOUT
      ISTATE(13)=NADI
      ISTATE(14)=IBLSZ
      ISTATE(15)=NSTARD
      CALL LCMPUT(IPFLUX,'STATE-VECTOR',NSTATE,1,ISTATE)
      EPSCON(1)=EPSINR
      EPSCON(2)=EPSOUT
      EPSCON(3)=EPSOUT
      EPSCON(4)=EPSMSR
      EPSCON(5)=RELAX
      CALL LCMPUT(IPFLUX,'EPS-CONVERGE',5,2,EPSCON)
*----
* PRINT STATE-VECTOR
*----
      IF(IMPX.GT.0) THEN
         WRITE (IOUT,300) IMPX,(ISTATE(I),I=1,15)
         WRITE (IOUT,310) (EPSCON(I),I=1,5)
      ENDIF
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(EVECT)
      RETURN
  300 FORMAT(/8H OPTIONS/8H -------/
     1 7H IMPX  ,I9,29H  (0=NO PRINT/1=SHORT/2=MORE)/
     2 7H NGRO  ,I9,27H  (NUMBER OF ENERGY GROUPS)/
     3 7H NUN   ,I9,39H  (NUMBER OF UNKNOWNS PER ENERGY GROUP)/
     4 7H IADJ  ,I9,42H  (1=DIRECT KEFF OR SOURCE/10=ADJOINT KEFF,
     5 31H100=DIRECT GPT/100=ADJOINT GPT)/
     6 7H LMOD  ,I9,23H  (NUMBER OF HARMONICS)/
     7 7H NGPT  ,I9,27H  (NUMBER OF GPT EQUATIONS)/
     8 7H ITYPE ,I9,46H  (TYPE OF SOLUTION: 0=FIXED SOURCE/1=FIXED SO,
     9 57HURCE EIGENVALUE/2=TYPE K/3=TYPE K BUCK/4=TYPE B/5=TYPE L)/
     1 7H ILEAK ,I9,25H  (TYPE OF LEAKAGE MODEL)/
     2 7H ICL1  ,I9,46H  (NUMBER OF FREE ITERATIONS PER ACCELERATION ,
     3 6HCYCLE)/
     4 7H ICL2  ,I9,46H  (NUMBER OF ACCELERATED ITERATIONS PER ACCELE,
     5 14H RATION CYCLE)/
     6 7H IREBAL,I9,34H  (0/1: THERMAL ITERATIONS OFF/ON)/
     7 7H MAXINR,I9,40H  (MAXIMUM NUMBER OF THERMAL ITERATIONS)/
     8 7H MAXOUT,I9,38H  (MAXIMUM NUMBER OF OUTER ITERATIONS)/
     9 7H NADI  ,I9,46H  (INITIAL NUMBER OF ADI ITERATIONS IN TRIVAC)/
     1 7H IBLSZ ,I9,46H  (BLOCK SIZE OF THE ARNOLDI HESSENBERG MATRIX,
     2 11H WITH IRAM)/
     3 7H NSTARD,I9,46H  (NUMBER OF RESTARTING ITERATIONS WITH GMRES ,
     4 51HFOR SOLVING THE ADI-PRECONDITIONNED LINEAR SYSTEMS))
  310 FORMAT(7H EPSINR,1P,E9.2,29H  (THERMAL ITERATION EPSILON)/
     1 7H EPSOUT,1P,E9.2,32H  (OUTER ITERATION KEFF EPSILON)/
     2 7H EPSOUT,1P,E9.2,32H  (OUTER ITERATION FLUX EPSILON)/
     3 7H EPSMSR,1P,E9.2,33H  (INNER ITERATION GMRES EPSILON)/
     4 7H RELAX ,1P,E9.2,21H  (RELAXATION FACTOR)/)
      END