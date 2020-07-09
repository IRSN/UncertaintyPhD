*DECK SNFTH1
      SUBROUTINE SNFTH1(NHEX,IELEM,ISPLH,NMAT,NPQ,NSCT,MAT,VOL,TOTAL,
     1 QEXT,DU,DE,W,DB,DA,PL,FLUX,CONNEC,IZGLOB,SIDE,CONFROM)
*
*-----------------------------------------------------------------------
*
*Purpose:
* perform one inner iteration for solving SN equations in 2D hexagonal
* geometry for the High Order DIAMOND DIFFERENCE method. VOID boundary
* conditions.
*
*Copyright:
* Copyright (C) 2019 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. A. Calloo
*
*Parameters: input
* NHEX    number of hexagons in X-Y plane.
* IELEM   measure of order of the spatial approximation polynomial:
*         =1: constant - only for HODD, classical diamond scheme
*             - default for HODD;
*         =2: linear - default for DG;
*         =3: parabolic;
*         =4: cubic - only for DG.
* NMAT    number of material mixtures.
* NPQ     number of SN directions in four octants (including zero-weight
*         directions).
* NSCT    maximum number of spherical harmonics moments of the flux.
* MAT     material mixture index in each region.
* VOL     volumes of each region.
* TOTAL   macroscopic total cross sections.
* NCODE   boundary condition indices.
* ZCODE   albedos.
* QEXT    Legendre components of the fixed source.
* LFIXUP  flag to enable negative flux fixup.
* DU      first direction cosines ($\mu$).
* DE      second direction cosines ($\eta$).
* W       weights.
* MRM     quadrature index.
* MRMY    quadrature index.
* DB      diamond-scheme parameter.
* DA      diamond-scheme parameter.
* PL      discrete values of the spherical harmonics corresponding
*         to the 2D SN quadrature.
* XNEI    X-directed SN boundary fluxes.
* XNEJ    Y-directed SN boundary fluxes.
* IZGLOB  hexagon sweep order depending on direction
* CONNEC  connectivity matrix for flux swapping -- which lozenges is the
*         lozenge under consideration connected to; in order to pass the
*         flux along. This is dependent on direction
* CONFROM matrix for incoming flux -- which lozenges are feeding into
*         the lozenge under consideration. This is dependent on
*         direction
*
*Parameters: output
* FLUX    Legendre components of the flux.
*
*-----------------------------------------------------------------------
*
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER NHEX, IELEM, ISPLH, NMAT, NPQ, NSCT,IZGLOB(NHEX,6),
     1 MAT(ISPLH,ISPLH,3,NHEX),CONNEC(3,(NHEX*3)*2,6),CONFROM(2,3,6)
      REAL SIDE,VOL(ISPLH,ISPLH,3,NHEX), TOTAL(0:NMAT),
     1 QEXT(IELEM**2,NSCT,ISPLH,ISPLH,3,NHEX), DU(NPQ),
     2 DB(ISPLH,ISPLH,3,NHEX,NPQ), DA(ISPLH,ISPLH,3,NHEX,NPQ),
     3 PL(NSCT,NPQ), DE(NPQ), W(NPQ),
     4 FLUX(IELEM**2,NSCT,ISPLH,ISPLH,3,NHEX)
*----
*  LOCAL VARIABLES
*----
      DOUBLE PRECISION Q(IELEM**2), Q2(IELEM**2,(IELEM**2)+1),
     1   CONST0, CONST1, CONST2
      PARAMETER(RLOG=1.0E-8,PI=3.141592654)
      INTEGER :: ILOZSWP(3,6), IFROMI, IFROMJ
      REAL :: JAC(2,2,3), MUH, ETAH, AAA, BBB, CCC, DDD, MUHTEMP,
     1 ETAHTEMP
      DOUBLE PRECISION :: THETA, XNI(IELEM,ISPLH), XNJ(IELEM), C1
      DOUBLE PRECISION, ALLOCATABLE, DIMENSION(:,:,:,:) :: BFLUX
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(BFLUX(2,NHEX*3,ISPLH,IELEM))
*----
*  CONSTRUCT JACOBIAN MATRIX FOR EACH LOZENGE
*----
      ILOZSWP = RESHAPE((/ 3, 2, 1, 3, 1, 2, 1, 3, 2, 1, 2, 3, 2, 1,
     1   3, 2, 3, 1 /), SHAPE(ILOZSWP))
      JAC = RESHAPE((/ 1., -SQRT(3.), 1., SQRT(3.), 2., 0., 1.,
     1    SQRT(3.), 2., 0., -1., SQRT(3.) /), SHAPE(JAC))
      JAC = (SIDE/2.)*JAC
