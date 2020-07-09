*DECK DUODRV
      SUBROUTINE DUODRV(IPLIB1,IPLIB2,IPRINT,LENER,LISOT,LMIXT,LREAC,
     > NMIX,NISOT,NGRP)
*
*-----------------------------------------------------------------------
*
* compare two microlibs and analyse the discrepancies using the Keff
* Clio perturbation formula.
*
*Copyright:
* Copyright (C) 2013 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* IPLIB1  first microlib
* IPLIB2  second microlib
* IPRINT  print parameter
* LENER   energy group analysis flag
* LISOT   isotope analysis flag
* LMIXT   mixture analysis flag
* LREAC   nuclear reaction analysis flag
* NMIX    number of mixtures
* NISOT   number of isotopes
* NGRP    number of energy groups
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPLIB1,IPLIB2
      INTEGER IPRINT,NMIX,NISOT,NGRP
      LOGICAL LENER,LISOT,LMIXT,LREAC
*----
*  LOCAL VARIABLES
*----
      PARAMETER (NSTATE=40)
      INTEGER ISTATE(NSTATE)
      DOUBLE PRECISION DBLLIR
      CHARACTER HREAC*8,CARLIR*12
*----
*  ALLOCATABLE ARRAYS
*----
      REAL, ALLOCATABLE, DIMENSION(:,:) :: FLUX1,AFLUX1,FLUX2,AFLUX2,
     > FLUXI1,AFLUXI1,FLUXI2,AFLUXI2
      REAL, ALLOCATABLE, DIMENSION(:,:,:) :: RHS1,LHS1,RHS2,LHS2,RHSI1,
     > LHSI1,RHSI2,LHSI2
*----
*  SCRATCH STORAGE ALLOCATION
*   RHS1    absorption macroscopic cross-section matrix
*   LHS1    production macroscopic cross-section matrix
*   FLUX1   direct flux
*   AFLUX1  adjoint flux flux
*   RHS2    absorption macroscopic cross-section matrix
*   LHS2    production macroscopic cross-section matrix
*   FLUX2   direct flux
*   AFLUX2  adjoint flux flux
*   RHSI1   absorption macroscopic cross-section matrix
*   LHSI1   production macroscopic cross-section matrix
*   FLUXI1  direct flux
*   AFLUXI1 adjoint flux flux
*   RHSI2   absorption macroscopic cross-section matrix
*   LHSI2   production macroscopic cross-section matrix
*   FLUXI2  direct flux
*   AFLUXI2 adjoint flux flux
*----
      ALLOCATE(RHS1(NGRP,NGRP,NMIX),LHS1(NGRP,NGRP,NMIX),
     > FLUX1(NGRP,NMIX),AFLUX1(NGRP,NMIX),RHS2(NGRP,NGRP,NMIX),
     > LHS2(NGRP,NGRP,NMIX),FLUX2(NGRP,NMIX),AFLUX2(NGRP,NMIX),
     > RHSI1(NGRP,NGRP,NISOT+NMIX),LHSI1(NGRP,NGRP,NISOT+NMIX),
     > FLUXI1(NGRP,NISOT+NMIX),AFLUXI1(NGRP,NISOT+NMIX),
     > RHSI2(NGRP,NGRP,NISOT+NMIX),LHSI2(NGRP,NGRP,NISOT+NMIX),
     > FLUXI2(NGRP,NISOT+NMIX),AFLUXI2(NGRP,NISOT+NMIX))
*----
*  -- MIXTURE KEYWORD --
*  CONSTRUCT THE RHS AND LHS MATRICES FOR THE FIRST SYSTEM
*----
      IF(.NOT.LMIXT) GO TO 100
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/48H DUODRV: ANALYSIS OF THE FIRST SYSTEM -- MIXTURE,
     >  8H KEYWORD)')
      ENDIF
      CALL LCMSIX(IPLIB1,'MACROLIB',1)
      CALL LCMGET(IPLIB1,'STATE-VECTOR',ISTATE)
      NFIS=ISTATE(4)
      CALL DUO001(IPLIB1,IPRINT,NMIX,NGRP,NFIS,3,ZKEFF1,RHS1,LHS1,FLUX1,
     > AFLUX1)
      CALL LCMSIX(IPLIB1,' ',2)
*----
*  CONSTRUCT THE RHS AND LHS MATRICES FOR THE SECOND SYSTEM
*----
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/48H DUODRV: ANALYSIS OF THE SECOND SYSTEM -- MIXTUR,
     >  9HE KEYWORD)')
      ENDIF
      CALL LCMSIX(IPLIB2,'MACROLIB',1)
      CALL LCMGET(IPLIB2,'STATE-VECTOR',ISTATE)
      NFIS=ISTATE(4)
      CALL DUO001(IPLIB2,IPRINT,NMIX,NGRP,NFIS,3,ZKEFF2,RHS2,LHS2,FLUX2,
     > AFLUX2)
      CALL LCMSIX(IPLIB2,' ',2)
