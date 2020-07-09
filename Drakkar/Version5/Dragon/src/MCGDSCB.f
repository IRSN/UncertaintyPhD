*DECK MCGDSCB
      SUBROUTINE MCGDSCB(M,N,LPS,IS,JS,H,NOM,NZON,TR,W,NFI,NREG,PJJ,PSJ,
     1                   IMU,NMU,NFUNL,NMOD,NPJJM,TRHAR,LPJJAN,PJJIND,
     2                   MODST,OMEGA2,PJJX,PJJY,PJJZ,PJJXI,PJJYI,PJJZI,
     3                   PSJX,PSJY,PSJZ)
*
*-----------------------------------------------------------------------
*
*Purpose:
* Calculation of contribution in PJJ and PSJ coefficients on one track,
* as well as directional values for TIBERE.
* Step-Characteristics scheme with tabulated exponential calls.
*
*Copyright:
* Copyright (C) 2019 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): S. Musongela
*
*Parameters: input
* LPS     first dimension of PSJ.
* M       number of material mixtures.
* N       number of elements for this track.
* IS      arrays for surfaces neighbors
* JS      JS(IS(ISOUT)+1:IS(ISOUT+1)) give the neighboring regions to
*         surface ISOUT.
* NOM     integer tracking elements.
* NZON    index-number of the mixture type assigned to each volume.
* TR      macroscopic total cross section.
* W       weight associated with this track.
* NFI     total number of volumes and surfaces for which specific values
*         of the neutron flux and reactions rates are required.
* NREG    number of volumes for which specific values
*         of the neutron flux and reactions rates are required.
* LEXAC   type of exponential function calculation (=.false. to compute
*         exponential functions using tables).
* IMU     polar angle index.
* NMU     order of the polar quadrature set.
* NFUNL   number of moments of the flux (in 2D : NFUNL=NANI*(NANI+1)/2).
* NMOD    first dimension of ISGNR.
* NPJJM   number of pjj modes to store for LPJJAN option.
* TRHAR   spherical harmonics components for this azimuthal angle in the
*         plan.
* LPJJAN  flag for the calculation of anisotropic moments of the pjj.
* PJJIND  index of the modes for LPJJAN option.
* MODST   starting angular mode index.
* OMEGA2  square x, y and z-component of the direction
*         Omega for 2D geometry
*
*Parameters: input/output
* PJJ     collision probabilities
* PJJX,PJJY,PJJZ,PJJXI,PJJYI,PJJZI collision probabilities for TIBERE
* PSJ     escape probabilities
* PSJX,PSJY,PSJZ escape probabilities for TIBERE
*
*Parameters: scratch
* H
*
*-----------------------------------------------------------------------
*
      IMPLICIT NONE
*---
* SUBROUTINE ARGUMENTS
*---
      INTEGER M,N,NFI,NREG,LPS,IS(NFI-NREG+1),JS(LPS),NZON(NFI),NOM(N),
     1 IMU,NMU,NFUNL,NMOD,NPJJM,PJJIND(NPJJM,2),MODST
      REAL TR(0:M),PSJ(LPS),TRHAR(NMU,NFUNL,NMOD)
      REAL PSJX(LPS),PSJY(LPS),PSJZ(LPS)
      DOUBLE PRECISION W,H(N),PJJ(NREG,NPJJM),OMEGA2(3)
      DOUBLE PRECISION PJJX(NREG,NPJJM),PJJY(NREG,NPJJM),
     1 PJJZ(NREG,NPJJM),PJJXI(NREG,NPJJM),PJJYI(NREG,NPJJM),
     2 PJJZI(NREG,NPJJM)
      LOGICAL LPJJAN
*---
* LOCAL VARIABLES
*---
      DOUBLE PRECISION TAUDMIN
      PARAMETER(TAUDMIN=2.D-2)
      INTEGER J,I,NOMI,IC,NZI,NOMJ,I0P,NOLDP,IFACE,IMOD,INU,INUP
      DOUBLE PRECISION TRI,TRJ,TAU,EXPT,HI,HJ,HID,TAUD,TAUD3,TAUD4,
     1 TAUD5,EXPTD,TEMPD
*     tabulated exponential common block
      REAL             E0, E1, PAS1, DX1, XLIM1
      INTEGER          MEX1, LAU
      PARAMETER      ( MEX1=7936 )
      COMMON /EXP1/ E0(0:MEX1),E1(0:MEX1),PAS1,DX1,XLIM1
