*DECK QIJI3D
      SUBROUTINE QIJI3D(NREG,NSOUT,NPIJ,NGRP,MXSEG,NCOR,SWVOID,LINE,
     >                  WEIGHT,NUMERO,LENGHT,SIGTAL,NPSYS,DPR)
C
C-------------------------    QIJI3D    -------------------------------
C
C 1- SUBROUTINE STATISTICS:
C     NAME     : QIJI3D
C     LEVEL    : 2 (CALLED BY 'EXCELP')
C     USE      : INTEGRATION FOR GENERAL 3D ISOTROPIC B.C. TRACKING
C     MODIFIED : 91/07/12 (R.R.)
C     AUTHOR   : R. ROY
C
C 2- PARAMETERS:
C  INPUT
C     IFTRAK  : UNIT ASSOCIATED WITH TRACKING FILE      I
C     NREG    : TOTAL NUMBER OF REGIONS                 I
C     NSOUT   : NUMBER OF OUTER SURFACE                 I
C     NTRK    : NUMBER OF TRACKS                        I
C     NPIJ    : NUMBER OF PROBABILITIES IN ONE GROUP    I
C     MXSEG   : MAXIMUM SEGMENT LENGTH                  I
C     NCOR    : MAXIMUM NUMBER OF CORNERS               I
C     SWVOID  : FLAG TO INDICATE IF THERE ARE VOIDS     L
C     WEIGHT  : TRACK WEIGHT                            R
C     LENGHT  : RELATIVE LENGHT OF EACH SEGMENT         D(MXSEG)
C     NUMERO  : MATERIAL IDENTIFICATION OF EACH SEGMENT I(MXSEG)
C     SIGTAL  : ALBEDO-CROSS SECTION VECTOR             R(-NSOUT:NREG)
C               IS=-NSOUT,-1; SIGTAL(IS)=ALBEDO(-IS)
C               IV=1,NREG ;   SIGTAL(IV)=SIGT(IV)
C     NPSYS   : NON-CONVERGED ENERGY GROUP INDICES.     I(NGRP)
C
C  OUTPUT
C     DPR     : COLLISION PROBABILITIES                 D(NPIJ,NGRP)
C
C-------------------------    QIJI3D    -------------------------------
C
      IMPLICIT          NONE
      INTEGER           NREG,NSOUT,NPIJ,NGRP,MXSEG,NCOR, NUMERO(*),
     >                  ISD(6),ISF(6),LIN2C,IL,JL,IG,LINE,NOIL,IND1,
     >                  IND2,I,J,IN0,IN1,IN2,NPSYS(NGRP),NUNK
      REAL              WEIGHT, SIGTAL(-NSOUT:NREG,NGRP)
      DOUBLE PRECISION  LENGHT(*), DPR(NPIJ,NGRP), XSIL, XSIL2
      LOGICAL           SWVOID
      REAL              ZERO, ONE, HALF
      PARAMETER       ( ZERO=0.0E0, ONE=1.0E0, HALF=0.5E0)
      REAL              SIXT,CUTEXP
      PARAMETER       ( CUTEXP=0.02)
C
C Allocated arrays
      INTEGER, ALLOCATABLE, DIMENSION(:) :: NRSEG
      DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:) :: DSCBEG, DSCEND,
     > SEGLEN, PRODUC
      DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:) :: STAYIN, GOSOUT
      
      IN0(I)   = ((I+NSOUT+1)*(I+NSOUT+2))/2
      IN1(I,J) = ((I+NSOUT+1)*(I+NSOUT))/2 + (J+NSOUT+1)
      IN2(I,J) = (MAX(I+NSOUT+1,J+NSOUT+1)*
     >           (MAX(I+NSOUT+1,J+NSOUT+1)-1))/2
     >          + MIN(I+NSOUT+1,J+NSOUT+1) 
C
C Scratch storage allocation
      ALLOCATE(NRSEG(MXSEG))
      ALLOCATE(DSCBEG(NGRP), DSCEND(NGRP), SEGLEN(MXSEG), PRODUC(NGRP))
      ALLOCATE(STAYIN(NGRP,MXSEG),GOSOUT(NGRP,MXSEG))
C
      SIXT=HALF/3.0
      NUNK=NSOUT+NREG+1
C
C  0) REFORMAT TRACKING LINE
      LIN2C= LINE-2*NCOR
      DO 10 JL= 1, NCOR
         ISD(JL)= NUMERO(JL)
         ISF(JL)= NUMERO(NCOR+LIN2C+JL)
   10 CONTINUE
      DO 20 IL= 1, LIN2C
         NRSEG(IL)=  NUMERO(NCOR+IL)
         SEGLEN(IL)= LENGHT(NCOR+IL)
   20 CONTINUE
      DO 90 IG= 1, NGRP
         PRODUC(IG)= WEIGHT
   90 CONTINUE
C
      IF( SWVOID )THEN