*----
*  PRINT THE DETAILED DELTA-RHO USING THE CLIO FORMULA
*----
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/33H DUODRV: PERFORMING CLIO ANALYSIS)')
      ENDIF
      CALL DUO002(IPRINT,NMIX,NGRP,LENER,ZKEFF1,ZKEFF2,RHS1,RHS2,
     > LHS1,LHS2,FLUX2,AFLUX1)
*----
*  -- ISOTOPE KEYWORD --
*  CONSTRUCT THE RHS AND LHS MATRICES FOR THE FIRST SYSTEM
*----
  100 IF(.NOT.LISOT) GO TO 200
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/48H DUODRV: ANALYSIS OF THE FIRST SYSTEM -- ISOTOPE,
     >  8H KEYWORD)')
      ENDIF
      CALL DUO003(IPLIB1,IPRINT,NMIX,NISOT,NGRP,3,ZKEFF1,RHSI1,
     > LHSI1,FLUXI1,AFLUXI1)
*----
*  CONSTRUCT THE RHS AND LHS MATRICES FOR THE SECOND SYSTEM
*----
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/48H DUODRV: ANALYSIS OF THE SECOND SYSTEM -- ISOTOP,
     >  9HE KEYWORD)')
      ENDIF
      CALL DUO003(IPLIB2,IPRINT,NMIX,NISOT,NGRP,3,ZKEFF2,RHSI2,
     > LHSI2,FLUXI2,AFLUXI2)
*----
*  PRINT THE DETAILED DELTA-RHO USING THE CLIO FORMULA
*----
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/33H DUODRV: PERFORMING CLIO ANALYSIS)')
      ENDIF
      CALL DUO004(IPLIB1,IPRINT,NMIX,NISOT,NGRP,LENER,ZKEFF1,ZKEFF2,
     > RHSI1,RHSI2,LHSI1,LHSI2,FLUXI2,AFLUXI1)
*----
*  -- REAC KEYWORD --
*----
  200 IF(.NOT.LREAC) GO TO 230
      CALL DUO003(IPLIB2,0,NMIX,NISOT,NGRP,3,ZKEFF2,RHSI2,LHSI2,
     > FLUXI2,AFLUXI2)
*
  210 CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
      IF(ITYPLU.NE.3) CALL XABORT('DUODRV: READ ERROR - CHARACTER VA'
     >  //'RIABLE EXPECTED')
  220 IF(CARLIR.EQ.'ENDREAC') THEN
        CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
        IF(ITYPLU.NE.3) CALL XABORT('DUODRV: READ ERROR - CHARACTER '
     >  //'VARIABLE EXPECTED')
        IF(CARLIR.NE.';') CALL XABORT('DUODRV: ; KEYWORD EXPECTED')
        GO TO 230
      ENDIF
      HREAC=CARLIR(:8)
*----
*  CONSTRUCT THE RHS MATRIX FOR THE FIRST SYSTEM
*----
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/49H DUODRV: ANALYSIS OF THE FIRST SYSTEM -- REACTION,
     >  1X,A8,1H.)') HREAC
      ENDIF
      CALL DUO006(IPLIB1,IPRINT,NISOT,NGRP,HREAC,3,RHSI1,FLUXI1,AFLUXI1)
*----
*  CONSTRUCT THE RHS MATRIX FOR THE SECOND SYSTEM
*----
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/48H DUODRV: ANALYSIS OF THE SECOND SYSTEM -- REACTI,
     >  2HON,1X,A8,1H.)') HREAC
      ENDIF
      CALL DUO006(IPLIB2,IPRINT,NISOT,NGRP,HREAC,3,RHSI2,FLUXI2,AFLUXI2)
*----
*  PRINT THE DETAILED DELTA-RHO USING THE CLIO FORMULA
*----
      IF(IPRINT.GT.1) THEN
        WRITE(6,'(/47H DUODRV: PERFORMING CLIO ANALYSIS FOR REACTION ,
     >  A8,1H.)') HREAC
      ENDIF
      CALL DUO007(IPLIB1,IPRINT,NISOT,NGRP,LENER,RHSI1,RHSI2,LHSI2,
     > FLUXI2,AFLUXI1,RHOREA)
*
      CALL REDGET(ITYPLU,INTLIR,REALIR,CARLIR,DBLLIR)
      IF(ITYPLU.NE.3) CALL XABORT('DUODRV: READ ERROR - CHARACTER VA'
     > //'RIABLE EXPECTED')
      IF(CARLIR.EQ.'PICK') THEN
        CALL REDGET(ITYPLU,INTLIR,RHOREA,CARLIR,DBLLIR)
        IF(ITYPLU.NE.-2) CALL XABORT('DUODRV: OUTPUT REAL EXPECTED')
        ITYPLU=2
        CALL REDPUT(ITYPLU,INTLIR,RHOREA,CARLIR,DBLLIR)
      ELSE
        GO TO 220
      ENDIF
      GO TO 210
*----
*  SCRATCH STORAGE DEALLOCATION
*----
  230 DEALLOCATE(AFLUXI2,FLUXI2,LHSI2,RHSI2,AFLUXI1,FLUXI1,LHSI1,RHSI1,
     > AFLUX2,FLUX2,LHS2,RHS2,AFLUX1,FLUX1,LHS1,RHS1)
      RETURN
      END
