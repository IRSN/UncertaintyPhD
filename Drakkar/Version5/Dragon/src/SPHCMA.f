*DECK SPHCMA
      SUBROUTINE SPHCMA(IPMACR,IPRINT,IMC,NMERGE,NGCOND,NIFISS,NED,
     1 NALBP,SPH)
*
*-----------------------------------------------------------------------
*
*Purpose:
* SPH-correction of a Macrolib.
*
*Copyright:
* Copyright (C) 2011 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* IPMACR  pointer to the condensed macrolib (L_MACROLIB signature).
* IPRINT  print flag (equal to 0 for no print).
* IMC     type of macro-calculation (=1: diffusion or SPN; =2: else;
*         =3: type PIJ with Bell acceleration).
* NMERGE  number of merged regions.
* NGCOND  number of condensed groups.
* NIFISS  number of fissile isotopes.
* NED     number of additional phi-weighted edits in macrolib.
* NALBP   number of physical albedos per condensed group.
* SPH     SPH homogenization factors.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPMACR
      INTEGER IPRINT,IMC,NMERGE,NGCOND,NIFISS,NED,NALBP
      REAL SPH(NMERGE+NALBP,NGCOND)
*----
*  LOCAL VARIABLES
*----
      PARAMETER(NSTATE=40)
      INTEGER ISTATE(NSTATE)
      DOUBLE PRECISION DNUM,DDEN
      CHARACTER HSIGN*12,TEXT12*12,TEXT2*2,TEXT8*8
      TYPE(C_PTR) JPMACR,KPMACR
      INTEGER, ALLOCATABLE, DIMENSION(:) :: NJJ,IJJ,IPOS
      INTEGER, ALLOCATABLE, DIMENSION(:,:) :: IHEDIT
      REAL, ALLOCATABLE, DIMENSION(:) :: GAR1,DIFHOM,SPHHOM
      REAL, ALLOCATABLE, DIMENSION(:,:) :: NTOT,GAR2,ALB
      REAL, ALLOCATABLE, DIMENSION(:,:,:) :: SIGS
*----
*  SCRATCH STORAGE ALLOCATION
*   IHEDIT  character*8 names of phi-weighted edits in macrolib.
*----
      ALLOCATE(IHEDIT(2,NED+1),NJJ(NMERGE),IJJ(NMERGE),IPOS(NMERGE))
      ALLOCATE(GAR1(NMERGE*NGCOND),GAR2(NMERGE,NIFISS),DIFHOM(NGCOND),
     1 SPHHOM(NGCOND))
*----
*  RECOVER MACROLIB INFORMATION
*----
      CALL LCMGTC(IPMACR,'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_MACROLIB') CALL XABORT('SPHCMA: MACROLIB EXPECTED')
      CALL LCMGET(IPMACR,'STATE-VECTOR',ISTATE)
      IF(NGCOND.NE.ISTATE(1)) THEN
        CALL XABORT('SPHCMA: INVALID NGCOND')
      ELSE IF(NMERGE.NE.ISTATE(2)) THEN
        CALL XABORT('SPHCMA: INVALID NMERGE')
      ELSE IF((NIFISS.NE.0).AND.(NIFISS.NE.ISTATE(4))) THEN
        CALL XABORT('SPHCMA: INVALID NIFISS')
      ELSE IF(NED.NE.ISTATE(5)) THEN
        CALL XABORT('SPHCMA: INVALID NED')
      ELSE IF(NALBP.NE.ISTATE(8)) THEN
        CALL XABORT('SPHCMA: INVALID NALBP')
      ENDIF
*
      IF(NED.GT.0) CALL LCMGET(IPMACR,'ADDXSNAME-P0',IHEDIT)
      NL=ISTATE(3)
      ITRANC=ISTATE(6)
      NDEL=ISTATE(7)
      ILEAKS=ISTATE(9)
      NW=MAX(1,ISTATE(10))
      ISTATE(10)=NW
      ISTATE(14)=1
      CALL LCMPUT(IPMACR,'STATE-VECTOR',NSTATE,1,ISTATE)
*----
*  LOOP OVER GROUPS
*----
      ALLOCATE(SIGS(NMERGE,NGCOND,NL))
      SIGS(:NMERGE,:NGCOND,:NL)=0.0
      JPMACR=LCMGID(IPMACR,'GROUP')
      DO 230 IGR=1,NGCOND
      KPMACR=LCMGIL(JPMACR,IGR)
*----
*  SPH FACTORS
*----
      CALL LCMPUT(KPMACR,'NSPH',NMERGE,2,SPH(1,IGR))