*
      INTEGER   NEWMOD(8,3)
      DATA      NEWMOD/ 2,1,4,3,6,5,8,7,
     >                  3,4,1,2,7,8,5,6,
     >                  5,6,7,8,1,2,3,4 /
      SAVE      NEWMOD
*
      I0P=MODST
      NOLDP=NOM(1)
      DO I=1,N
         NOMI=NOM(I)
         NZI=NZON(NOMI)
         HI=H(I)
         IF(NZI.LT.0) THEN
*        Boundary Condition
            IF((LPJJAN).AND.(NOLDP.NE.NOMI)) THEN
               IFACE=(1-NZI)/2
               I0P=NEWMOD(I0P,IFACE)
            ENDIF
            NOLDP=NOMI
            IF(LPS.GT.0) THEN
*           SCR for a non-cyclic tracking
               IF(I.EQ.1) THEN
                  J=I+1
               ELSE !! I.EQ.N
                  J=I-1
               ENDIF
               NOMJ=NOM(J)
               DO IC=IS(NOMI-NREG)+1,IS(NOMI-NREG+1)
                  IF(JS(IC).EQ.NOMJ) GOTO 10
               ENDDO
 10            HJ=H(J)
               TRJ=TR(NZON(NOMJ))
               TAU=HJ*TRJ
               IF(TAU.GE.XLIM1) THEN
                  EXPT=1.0/TRJ
               ELSE
                  LAU=INT(TAU*PAS1)
                  EXPT=HJ*(E0(LAU)+E1(LAU)*TAU)
               ENDIF
               PSJ(IC)=PSJ(IC)+REAL(W*EXPT)
               PSJX(IC)=PSJX(IC)+REAL(W*EXPT*3.0*OMEGA2(1))
               PSJY(IC)=PSJY(IC)+REAL(W*EXPT*3.0*OMEGA2(2))
               PSJZ(IC)=PSJZ(IC)+REAL(W*EXPT*3.0*OMEGA2(3))
            ENDIF
         ELSE
*        this cell is a volume
            TRI=TR(NZI)
            HID=HI
            TAUD=HI*TRI
            TAU=REAL(TAUD)
            IF(TAUD.LE.TAUDMIN) THEN
*           expansion in Taylor serie in O(TAUD^3)
               TAUD3=TAUD/3.D0
               TAUD4=0.125D0*TAUD
               TAUD5=0.2D0*TAUD
               EXPTD=HID*(0.5D0-TAUD3*(0.5D0-TAUD4*(1.D0-TAUD5)))
            ELSE
               IF(TAU.GE.XLIM1) THEN
*              Out of the table range
                  EXPTD=(1.D0-1.D0/TAUD)/DBLE(TRI)
               ELSE
*              Linear interpolation in table of (1-exp(-x))/x
                  LAU=INT(TAU*PAS1)
                  EXPTD=(1.D0-DBLE(E0(LAU)+E1(LAU)*TAU))/DBLE(TRI)
               ENDIF
            ENDIF
            EXPTD=EXPTD*W*HID
            IF(LPJJAN) THEN
               DO IMOD=1,NPJJM
                  INU=PJJIND(IMOD,1)
                  INUP=PJJIND(IMOD,2)
                  TEMPD=DBLE(TRHAR(IMU,INU,I0P))*
     1                  DBLE(TRHAR(IMU,INUP,I0P))
                  PJJ(NOMI,IMOD)=PJJ(NOMI,IMOD)+EXPTD*TEMPD
               ENDDO
            ELSE
               PJJ(NOMI,1)=PJJ(NOMI,1)+EXPTD
               PJJX(NOMI,1)=PJJX(NOMI,1)+EXPTD*3.0*OMEGA2(1)
               PJJY(NOMI,1)=PJJY(NOMI,1)+EXPTD*3.0*OMEGA2(2)
               PJJZ(NOMI,1)=PJJZ(NOMI,1)+EXPTD*3.0*OMEGA2(3)
               PJJXI(NOMI,1)=PJJXI(NOMI,1)+EXPTD*9.0*
     1                       OMEGA2(1)*OMEGA2(1)                
               PJJYI(NOMI,1)=PJJYI(NOMI,1)+EXPTD*9.0*
     1                       OMEGA2(2)*OMEGA2(2)
               PJJZI(NOMI,1)=PJJZI(NOMI,1)+EXPTD*9.0*
     1                       OMEGA2(3)*OMEGA2(3)
            ENDIF
         ENDIF
      ENDDO  
*
      RETURN
      END
