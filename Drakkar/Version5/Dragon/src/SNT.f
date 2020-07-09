*DECK SNT
      SUBROUTINE SNT(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
*Purpose:
* SN method tracking operator.
*
*Copyright:
* Copyright (C) 2005 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input/output
* NENTRY  number of LCM objects or files used by the operator.
* HENTRY  name of each LCM object or file:
*         HENTRY(1): create or modification type(L_TRACK);
*         HENTRY(2): read-only type(L_GEOM).
* IENTRY  type of each LCM object or file:
*         =1 LCM memory object; =2 XSM file; =3 sequential binary file;
*         =4 sequential ascii file.
* JENTRY  access of each LCM object or file:
*         =0 the LCM object or file is created;
*         =1 the LCM object or file is open for modifications;
*         =2 the LCM object or file is open in read-only mode.
* KENTRY  LCM object address or file unit number.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER      NENTRY,IENTRY(NENTRY),JENTRY(NENTRY)
      TYPE(C_PTR)  KENTRY(NENTRY)
      CHARACTER    HENTRY(NENTRY)*12
*----
*  LOCAL VARIABLES
*----
      PARAMETER(NSTATE=40,IOUT=6)
      TYPE(C_PTR) IPTRK,IPGEOM
      CHARACTER TEXT4*4,TEXT12*12,TITLE*72,HSIGN*12
      DOUBLE PRECISION DFLOTT
      REAL EPSI
      LOGICAL LOG,LFIXUP,LDSA,LBIHET,LIVO
      INTEGER IGP(NSTATE),ISTATE(NSTATE),NCODE(6),NITMA
*----
*  PARAMETER VALIDATION
*----
      IF(NENTRY.LE.1) CALL XABORT('SNT: TWO PARAMETERS EXPECTED.')
      IF((IENTRY(1).NE.1).AND.(IENTRY(1).NE.2)) CALL XABORT('SNT: L'
     1 //'CM OBJECT EXPECTED AT LHS.')
      IF((JENTRY(1).NE.0).AND.(JENTRY(1).NE.1)) CALL XABORT('SNT: E'
     1 //'NTRY IN CREATE OR MODIFICATION MODE EXPECTED.')
      IF((JENTRY(2).NE.2).OR.((IENTRY(2).NE.1).AND.(IENTRY(2).NE.2)))
     1 CALL XABORT('SNT: LCM OBJECT IN READ-ONLY MODE EXPECTED AT R'
     2 //'HS.')
      CALL LCMGTC(KENTRY(2),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_GEOM') THEN
         TEXT12=HENTRY(2)
         CALL XABORT('SNT: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1   '. L_GEOM EXPECTED.')
      ENDIF
      IPTRK=KENTRY(1)
      IPGEOM=KENTRY(2)
      HSIGN='L_TRACK'
      CALL LCMPTC(IPTRK,'SIGNATURE',12,1,HSIGN)
      HSIGN='SN'
      CALL LCMPTC(IPTRK,'TRACK-TYPE',12,1,HSIGN)
      CALL LCMGET(IPGEOM,'STATE-VECTOR',ISTATE)
      ITYPE=ISTATE(1)
*
      IMPX=1
      IF(JENTRY(1).EQ.0) THEN
         TITLE=' '
         MAXPTS=ISTATE(6)
         ISCHM=1
         IELEM=1
         NLF=0
         ISCAT=0
         IQUAD=0
         LFIXUP=.FALSE.
         LDSA=.FALSE.
         LIVO=.TRUE.
         ICL1=3
         ICL2=3
         IF((ITYPE.EQ.8).OR.(ITYPE.EQ.9)) THEN
            CALL LCMLEN(IPGEOM,'SPLITL',ILEN,ITYLCM)
            IF(ILEN.GT.0)THEN
               CALL LCMGET(IPGEOM,'SPLITL',ISPLH)
               IF(ISPLH.EQ.0) ISPLH=1
               MAXPTS=MAXPTS*3*ISPLH**2
            ELSE
               CALL XABORT('SNT: SPLITL SPECIFIER NEEDED FOR SN '//
     1          'WITH HEXAGONAL GEOMETRY.')
            ENDIF
         ENDIF
         NSTART=0
         NSDSA=10
         MAXIT=100
         EPSI=1.0E-5
         CALL LCMGET(IPGEOM,'NCODE',NCODE)
         LOG=.FALSE.
         DO 10 I=1,4
         LOG=LOG.OR.(NCODE(I).EQ.3)
   10    CONTINUE
         IF(LOG) MAXPTS=2*MAXPTS
         IQUA10=5
         IBIHET=2
         INSB=0
         IOMP=0
         CALL LCMLEN(IPGEOM,'BIHET',ILONG,ITYLCM)
         LBIHET=(ILONG.NE.0)
         IF(LBIHET) IQUA10=5
      ELSE IF(JENTRY(1).EQ.1) THEN
         CALL LCMGTC(IPTRK,'SIGNATURE',12,1,HSIGN)
         IF(HSIGN.NE.'L_TRACK') THEN
            TEXT12=HENTRY(1)
            CALL XABORT('SNT: SIGNATURE OF '//TEXT12//' IS '//HSIGN
     1      //'. L_TRACK EXPECTED.')
         ENDIF
         CALL LCMGTC(IPTRK,'TRACK-TYPE',12,1,HSIGN)
         IF(HSIGN.NE.'SN') THEN
            TEXT12=HENTRY(1)
            CALL XABORT('SNT: TRACK-TYPE OF '//TEXT12//' IS '//HSIGN
     1      //'. SN EXPECTED.')
         ENDIF
         CALL LCMGET(IPTRK,'STATE-VECTOR',IGP)
         MAXPTS=IGP(1)
         IELEM=IGP(8)
         ISCHM=IGP(10)
         NLF=IGP(15)
         ISCAT=IGP(16)
         IQUAD=IGP(17)
         LFIXUP=IGP(18).EQ.1
         LDSA=IGP(19).EQ.1
         NSTART=IGP(20)
         NSDSA=IGP(21)
         ISPLH=IGP(26)
         INSB=IGP(27)
         IOMP=IGP(28)
         LBIHET=(IGP(40).GT.0)
         IF(LBIHET) THEN
            CALL LCMSIX(IPTRK,'BIHET',1)
            CALL LCMGET(IPTRK,'PARAM',IGP)
            CALL LCMSIX(IPTRK,'BIHET',2)
            IBIHET=IGP(6)
            IQUA10=IGP(8)
         ELSE
            IBIHET=0
            IQUA10=0
         ENDIF
      ENDIF
      FRTM=0.05
   15 CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
   16 CONTINUE
      IF(INDIC.EQ.10) GO TO 30
      IF(INDIC.NE.3) CALL XABORT('SNT: CHARACTER DATA EXPECTED.')
      IF(TEXT4.EQ.'EDIT') THEN
         CALL REDGET(INDIC,IMPX,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(1).')
      ELSE IF(TEXT4.EQ.'TITL') THEN
         CALL REDGET(INDIC,NITMA,FLOTT,TITLE,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('SNT: TITLE EXPECTED.')
      ELSE IF(TEXT4.EQ.'MAXR') THEN
         CALL REDGET(INDIC,MAXPTS,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(2).')
      ELSE IF(TEXT4.EQ.'SCHM') THEN
         CALL REDGET(INDIC,ISCHM,FLOTT,TEXT4,DFLOTT)
         IF(ISCHM.EQ.2) IELEM = 2
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(2.1).')
      ELSE IF(TEXT4.EQ.'DIAM') THEN
         CALL REDGET(INDIC,IELEM,FLOTT,TEXT4,DFLOTT)
         IELEM = IELEM + 1
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(3).')
      ELSE IF(TEXT4.EQ.'SN') THEN
         CALL REDGET(INDIC,NLF,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(4).')
         IF(MOD(NLF,2).EQ.1) CALL XABORT('SNT: EVEN SN ORDER EXPECTED.')
         ISCAT=NLF
         IQUAD=2
      ELSE IF(TEXT4.EQ.'SCAT') THEN
         IF(NLF.EQ.0) CALL XABORT('SNT: DEFINE SN FIRST.')
         CALL REDGET(INDIC,ISCAT,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(5).')
         ISCAT=MIN(ISCAT,NLF)
      ELSE IF(TEXT4.EQ.'MAXI') THEN
         CALL REDGET(INDIC,MAXIT,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(6).')
      ELSE IF(TEXT4.EQ.'EPSI') THEN
         CALL REDGET(INDIC,NITMA,EPSI,TEXT4,DFLOTT)
         IF(INDIC.NE.2) CALL XABORT('SNT: REAL DATA EXPECTED(1).')
      ELSE IF(TEXT4.EQ.'QUAD') THEN
         CALL REDGET(INDIC,IQUAD,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(7).')
         IF((IQUAD.LT.1).OR.(IQUAD.GT.20)) CALL XABORT('SNT: INVALID'//
     1   ' QUAD VALUE.')
      ELSE IF(TEXT4.EQ.'NFIX') THEN
         LFIXUP=.TRUE.
         CALL REDGET(INDIC,ICL1,FLOTT,TEXT4,DFLOTT)
      ELSE IF(TEXT4.EQ.'LIVO') THEN
         LIVO=.TRUE.
         CALL REDGET(INDIC,ICL1,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(8).')
         CALL REDGET(INDIC,ICL2,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(9).')
      ELSE IF(TEXT4.EQ.'NLIV') THEN
         LIVO=.FALSE.
      ELSE IF(TEXT4.EQ.'DSA') THEN
         LDSA=.TRUE.
      ELSE IF(TEXT4.EQ.'NDSA') THEN
         LDSA=.FALSE.
      ELSE IF(TEXT4.EQ.'GMRE') THEN
         CALL REDGET(INDIC,NSTART,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(10).')
         IF(NSTART.LT.0) CALL XABORT('SNT: POSITIVE VALUE EXPECTED.')
      ELSE IF(TEXT4.EQ.'QUAB') THEN
         CALL REDGET(INDIC,IQUA10,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(11).')
      ELSE IF(TEXT4.EQ.'SAPO') THEN
         IBIHET=1
      ELSE IF(TEXT4.EQ.'NSDS') THEN
         CALL REDGET(INDIC,NSDSA,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(12).')
      ELSE IF(TEXT4.EQ.'HEBE') THEN
         IBIHET=2
      ELSE IF(TEXT4.EQ.'SLSI') THEN
         IBIHET=3
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF (INDIC.NE.2) GOTO 16
         FRTM=FLOTT
      ELSE IF(TEXT4.EQ.'SLSS') THEN
         IBIHET=4
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF (INDIC.NE.2) GOTO 16
         FRTM=FLOTT
      ELSE IF(TEXT4.EQ.'ONEG') THEN
         INSB=0
      ELSE IF(TEXT4.EQ.'ALLG') THEN
         INSB=1
      ELSE IF(TEXT4.EQ.'DOFF') THEN
         IOMP=0
      ELSE IF(TEXT4.EQ.'DOON') THEN
         CALL REDGET(INDIC,IOMP,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('SNT: INTEGER DATA EXPECTED(13).')
         IF(IOMP.LE.0) CALL XABORT('SNT: POSITIVE INTEGER EXPECTED.')
      ELSE IF(TEXT4.EQ.';') THEN
         GO TO 30
      ELSE
         CALL XABORT('SNT: '//TEXT4//' IS AN INVALID KEY WORD.')
      ENDIF
      GO TO 15
*
   30 IF(TITLE.NE.' ') CALL LCMPTC(IPTRK,'TITLE',72,1,TITLE)
      TEXT12=HENTRY(2)
      CALL LCMPTC(IPTRK,'LINK.GEOM',12,1,TEXT12)
      IF(IMPX.GT.1) WRITE(IOUT,100) TITLE
*
      IF(MAXPTS.EQ.0) CALL XABORT('SNT: MAXPTS NOT DEFINED.')
      CALL SNTRK(MAXPTS,IPTRK,IPGEOM,IMPX,ISCHM,IELEM,ISPLH,INSB,IOMP,
     1 NLF,MAXIT,EPSI,ISCAT,IQUAD,LFIXUP,LIVO,ICL1,ICL2,LDSA,NSTART,
     2 NSDSA,LBIHET,FRTM)
*
      IF(IMPX.GT.1) THEN
         CALL LCMGET(IPTRK,'STATE-VECTOR',IGP)
         WRITE(IOUT,110) (IGP(I),I=1,15)
         WRITE(IOUT,120) (IGP(I),I=16,28),IGP(40),EPSI
      ENDIF
*----
*  PROCESS DOUBLE HETEROGENEITY (BIHET) DATA (IF AVAILABLE)
*----
      IF(LBIHET) CALL XDRTBH(IPGEOM,IPTRK,IQUA10,IBIHET,IMPX,FRTM)
      RETURN
*
  100 FORMAT(1H1,19H SSSSS  NN      NN ,95(1H*)/
     1 20H SSSSSSS NNN     NN ,57(1H*),
     2 38H MULTIGROUP VERSION.  A. HEBERT (2005)/
     3 19H SS   SS NNNN    NN/19H  SS     NN NN   NN/
     4 19H    SS   NN  NN  NN/19H SS   SS NN   NN NN/
     5 19H SSSSSSS NN    NNNN/19H  SSSSS  NN     NNN//1X,A72//)
  110 FORMAT(/14H STATE VECTOR:/
     1 7H NREG  ,I6,22H   (NUMBER OF REGIONS)/
     2 7H NUN   ,I6,23H   (NUMBER OF UNKNOWNS)/
     3 7H ILK   ,I6,39H   (0=LEAKAGE PRESENT/1=LEAKAGE ABSENT)/
     4 7H NBMIX ,I6,36H   (MAXIMUM NUMBER OF MIXTURES USED)/
     5 7H NSURF ,I6,29H   (NUMBER OF OUTER SURFACES)/
     6 7H ITYPE ,I6,21H   (TYPE OF GEOMETRY)/
     7 7H NFUNL ,I6,45H   (NUMBER OF SPHERICAL HARMONICS COMPONENTS)/
     8 7H IELEM ,I6,46H   (ORDER OF POLYNOMIAL USED IN SPATIAL APPROX,
     9 48H./1=DIAMOND SCHEME/2=LINEAR/3=PARABOLIC/3=CUBIC)/
     1 7H NDIM  ,I6,35H   (NUMBER OF GEOMETRIC DIMENSIONS)/
     2 7H ISCHM ,I6,46H   (METHOD OF SPATIAL DISCRETISATION/1=HODD/2=,
     3 3HDG)/
     3 7H LL4   ,I6,36H   (ORDER OF THE MATRICES PER GROUP)/
     4 7H LX    ,I6,38H   (NUMBER OF MESHES ALONG THE X AXIS)/
     5 7H LY    ,I6,38H   (NUMBER OF MESHES ALONG THE Y AXIS)/
     6 7H LZ    ,I6,38H   (NUMBER OF MESHES ALONG THE Z AXIS)/
     7 7H NLF   ,I6,13H   (SN ORDER))
  120 FORMAT(
     1 7H ISCAT ,I6,47H   (1=ISOTROPIC SOURCE/2=LINEARLY ANISOTROPIC S,
     2 6HOURCE)/
     3 7H IQUAD ,I6,47H   (<4=LEVEL-SYMMETRIC OF TYPE IQUAD/4=LEGENDRE,
     4 58H-CHEBYSHEV/5=SYMMETRIC LEGENDRE-CHEBYSHEV/6=QR/>9=PRODUCT)/
     5 7H IFIX  ,I6,29H   (0/1: NEGATIVE FLUX FIXUP)/
     6 7H IDSA  ,I6,32H   (0/1: SYNTHETIC ACCELERATION)/
     7 7H NSTART,I6,32H   (NUMBER OF RESTARTS IN GMRES)/
     8 7H NSDSA ,I6,45H   (NUMBER OF ITERATIONS BEFORE ENABLING DSA)/
     9 7H MAXIT ,I6,39H   (MAXIMUM NUMBER OF INNER ITERATIONS)/
     1 7H LIVO  ,I6,38H   (0/1: LIVOLANT ACCELERATION OFF/ON)/
     2 7H ICL1  ,I6,39H   (NUMBER OF FREE ITERATIONS IN LIVO.)/
     3 7H ICL2  ,I6,46H   (NUMBER OF ACCELERATED ITERATIONS IN LIVO.)/
     4 7H ISPLH ,I6,46H   (DEGREE OF LOZENGE SPLITTING FOR HEXAGONAL ,
     5 9HGEOMETRY)/
     6 7H INSB  ,I6,36H   (0/1: GROUP VECTORIZATION OFF/ON)/
     7 7H IOMP  ,I6,38H   (0/1: DOMINO MULTITHREADING OFF/ON)/
     8 7H IBIHET,I6,47H   (0/1: DOUBLE HETEROGENEITY IS NOT/IS ACTIVE)/
     9 7H EPSI  ,E11.1,45H  (CONVERGENCE CRITERION ON INNER ITERATIONS))
      END