*----
*  DEFINITION OF CONSTANTS.
*----
      CONST0=2.0D0*DSQRT(3.0D0)
      CONST1=2.0D0*DSQRT(5.0D0)
      CONST2=2.0D0*DSQRT(15.0D0)
*----
*  PARAMETER VALIDATION.
*----
      IF((IELEM.LT.1).OR.(IELEM.GT.3))
     1   CALL XABORT('SNFTH1: INVALID IELEM (DIAM) VALUE. '
     2   //'CHECK INPUT DATA FILE.')
*----
*  MAIN LOOP OVER SN ANGLES.
*----
      CALL XDRSET(FLUX,IELEM*IELEM*NHEX*(3*ISPLH**2)*NSCT,0.0)

      DO 210 M=1,NPQ
      WEIGHT=W(M)
      VU=DU(M)
      VE=DE(M)

      IF(WEIGHT.EQ.0.0) GO TO 210
*
      THETA=0.0D0
      IF(VE.GT.0.0)THEN
         IF(VU.EQ.0.0)THEN
            THETA = PI/2
         ELSEIF(VU.GT.0.0)THEN
            THETA = ATAN(ABS(VE/VU))
         ELSEIF(VU.LT.0.0)THEN
            THETA = PI - ATAN(ABS(VE/VU))
         ENDIF
      ELSEIF(VE.LT.0.0)THEN
         IF(VU.EQ.0.0)THEN
            THETA = 3*PI/2
         ELSEIF(VU.LT.0.0)THEN
            THETA = PI + ATAN(ABS(VE/VU))
         ELSEIF(VU.GT.0.0)THEN
            THETA = 2.*PI - ATAN(ABS(VE/VU))
         ENDIF
      ENDIF

      IND=0
      IF((THETA.GT.0.0).AND.(THETA.LT.(PI/3.)))THEN
         IND=1
      ELSEIF((THETA.GT.(PI/3.)).AND.(THETA.LT.(2.*PI/3.)))THEN
         IND=2
      ELSEIF((THETA.GT.(2.*PI/3.)).AND.(THETA.LT.(PI)))THEN
         IND=3
      ELSEIF((THETA.GT.(PI)).AND.(THETA.LT.(4.*PI/3.)))THEN
         IND=4
      ELSEIF((THETA.GT.(4.*PI/3.)).AND.(THETA.LT.(5.*PI/3.)))THEN
         IND=5
      ELSEIF((THETA.GT.(5.*PI/3.)).AND.(THETA.LT.(2.*PI)))THEN
         IND=6
      ENDIF

      IF(VE.GT.0.0) GOTO 70
      IF(VU.GT.0.0) GOTO 60
      IND2=3
      GOTO 90
   60 IND2=4
      GOTO 90
   70 IF(VU.GT.0.0) GOTO 80
      IND2=2
      GOTO 90
   80 IND2=1

   90 BFLUX = 0.0D0
*
*----
*  LOOP OVER X- AND Y-DIRECTED AXES.
*----
* SECOND loop over hexagons
      DO 190 IZ=1,NHEX
      I=IZGLOB(IZ,IND)

* THIRD loop over lozenges
      DO 180 JJ=1,3
      J=ILOZSWP(JJ,IND)
*
      AAA = JAC(1,1,J)
      BBB = JAC(1,2,J)
      CCC = JAC(2,1,J)
      DDD = JAC(2,2,J)
*
      IHEXI  = CONNEC(1,((I-1)*3*2) + ((J-1)*2) +1,IND)
      ILOZI  = CONNEC(2,((I-1)*3*2) + ((J-1)*2) +1,IND)
      ISIDEI = CONNEC(3,((I-1)*3*2) + ((J-1)*2) +1,IND)
      IHEXJ  = CONNEC(1,((I-1)*3*2) + ((J-1)*2) +2,IND)
      ILOZJ  = CONNEC(2,((I-1)*3*2) + ((J-1)*2) +2,IND)
      ISIDEJ = CONNEC(3,((I-1)*3*2) + ((J-1)*2) +2,IND)
      IFROMI = CONFROM(1,J,IND)
      IFROMJ = CONFROM(2,J,IND)
      INDEXI = ((IHEXI-1)*3)+ILOZI
      INDEXJ = ((IHEXJ-1)*3)+ILOZJ
*
      DO 170 IL=1,ISPLH
      I2=IL
      IF(CONFROM(1,J,IND).EQ.3) I2=ISPLH+1-IL

      DO IEL=1,IELEM
         XNJ(IEL) = BFLUX(2,((I-1)*3)+J,I2,IEL)
      ENDDO

      DO 160 JL=1,ISPLH
      J2=JL
      IF(CONFROM(2,J,IND).EQ.4) J2=ISPLH+1-JL

      IF(IL.EQ.1)THEN
         DO IEL=1,IELEM
            XNI(IEL,J2) = BFLUX(1,((I-1)*3)+J,J2,IEL)
         ENDDO
      ENDIF
*
      MUHTEMP  =  DA(I2,J2,J,I,M)
      ETAHTEMP =  DB(I2,J2,J,I,M)
      MUH = (MUHTEMP*DDD) - (ETAHTEMP*BBB)
      ETAH = (-MUHTEMP*CCC) + (ETAHTEMP*AAA)
*
      IF(MAT(I2,J2,J,I).EQ.0) GO TO 180

*     -----------------------------------------------------
      DO 115 IEL=1,IELEM**2
      Q(IEL)=0.0
      DO 110 K=1,NSCT
      Q(IEL)=Q(IEL)+QEXT(IEL,K,I2,J2,J,I)*PL(K,M)/(4.0*PI)
  110 CONTINUE
  115 CONTINUE
*                  ---------------------------------------------------
*
      VT=VOL(I2,J2,J,I)*TOTAL(MAT(I2,J2,J,I))
      CALL XDDSET(Q2,(IELEM**2)*((IELEM**2)+1),0.0D0)
*
*     -----------------------------------------------------
      IF(IELEM.EQ.1) THEN
         Q2(1,1)= 2.0D0*ABS(MUH) + 2.0D0*ABS(ETAH) + VT
*        ------
         Q2(1,2)= 2.0D0*ABS(MUH)*XNI(1,J2) + 2.0D0*ABS(ETAH)*XNJ(1)
     1            + VOL(I2,J2,J,I)*Q(1)
*        ------
      ELSE IF(IELEM.EQ.2) THEN
         Q2(1,1)=VT
         Q2(2,1)=CONST0*MUH
         Q2(2,2)=-VT-6.0D0*ABS(MUH)
         Q2(3,1)=CONST0*ETAH
         Q2(3,3)=-VT-6.0D0*ABS(ETAH)
         Q2(4,2)=-CONST0*ETAH
         Q2(4,3)=-CONST0*MUH
         Q2(4,4)=VT+6.0D0*ABS(MUH)+6.0D0*ABS(ETAH)
*        ------
         Q2(1,5)=VOL(I2,J2,J,I)*Q(1)
         Q2(2,5)=-VOL(I2,J2,J,I)*Q(2)+CONST0*MUH*XNI(1,J2)
         Q2(3,5)=-VOL(I2,J2,J,I)*Q(3)+CONST0*ETAH*XNJ(1)
         Q2(4,5)=VOL(I2,J2,J,I)*Q(4)-CONST0*MUH*XNI(2,J2)-CONST0*
     1           ETAH*XNJ(2)
      ELSE IF(IELEM.EQ.3) THEN
         Q2(1,1)=VT+2.0D0*ABS(MUH)+2.0D0*ABS(ETAH)
         Q2(2,2)=-VT-2.0D0*ABS(ETAH)
         Q2(3,1)=CONST1*ABS(MUH)
         Q2(3,2)=-CONST2*MUH
         Q2(3,3)=VT+1.0D1*ABS(MUH)+2.0D0*ABS(ETAH)
         Q2(4,4)=-VT-2.0D0*ABS(MUH)
         Q2(5,5)=VT
         Q2(6,4)=-CONST1*ABS(MUH)
         Q2(6,5)=CONST2*MUH
         Q2(6,6)=-VT-1.0D1*ABS(MUH)
         Q2(7,1)=CONST1*ABS(ETAH)
         Q2(7,4)=-CONST2*ETAH
         Q2(7,7)=VT+2.0D0*ABS(MUH)+1.0D1*ABS(ETAH)
         Q2(8,2)=-CONST1*ABS(ETAH)
         Q2(8,5)=CONST2*ETAH
         Q2(8,8)=-VT-1.0D1*ABS(ETAH)
         Q2(9,3)=CONST1*ABS(ETAH)
         Q2(9,6)=-CONST2*ETAH
         Q2(9,7)=CONST1*ABS(MUH)
         Q2(9,8)=-CONST2*MUH
         Q2(9,9)=VT+1.0D1*ABS(MUH)+1.0D1*ABS(ETAH)
*        ------
         Q2(1,10)=VOL(I2,J2,J,I)*Q(1)+2.0D0*ABS(MUH)*XNI(1,J2)+2.0D0*
     1            ABS(ETAH)*XNJ(1)
         Q2(2,10)=-VOL(I2,J2,J,I)*Q(2)-2.0D0*ABS(ETAH)*XNJ(2)
         Q2(3,10)=VOL(I2,J2,J,I)*Q(3)+CONST1*ABS(MUH)*XNI(1,J2)+2.0D0*
     1            ABS(ETAH)*XNJ(3)
         Q2(4,10)=-VOL(I2,J2,J,I)*Q(4)-2.0D0*ABS(MUH)*XNI(2,J2)
         Q2(5,10)=VOL(I2,J2,J,I)*Q(5)
         Q2(6,10)=-VOL(I2,J2,J,I)*Q(6)-CONST1*ABS(MUH)*XNI(2,J2)
         Q2(7,10)=VOL(I2,J2,J,I)*Q(7)+2.0D0*ABS(MUH)*XNI(3,J2)+CONST1*
     1            ABS(ETAH)*XNJ(1)
         Q2(8,10)=-VOL(I2,J2,J,I)*Q(8)-CONST1*ABS(ETAH)*XNJ(2)
         Q2(9,10)=VOL(I2,J2,J,I)*Q(9)+CONST1*ABS(MUH)*XNI(3,J2)+CONST1*
     1            ABS(ETAH)*XNJ(3)
      ENDIF
      DO 125 IEL=1,IELEM**2
      DO 120 JEL=IEL+1,IELEM**2
      Q2(IEL,JEL)=Q2(JEL,IEL)
  120 CONTINUE
  125 CONTINUE
*
      CALL ALSBD(IELEM**2,1,Q2,IER,IELEM**2)
      IF(IER.NE.0) CALL XABORT('SNFTH1: SINGULAR MATRIX.')
*
      IF(JL.LT.ISPLH)THEN
      IF(IELEM.EQ.1) THEN
         XNJ(1) = 2.0D0*Q2(1,2)-XNJ(1)
      ELSEIF(IELEM.EQ.2) THEN
         XNJ(1)=XNJ(1)+SIGN(1.0,ETAH)*CONST0*Q2(3,5)
         XNJ(2)=XNJ(2)+SIGN(1.0,ETAH)*CONST0*Q2(4,5)
      ELSEIF(IELEM.EQ.3) THEN
         XNJ(1)=2.0D0*Q2(1,10)+CONST1*Q2(7,10)-XNJ(1)
         XNJ(2)=2.0D0*Q2(2,10)+CONST1*Q2(8,10)-XNJ(2)
         XNJ(3)=2.0D0*Q2(3,10)+CONST1*Q2(9,10)-XNJ(3)
      ENDIF
      ELSEIF((JL.EQ.ISPLH).AND.(IHEXJ.LE.NHEX))THEN
      I3=I2
      C1=1.0D0
      IF((J.EQ.1).AND.(ILOZJ.EQ.3)) THEN
         I3=ISPLH+1 -I2
         C1=-1.0D0
      ENDIF
      IF(IELEM.EQ.1) THEN
         BFLUX(ISIDEJ,INDEXJ,I3,1) = 2.0D0*Q2(1,2)-XNJ(1)
      ELSEIF(IELEM.EQ.2) THEN
      BFLUX(ISIDEJ,INDEXJ,I3,1)=XNJ(1)+SIGN(1.0,ETAH)*CONST0*Q2(3,5)
      BFLUX(ISIDEJ,INDEXJ,I3,2)=(XNJ(2)+SIGN(1.0,ETAH)*CONST0*Q2(4,5))
     1 *C1
      ELSEIF(IELEM.EQ.3) THEN
      BFLUX(ISIDEJ,INDEXJ,I3,1)=2.0D0*Q2(1,10)+CONST1*Q2(7,10)-XNJ(1)
      BFLUX(ISIDEJ,INDEXJ,I3,2)=(2.0D0*Q2(2,10)+CONST1*Q2(8,10)-XNJ(2))
     1 *C1
      BFLUX(ISIDEJ,INDEXJ,I3,3)=2.0D0*Q2(3,10)+CONST1*Q2(9,10)-XNJ(3)
      ENDIF
      ENDIF
*
      IF(IL.LT.ISPLH)THEN
      IF(IELEM.EQ.1) THEN
         XNI(1,J2) = 2.0D0*Q2(1,2)-XNI(1,J2)
      ELSEIF(IELEM.EQ.2) THEN
         XNI(1,J2)=XNI(1,J2)+SIGN(1.0,MUH)*CONST0*Q2(2,5)
         XNI(2,J2)=XNI(2,J2)+SIGN(1.0,MUH)*CONST0*Q2(4,5)
      ELSEIF(IELEM.EQ.3) THEN
         XNI(1,J2)=2.0D0*Q2(1,10)+CONST1*Q2(3,10)-XNI(1,J2)
         XNI(2,J2)=2.0D0*Q2(4,10)+CONST1*Q2(6,10)-XNI(2,J2)
         XNI(3,J2)=2.0D0*Q2(7,10)+CONST1*Q2(9,10)-XNI(3,J2)
      ENDIF
      ELSEIF((IL.EQ.ISPLH).AND.(IHEXI.LE.NHEX))THEN
      J3=J2
      C1=1.0D0
      IF((J.EQ.3).AND.(ILOZI.EQ.1)) THEN
         J3=ISPLH+1-J2
         C1=-1.0D0
      ENDIF
      IF(IELEM.EQ.1) THEN
         BFLUX(ISIDEI,INDEXI,J3,1) = 2.0D0*Q2(1,2)-XNI(1,J2)
      ELSEIF(IELEM.EQ.2) THEN
      BFLUX(ISIDEI,INDEXI,J3,1)=XNI(1,J2)+SIGN(1.0,MUH)*CONST0*Q2(2,5)
      BFLUX(ISIDEI,INDEXI,J3,2)=(XNI(2,J2)+SIGN(1.0,MUH)*CONST0*Q2(4,5)
     1 )*C1
      ELSEIF(IELEM.EQ.3) THEN
      BFLUX(ISIDEI,INDEXI,J3,1)=2.0D0*Q2(1,10)+CONST1*Q2(3,10)-XNI(1,J2)
      BFLUX(ISIDEI,INDEXI,J3,2)=(2.0D0*Q2(4,10)+CONST1*Q2(6,10)-
     1 XNI(2,J2))*C1
      BFLUX(ISIDEI,INDEXI,J3,3)=2.0D0*Q2(7,10)+CONST1*Q2(9,10)-XNI(3,J2)
      ENDIF
      ENDIF
*
      DO 135 K=1,NSCT
      DO 130 IEL=1,IELEM**2
      FLUX(IEL,K,I2,J2,J,I) = FLUX(IEL,K,I2,J2,J,I) +
     1   2.0*W(M)*REAL(Q2(IEL,IELEM**2+1))*PL(K,M)
  130 CONTINUE
  135 CONTINUE
*
  160 CONTINUE
  170 CONTINUE
  180 CONTINUE
  190 CONTINUE
  210 CONTINUE
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(BFLUX)
      RETURN
      END