*----
*  INTEGRATED FLUX
*----
      CALL LCMLEN(KPMACR,'FLUX-INTG',ILCMLN,ITYLCM)
      IF(ILCMLN.EQ.0) CALL XABORT('SPHCMA: MISSING FLUX-INTG INFO')
      CALL LCMGET(KPMACR,'FLUX-INTG',GAR1)
      DNUM=0.0D0
      DDEN=0.0D0
      DO 10 IBM=1,NMERGE
      DNUM=DNUM+GAR1(IBM)
      GAR1(IBM)=GAR1(IBM)/SPH(IBM,IGR)
   10 DDEN=DDEN+GAR1(IBM)
      CALL LCMPUT(KPMACR,'FLUX-INTG',NMERGE,2,GAR1)
      SPHHOM(IGR)=REAL(DNUM/DDEN)
      DO 15 IW=2,MIN(NW+1,10)
      WRITE(TEXT12,'(11HFLUX-INTG-P,I1)') IW-1
      CALL LCMLEN(KPMACR,TEXT12,ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,TEXT12,GAR1)
      ELSE
         CALL LCMGET(KPMACR,'FLUX-INTG',GAR1)
      ENDIF
      IF(MOD(IW-1,2).EQ.0) GAR1(IBM)=GAR1(IBM)/SPH(IBM,IGR)
      CALL LCMPUT(KPMACR,TEXT12,NMERGE,2,GAR1)
   15 CONTINUE
*----
*  MACROSCOPIC TOTAL CROSS SECTIONS
*----
      CALL LCMLEN(KPMACR,'NTOT0',ILCMLN,ITYLCM)
      IF(ILCMLN.EQ.0) CALL XABORT('SPHCMA: MISSING NTOT0 INFO')
      ALLOCATE(NTOT(NMERGE,NW+1))
      DO 40 IW=1,MIN(NW+1,10)
      WRITE(TEXT12,'(4HNTOT,I1)') IW-1
      CALL LCMLEN(KPMACR,TEXT12,ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,TEXT12,NTOT(1,IW))
      ELSE
         NTOT(:,IW)=NTOT(:,1)
      ENDIF
      IF((IMC.EQ.1).AND.(MOD(IW-1,2).EQ.0)) THEN
         DO 20 IBM=1,NMERGE
   20    GAR1(IBM)=NTOT(IBM,IW)*SPH(IBM,IGR)
      ELSEIF((IMC.EQ.1).AND.(MOD(IW-1,2).EQ.1)) THEN
         DO 30 IBM=1,NMERGE
   30    GAR1(IBM)=NTOT(IBM,IW)/SPH(IBM,IGR)
      ELSE
         GAR1(:)=NTOT(:,IW)
      ENDIF
      CALL LCMPUT(KPMACR,TEXT12,NMERGE,2,GAR1)
   40 CONTINUE
*----
*  MACROSCOPIC NU*FISSION CROSS SECTIONS (STEADY-STATE AND DELAYED)
*----
      IF(NIFISS.GT.0) THEN
         CALL LCMGET(KPMACR,'NUSIGF',GAR2)
         DO 50 IFIS=1,NIFISS
         DO 50 IBM=1,NMERGE
   50    GAR2(IBM,IFIS)=GAR2(IBM,IFIS)*SPH(IBM,IGR)
         CALL LCMPUT(KPMACR,'NUSIGF',NMERGE*NIFISS,2,GAR2)
         DO 70 IDEL=1,NDEL
         WRITE(TEXT12,'(6HNUSIGF,I2.2)') IDEL
         CALL LCMGET(KPMACR,TEXT12,GAR2)
         DO 60 IFIS=1,NIFISS
         DO 60 IBM=1,NMERGE
   60    GAR2(IBM,IFIS)=GAR2(IBM,IFIS)*SPH(IBM,IGR)
         CALL LCMPUT(KPMACR,TEXT12,NMERGE*NIFISS,2,GAR2)
   70    CONTINUE
      ENDIF