C
C  1) VOIDS ARE POSSIBLE
C        PII CALCULATION AND ESCAPE
         DO 240 IL = 1,LINE-2*NCOR
            NOIL  = NRSEG(IL)
            IND1  = IN0(NOIL)
            DO 100 IG= 1, NGRP
               IF(NPSYS(IG).EQ.0) GO TO 100
               XSIL=SIGTAL(NOIL,IG)*SEGLEN(IL)
               IF( XSIL.EQ.ZERO )THEN
                  GOSOUT(IG,IL)= ONE
                  STAYIN(IG,IL)= SEGLEN(IL)
                  DPR(IND1,IG)= DPR(IND1,IG)
     >                       + HALF*WEIGHT*SEGLEN(IL)*SEGLEN(IL)
               ELSE IF(XSIL .LT. CUTEXP) THEN
                  XSIL2=XSIL*XSIL
                  STAYIN(IG,IL)=XSIL-XSIL2*(HALF-SIXT*XSIL)
                  GOSOUT(IG,IL)=ONE-STAYIN(IG,IL)
                  PRODUC(IG)= PRODUC(IG) * GOSOUT(IG,IL)
                  DPR(IND1,IG)= DPR(IND1,IG)
     >             + WEIGHT*XSIL2*(HALF-SIXT*XSIL)
               ELSE
                  GOSOUT(IG,IL)= EXP( -XSIL )
                  STAYIN(IG,IL)= (ONE - GOSOUT(IG,IL))
                  PRODUC(IG)= PRODUC(IG) * GOSOUT(IG,IL)
                  DPR(IND1,IG)= DPR(IND1,IG)
     >             + WEIGHT*(XSIL-STAYIN(IG,IL))
               ENDIF
  100       CONTINUE
  240    CONTINUE
      ELSE
         DO 241 IL = 1,LINE-2*NCOR
            NOIL  = NRSEG(IL)
            IND1  = IN0(NOIL)
            DO 101 IG= 1, NGRP
               IF(NPSYS(IG).EQ.0) GO TO 101
               XSIL=SIGTAL(NOIL,IG)*SEGLEN(IL)
               IF(XSIL .LT. CUTEXP) THEN
                  XSIL2=XSIL*XSIL
                  STAYIN(IG,IL)=XSIL-XSIL2*(HALF-SIXT*XSIL)
                  GOSOUT(IG,IL)=ONE-STAYIN(IG,IL)
                  PRODUC(IG)= PRODUC(IG) * GOSOUT(IG,IL)
                  DPR(IND1,IG)= DPR(IND1,IG)
     >             + WEIGHT*XSIL2*(HALF-SIXT*XSIL)
               ELSE
                GOSOUT(IG,IL)= EXP( -XSIL )
                STAYIN(IG,IL)= (ONE - GOSOUT(IG,IL))
                PRODUC(IG)= PRODUC(IG) * GOSOUT(IG,IL)
                DPR(IND1,IG)= DPR(IND1,IG)
     >           + WEIGHT*(XSIL-STAYIN(IG,IL))
               ENDIF
  101       CONTINUE
  241    CONTINUE
      ENDIF
C        PIJ CALCULATION
      DO 120 IG= 1, NGRP
         DSCBEG(IG)= WEIGHT
  120 CONTINUE
      DO 260 IL = 1, LINE-2*NCOR
         NOIL  = NRSEG(IL)
         DO 130 IG= 1, NGRP
            IF(NPSYS(IG).NE.0) DSCEND(IG)= WEIGHT*STAYIN(IG,IL)
  130    CONTINUE
         DO 250 JL  = IL+1, LINE-2*NCOR
            IND2= IN2(NRSEG(JL),NOIL)
            DO 140 IG= 1, NGRP
               IF(NPSYS(IG).EQ.0) GO TO 140
               DPR(IND2,IG)= DPR(IND2,IG) + STAYIN(IG,JL)*DSCEND(IG)
               DSCEND(IG)= DSCEND(IG)*GOSOUT(IG,JL)
  140       CONTINUE
  250    CONTINUE
C           PIS CALCULATION
         DO 261 JL = 1, NCOR
            IND1= IN1(NOIL,ISD(JL))
            IND2= IN1(NOIL,ISF(JL))
            DO 150 IG= 1, NGRP
               IF(NPSYS(IG).EQ.0) GO TO 150
               DPR(IND1,IG)= DPR(IND1,IG) + DSCBEG(IG)*STAYIN(IG,IL)
               DPR(IND2,IG)= DPR(IND2,IG) + DSCEND(IG)
  150       CONTINUE
  261    CONTINUE
         DO 160 IG= 1, NGRP
            IF(NPSYS(IG).NE.0) DSCBEG(IG)= DSCBEG(IG)*GOSOUT(IG,IL)
  160    CONTINUE
  260 CONTINUE
C        PSS CALCULATION
      DO 265 IL = 1, NCOR
        DO 264 JL = 1, NCOR
          IND2= IN2(ISD(IL),ISF(JL))
          DO 170 IG = 1, NGRP
            IF(NPSYS(IG).NE.0) DPR(IND2,IG)= DPR(IND2,IG) + PRODUC(IG)
  170     CONTINUE
  264   CONTINUE
  265 CONTINUE
C
C Scratch storage deallocation
      DEALLOCATE(GOSOUT,STAYIN)
      DEALLOCATE(PRODUC,SEGLEN,DSCEND,DSCBEG)
      DEALLOCATE(NRSEG)
C
      RETURN
      END
