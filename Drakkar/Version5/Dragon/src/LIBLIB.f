*DECK LIBLIB
      SUBROUTINE LIBLIB (IPLIB,NBISO,MASKI,IMPX)
*
*-----------------------------------------------------------------------
*
*Purpose:
* transcription of the useful interpolated microscopic cross section
* data from various format of libraries to LCM. A two dimensional
* interpolation in temperature and dilution is performed. Part A
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
* IPLIB   pointer to the lattice microscopic cross section library
*         (L_LIBRARY signature)
* NBISO   number of isotopes present in the calculation domain
* MASKI   isotopic masks. An isotope with index I is process if
*         MASKI(I)=.true.
* IMPX    print flag
*
*-----------------------------------------------------------------------
*
      USE GANLIB
      IMPLICIT NONE
*----
*  SUBROUTINE ARGUMENTS
*----
      TYPE(C_PTR) IPLIB
      INTEGER NBISO,IMPX
      LOGICAL MASKI(*)
*----
*  INTERNAL PARAMETERS
*----
      INTEGER IOUT,MAXED,NSTATE
      PARAMETER (IOUT=6,MAXED=50,NSTATE=40)
*----
*  LOCAL VARIABLES
*----
      TYPE(C_PTR) JPLIB
      INTEGER IPAR(NSTATE),NGRO,NL,ITRANC,ITIME,NLIB,NGF,IGRMAX,NED,
     > NDEL,IPROC,ILENG,ITYLCM,IVOID,NBESP,ISOT
      CHARACTER HVECT(MAXED)*8,TEXT4*4
*----
*  ALLOCATABLE ARRAYS
*----
      INTEGER, ALLOCATABLE, DIMENSION(:) :: ISONA,ISONR,IHLIB,ILLIB,
     > NAME,NTFG,ISHIN,NIR
      REAL, ALLOCATABLE, DIMENSION(:) :: TMPIS,SN,SB,GIR
      TYPE(C_PTR), ALLOCATABLE, DIMENSION(:) :: IPISO
*----
*  RECOVER INFORMATION FROM THE /MICROLIB/ DIRECTORY.
*----
      CALL LCMGET(IPLIB,'STATE-VECTOR',IPAR)
      IF(NBISO.NE.IPAR(2)) CALL XABORT('LIBLIB: INCONSISTENT LIBRARY.')
      NGRO=IPAR(3)
      NL=IPAR(4)
      ITRANC=IPAR(5)
      ITIME=IPAR(7)
      NLIB=IPAR(8)
      NGF=IPAR(9)
      IGRMAX=IPAR(10)
      NED=IPAR(13)
      IF(NED.GT.MAXED) CALL XABORT('LIBLIB: MAXED OVERFLOW.')
      NBESP=IPAR(16)
      IPROC=IPAR(17)
      NDEL=IPAR(19)
      CALL LCMGTC(IPLIB,'ADDXSNAME-P0',8,NED,HVECT)
*----
*  MEMORY ALLOCATION.
*----
      ALLOCATE(ISONA(3*NBISO),ISONR(3*NBISO),IPISO(NBISO),TMPIS(NBISO),
     > IHLIB(6*NBISO),ILLIB(6*NBISO),NAME(16*NLIB),NTFG(NBISO),
     > ISHIN(3*NBISO),SN(NGRO*NBISO),SB(NGRO*NBISO),NIR(NBISO),
     > GIR(NBISO))
*----
*  RECOVER ARRAYS.
*----
      CALL LCMGET(IPLIB,'ISOTOPESUSED',ISONA)
      CALL LCMGET(IPLIB,'ISOTOPERNAME',ISONR)
      JPLIB=LCMLID(IPLIB,'ISOTOPESLIST',NBISO)
      CALL LCMGET(IPLIB,'ISOTOPESTEMP',TMPIS)
      CALL LCMGET(IPLIB,'ILIBRARYTYPE',IHLIB)
      CALL LCMGET(IPLIB,'ILIBRARYINDX',ILLIB)
      CALL LCMGET(IPLIB,'ILIBRARYNAME',NAME)
      CALL LCMLEN(IPLIB,'ISOTOPESNTFG',ILENG,ITYLCM)
      IF(ILENG.GT.0) THEN
         CALL LCMGET(IPLIB,'ISOTOPESNTFG',NTFG)
         CALL LCMGET(IPLIB,'ISOTOPESCOH',IHLIB(2*NBISO+1))
         CALL LCMGET(IPLIB,'ISOTOPESINC',IHLIB(4*NBISO+1))
      ELSE
         CALL XDISET(NTFG,NBISO,0)
      ENDIF
      CALL LCMLEN(IPLIB,'ISOTOPESHIN',ILENG,ITYLCM)
      IF(ILENG.GT.0) THEN
         CALL LCMGET(IPLIB,'ISOTOPESHIN',ISHIN)
      ELSE
         TEXT4=' '
         READ(TEXT4,'(A4)') IVOID
         CALL XDISET(ISHIN,2*NBISO,IVOID)
      ENDIF
      CALL LCMLEN(IPLIB,'ISOTOPESDSN',ILENG,ITYLCM)
      IF(ILENG.GT.0) THEN
         CALL LCMGET(IPLIB,'ISOTOPESDSN',SN)
         CALL LCMGET(IPLIB,'ISOTOPESDSB',SB)
      ELSE
         CALL XDRSET(SN,NGRO*NBISO,1.0E10)
         CALL XDRSET(SB,NGRO*NBISO,1.0E10)
      ENDIF
      CALL LCMLEN(IPLIB,'ISOTOPESNIR',ILENG,ITYLCM)
      IF(ILENG.GT.0) THEN
         CALL LCMGET(IPLIB,'ISOTOPESNIR',NIR)
         CALL LCMGET(IPLIB,'ISOTOPESGIR',GIR)
      ELSE
         CALL XDISET(NIR,NBISO,0)
         CALL XDRSET(GIR,NBISO,1.0)
      ENDIF
      DO ISOT=1,NBISO
        IF(MASKI(ISOT).AND.(ILLIB(ISOT).NE.0)) THEN
          IPISO(ISOT)=LCMDIL(JPLIB,ISOT) ! set ISOT-th isotope
        ELSE
          IPISO(ISOT)=C_NULL_PTR
        ENDIF
      ENDDO
*----
*  RECOVER AND INTERPOLATE MICROSCOPIC CROSS SECTIONS.
*----
      CALL LIBLIC (IPLIB,NBISO,MASKI,IMPX,NGRO,NL,ITRANC,ITIME,NLIB,
     1 NED,HVECT,ISONA,ISONR,IPISO,ISHIN,TMPIS,IHLIB,ILLIB,NAME,NTFG,
     2 SN,SB,NIR,GIR,NGF,IGRMAX,NDEL,NBESP,IPROC)
*
      DEALLOCATE(GIR,NIR,SB,SN,NTFG,NAME,ILLIB,IHLIB,TMPIS,ISHIN,IPISO,
     1 ISONR,ISONA)
*
      IPAR(9)=NGF
      IPAR(10)=IGRMAX
      IPAR(16)=NBESP
      IPAR(19)=NDEL
      CALL LCMPUT(IPLIB,'STATE-VECTOR',NSTATE,1,IPAR)
      IF(IMPX.GT.9) THEN
         WRITE (IOUT,'(36H LIBLIB: VALIDATION OF MICROLIB DATA)')
         CALL LCMVAL(IPLIB,' ')
      ENDIF
      RETURN
      END