*----
*  MACROSCOPIC SCATTERING CROSS SECTIONS
*----
      DO 110 IL=1,NL
      WRITE(TEXT2,'(I2.2)') IL-1
      CALL LCMLEN(KPMACR,'NJJS'//TEXT2,ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,'NJJS'//TEXT2,NJJ)
         CALL LCMGET(KPMACR,'IJJS'//TEXT2,IJJ)
         CALL LCMGET(KPMACR,'IPOS'//TEXT2,IPOS)
         CALL LCMGET(KPMACR,'SCAT'//TEXT2,GAR1)
         IPO=0
         DO 80 IBM=1,NMERGE
         IPO=IPOS(IBM)
         DO 80 JGR=IJJ(IBM),IJJ(IBM)-NJJ(IBM)+1,-1
         IF(MOD(IL-1,2).EQ.0) THEN
            IF((IGR.EQ.JGR).AND.(IMC.GT.1).AND.(IL.LE.NW+1)) THEN
               GAR1(IPO)=GAR1(IPO)*SPH(IBM,IGR)+
     >                   (NTOT(IBM,1)-NTOT(IBM,IL)*SPH(IBM,IGR))
            ELSE
               GAR1(IPO)=GAR1(IPO)*SPH(IBM,JGR) ! IGR <- JGR
            ENDIF
         ELSE
            IF((IGR.EQ.JGR).AND.(IMC.GT.1).AND.(IL.LE.NW+1)) THEN
               GAR1(IPO)=GAR1(IPO)/SPH(IBM,IGR)+
     >                  (NTOT(IBM,1)-NTOT(IBM,IL)/SPH(IBM,IGR))
            ELSE
               GAR1(IPO)=GAR1(IPO)/SPH(IBM,IGR)
            ENDIF
         ENDIF
         SIGS(IBM,JGR,IL)=SIGS(IBM,JGR,IL)+GAR1(IPO)
   80    IPO=IPO+1
         CALL LCMPUT(KPMACR,'SCAT'//TEXT2,IPO-1,2,GAR1)
      ENDIF
      CALL LCMLEN(KPMACR,'SIGW'//TEXT2,ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,'SIGW'//TEXT2,GAR1)
         DO 90 IBM=1,NMERGE
         IF(MOD(IL-1,2).EQ.0) THEN
            IF((IMC.GT.1).AND.(IL.LE.NW+1)) THEN
               GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)+
     >                   (NTOT(IBM,1)-NTOT(IBM,IL)*SPH(IBM,IGR))
            ELSE
               GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
            ENDIF
         ELSE
            IF((IMC.GT.1).AND.(IL.LE.NW+1)) THEN
               GAR1(IBM)=GAR1(IBM)/SPH(IBM,IGR)+
     >                  (NTOT(IBM,1)-NTOT(IBM,IL)/SPH(IBM,IGR))
            ELSE
               GAR1(IBM)=GAR1(IBM)/SPH(IBM,IGR)
            ENDIF
         ENDIF
   90    CONTINUE
         CALL LCMPUT(KPMACR,'SIGW'//TEXT2,NMERGE,2,GAR1)
      ENDIF
  110 CONTINUE
      DEALLOCATE(NTOT)
*----
*  DIFFUSION COEFFICIENTS
*----
      IF(ILEAKS.EQ.1) THEN
         CALL LCMLEN(KPMACR,'DIFF',ILCMLN,ITYLCM)
         IF(ILCMLN.GT.0) THEN
            CALL LCMGET(KPMACR,'DIFF',GAR1)
            DO 120 IBM=1,NMERGE
  120       GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
         ELSE
            CALL LCMGET(IPMACR,'DIFHOMB1HOM',DIFHOM)
            DO 130 IBM=1,NMERGE
  130       GAR1(IBM)=DIFHOM(IGR)*SPH(IBM,IGR)
         ENDIF
         CALL LCMPUT(KPMACR,'DIFF',NMERGE,2,GAR1)
      ELSE IF(ILEAKS.EQ.2) THEN
         CALL LCMLEN(KPMACR,'DIFFX',ILCMLN,ITYLCM)
         IF(ILCMLN.GT.0) THEN
            CALL LCMGET(KPMACR,'DIFFX',GAR1)
            DO 140 IBM=1,NMERGE
  140       GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
            CALL LCMPUT(KPMACR,'DIFFX',NMERGE,2,GAR1)
         ENDIF
         CALL LCMLEN(KPMACR,'DIFFY',ILCMLN,ITYLCM)
         IF(ILCMLN.GT.0) THEN
            CALL LCMGET(KPMACR,'DIFFY',GAR1)
            DO 150 IBM=1,NMERGE
  150       GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
            CALL LCMPUT(KPMACR,'DIFFY',NMERGE,2,GAR1)
         ENDIF
         CALL LCMLEN(KPMACR,'DIFFZ',ILCMLN,ITYLCM)
         IF(ILCMLN.GT.0) THEN
            CALL LCMGET(KPMACR,'DIFFZ',GAR1)
            DO 160 IBM=1,NMERGE
  160       GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
            CALL LCMPUT(KPMACR,'DIFFZ',NMERGE,2,GAR1)
         ENDIF
      ENDIF
*----
*  SPECIFIC REACTIONS
*----
      CALL LCMLEN(KPMACR,'H-FACTOR',ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,'H-FACTOR',GAR1)
         DO 170 IBM=1,NMERGE
  170    GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
         CALL LCMPUT(KPMACR,'H-FACTOR',NMERGE,2,GAR1)
      ENDIF
      CALL LCMLEN(KPMACR,'OVERV',ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,'OVERV',GAR1)
         DO 180 IBM=1,NMERGE
  180    GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
         CALL LCMPUT(KPMACR,'OVERV',NMERGE,2,GAR1)
      ENDIF
      CALL LCMLEN(KPMACR,'TRANC',ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,'TRANC',GAR1)
         DO 190 IBM=1,NMERGE
  190    GAR1(IBM)=GAR1(IBM)/SPH(IBM,IGR)
         CALL LCMPUT(KPMACR,'TRANC',NMERGE,2,GAR1)
      ENDIF
      CALL LCMLEN(KPMACR,'ABS',ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,'ABS',GAR1)
         DO 200 IBM=1,NMERGE
  200    GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
         CALL LCMPUT(KPMACR,'ABS',NMERGE,2,GAR1)
      ENDIF
*----
*  ADDITIONAL PHI-WEIGHTED EDITS
*----
      DO 220 IED=1,NED
      WRITE(TEXT8,'(2A4)') (IHEDIT(I0,IED),I0=1,2)
      IF((TEXT8.EQ.'H-FACTOR').OR.(TEXT8(:5).EQ.'OVERV').OR.
     >   (TEXT8(:3).EQ.'ABS').OR.(TEXT8(:5).EQ.'TRANC')) GO TO 220
      CALL LCMLEN(KPMACR,TEXT8,ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,TEXT8,GAR1)
         DO 210 IBM=1,NMERGE
         IF(TEXT8(:4).EQ.'STRD') THEN
            GAR1(IBM)=GAR1(IBM)/SPH(IBM,IGR)
         ELSE
            GAR1(IBM)=GAR1(IBM)*SPH(IBM,IGR)
         ENDIF
  210    CONTINUE
         CALL LCMPUT(KPMACR,TEXT8,NMERGE,2,GAR1)
      ENDIF
  220 CONTINUE
  230 CONTINUE
*----
* STORE SCATTERING CROSS SECTIONS
*----
      DO 240 IGR=1,NGCOND
      KPMACR=LCMGIL(JPMACR,IGR)
      CALL LCMLEN(KPMACR,'SIGS00',ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(KPMACR,'SIGS00',SIGS(1,IGR,1))
         CALL LCMGET(KPMACR,'NTOT0',GAR1)
         DO 235 IBM=1,NMERGE
            IF(IMC.EQ.1) THEN
               SIGS(IBM,IGR,1)=SIGS(IBM,IGR,1)*SPH(IBM,IGR)
            ELSE
               SIGS(IBM,IGR,1)=SIGS(IBM,IGR,1)*SPH(IBM,IGR)+GAR1(IBM)*
     >         (1.0-SPH(IBM,IGR))
            ENDIF
  235    CONTINUE
      ENDIF
      DO 240 IL=1,NL
      WRITE(TEXT2,'(I2.2)') IL-1
      CALL LCMLEN(KPMACR,'SIGS'//TEXT2,ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMPUT(KPMACR,'SIGS'//TEXT2,NMERGE,2,SIGS(1,IGR,IL))
      ENDIF
  240 CONTINUE
      DEALLOCATE(SIGS)
*----
*  HOMOGENIZED DIFFUSION COEFFICIENTS
*----
      CALL LCMLEN(IPMACR,'DIFFB1HOM',ILCMLN,ITYLCM)
      IF(ILCMLN.GT.0) THEN
         CALL LCMGET(IPMACR,'DIFFB1HOM',DIFHOM)
         DO 250 IGR=1,NGCOND
  250    DIFHOM(IGR)=DIFHOM(IGR)*SPHHOM(IGR)
         CALL LCMPUT(IPMACR,'DIFFB1HOM',NGCOND,2,DIFHOM)
      ENDIF
*----
*  PHYSICAL ALBEDOS
*----
      IF(NALBP.GT.0) THEN
         ALLOCATE(ALB(NALBP,NGCOND))
         CALL LCMGET(IPMACR,'ALBEDO',ALB)
         DO 260 IGR=1,NGCOND
         DO 260 IAL=1,NALBP
         FACT=0.5*(1.0-ALB(IAL,IGR))/(1.0+ALB(IAL,IGR))*
     1   SPH(NMERGE+IAL,IGR)
  260    ALB(IAL,IGR)=(1.0-2.0*FACT)/(1.0+2.0*FACT)
         CALL LCMPUT(IPMACR,'ALBEDO',NGCOND*NALBP,2,ALB)
         DEALLOCATE(ALB)
      ENDIF
      IF(IPRINT.GT.5) WRITE(6,'(/28H SPHCMA: MACROLIB CORRECTED.)')
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(SPHHOM,DIFHOM,GAR2,GAR1)
      DEALLOCATE(IPOS,IJJ,NJJ,IHEDIT)
      RETURN
      END
