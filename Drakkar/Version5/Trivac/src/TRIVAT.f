*DECK TRIVAT
      SUBROUTINE TRIVAT(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
*Purpose:
* TRIVAC type (3-D and ADI) tracking operator.
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
      INTEGER NENTRY,IENTRY(NENTRY),JENTRY(NENTRY)
      CHARACTER HENTRY(NENTRY)*12
      TYPE(C_PTR) KENTRY(NENTRY)
*----
*  LOCAL VARIABLES
*----
      PARAMETER (NSTATE=40)
      CHARACTER TEXT4*4,TEXT12*12,TITLE*72,HSIGN*12
      DOUBLE PRECISION DFLOTT
      LOGICAL LOG,LDIFF
      INTEGER IGP(NSTATE),ISTATE(NSTATE),NCODE(6)
*----
*  PARAMETER VALIDATION.
*----
      IF(NENTRY.LE.1) CALL XABORT('TRIVAT: TWO PARAMETERS EXPECTED.')
      IF((IENTRY(1).NE.1).AND.(IENTRY(1).NE.2)) CALL XABORT('TRIVAT: L'
     1 //'CM OBJECT EXPECTED AT LHS.')
      IF((JENTRY(1).NE.0).AND.(JENTRY(1).NE.1)) CALL XABORT('TRIVAT: E'
     1 //'NTRY IN CREATE OR MODIFICATION MODE EXPECTED.')
      IF((JENTRY(2).NE.2).OR.((IENTRY(2).NE.1).AND.(IENTRY(2).NE.2)))
     1 CALL XABORT('TRIVAT: LCM OBJECT IN READ-ONLY MODE EXPECTED AT R'
     2 //'HS.')
      CALL LCMGTC(KENTRY(2),'SIGNATURE',12,1,HSIGN)
      IF(HSIGN.NE.'L_GEOM') THEN
         TEXT12=HENTRY(2)
         CALL XABORT('TRIVAT: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1   '. L_GEOM EXPECTED.')
      ENDIF
      HSIGN='L_TRACK'
      CALL LCMPTC(KENTRY(1),'SIGNATURE',12,1,HSIGN)
      HSIGN='TRIVAC'
      CALL LCMPTC(KENTRY(1),'TRACK-TYPE',12,1,HSIGN)
      CALL LCMGET(KENTRY(2),'STATE-VECTOR',ISTATE)
      ITYPE=ISTATE(1)
      CALL LCMLEN(KENTRY(2),'BIHET',ILONG,ITYLCM)
      IF(ILONG.NE.0) CALL XABORT('TRIVAT: DOUBLE-HETEROGENEITY NOT SUP'
     1 //'PORTED.')
*
      IMPX=1
      IF(JENTRY(1).EQ.0) THEN
         TITLE=' '
         MAXPTS=ISTATE(6)
         IELEM=1
         ICOL=2
         ICHX=3
         ISEG=0
         IMPV=1
         NLF=0
         ISPN=0
         ISCAT=0
         NADI=2
         NVD=0
         CALL LCMGET(KENTRY(2),'NCODE',NCODE)
         LOG=.FALSE.
         DO 10 I=1,6
         LOG=LOG.OR.(NCODE(I).EQ.3)
   10    CONTINUE
         IF(LOG) MAXPTS=2*MAXPTS
      ELSE IF(JENTRY(1).EQ.1) THEN
         CALL LCMGTC(KENTRY(1),'SIGNATURE',12,1,HSIGN)
         IF(HSIGN.NE.'L_TRACK') THEN
            TEXT12=HENTRY(1)
            CALL XABORT('TRIVAT: SIGNATURE OF '//TEXT12//' IS '//HSIGN//
     1      '. L_TRACK EXPECTED.')
         ENDIF
         CALL LCMGTC(KENTRY(1),'TRACK-TYPE',12,1,HSIGN)
         IF(HSIGN.NE.'TRIVAC') THEN
            TEXT12=HENTRY(3)
            CALL XABORT('TRIVAT: TRACK-TYPE OF '//TEXT12//' IS '//HSIGN
     1      //'. TRIVAC EXPECTED.')
         ENDIF
         CALL LCMGET(KENTRY(1),'STATE-VECTOR',IGP)
         MAXPTS=IGP(1)
         IELEM=IGP(9)
         ICOL=IGP(10)
         ICHX=IGP(12)
         ISEG=IGP(17)
         IMPV=IGP(18)
         NLF=IGP(30)
         ISPN=IGP(31)
         ISCAT=IGP(32)
         NADI=IGP(33)
         NVD=IGP(34)
      ENDIF
   15 CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
      IF(INDIC.EQ.10) GO TO 30
   20 IF(INDIC.NE.3) CALL XABORT('TRIVAT: CHARACTER DATA EXPECTED.')
      IF(TEXT4.EQ.'EDIT') THEN
         CALL REDGET(INDIC,IMPX,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED(1).')
      ELSE IF(TEXT4.EQ.'TITL') THEN
         CALL REDGET(INDIC,NITMA,FLOTT,TITLE,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('TRIVAT: TITLE EXPECTED.')
      ELSE IF(TEXT4.EQ.'MAXR') THEN
         CALL REDGET(INDIC,MAXPTS,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED(2).')
      ELSE IF(TEXT4.EQ.'PRIM') THEN
*        MESH CORNER FINITE DIFFERENCES OR PRIMAL FINITE ELEMENTS.
         IELEM=1
         ICHX=1
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.EQ.1) THEN
            IELEM=NITMA
         ELSE
            GO TO 20
         ENDIF
      ELSE IF(TEXT4.EQ.'DUAL') THEN
*        MESH CENTERED FINITE DIFFERENCES OR MIXED-DUAL FINITE ELEMENTS.
         IELEM=1
         ICOL=2
         ICHX=2
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.EQ.1) THEN
            IELEM=NITMA
            CALL REDGET(INDIC,ICOL,FLOTT,TEXT4,DFLOTT)
            IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED.')
         ELSE
            GO TO 20
         ENDIF
      ELSE IF(TEXT4.EQ.'MCFD') THEN
*        MESH CENTERED FINITE DIFFERENCES OR NODAL COLLOCATION.
         IELEM=1
         ICHX=3
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.EQ.1) THEN
            IELEM=NITMA
         ELSE
            GO TO 20
         ENDIF
      ELSE IF(TEXT4.EQ.'LUMP') THEN
*        NODAL COLLOCATION WITH SERENDIPITY APPROXIMATION.
         IELEM=1
         ICHX=4
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.EQ.1) THEN
            IELEM=NITMA
         ELSE
            GO TO 20
         ENDIF
      ELSE IF(TEXT4.EQ.'VOID') THEN
         IF(NLF.EQ.0) CALL XABORT('TRIVAT: SPN-RELATED OPTION.')
         CALL REDGET(INDIC,NVD,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED.')
         IF((NVD.LT.0).OR.(NVD.GT.2)) CALL XABORT('TRIVAT: INVALID VAL'
     1   //'UE OF NVD (0, 1 OR 2 EXPECTED).')
      ELSE IF(TEXT4.EQ.'VECT') THEN
         ISEG=64
         CALL REDGET(INDIC,ISEG,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) GO TO 20
         IF(MOD(ISEG,64).NE.0) WRITE(6,'(/25H TRIVAT: ***WARNING*** IS,
     1   27HEG IS NOT A MULTIPLE OF 64.)')
      ELSE IF(TEXT4.EQ.'PRTV') THEN
         CALL REDGET(INDIC,IMPV,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED.')
      ELSE IF(TEXT4.EQ.'SPN') THEN
         CALL REDGET(INDIC,NLF,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED.')
         IF(NLF.EQ.0) THEN
*           DIFFUSION THEORY.
            ISCAT=0
            ISPN=0
         ELSE
            IF(MOD(NLF,2).EQ.0) CALL XABORT('TRIVAT: ODD SPN ORDER EXP'
     1      //'ECTED.')
            NLF=NLF+1
            ISCAT=NLF
            ISPN=1
         ENDIF
      ELSE IF(TEXT4.EQ.'SCAT') THEN
         IF(NLF.EQ.0) CALL XABORT('TRIVAT: DEFINE PN OR SPN FIRST.')
         CALL REDGET(INDIC,ISCAT,FLOTT,TEXT4,DFLOTT)
         IF(ISCAT.LE.0) CALL XABORT('TRIVAT: POSITIVE ISCAT EXPECTED.')
         LDIFF=.FALSE.
         IF((INDIC.EQ.3).AND.(TEXT4.EQ.'DIFF')) THEN
            LDIFF=.TRUE.
            CALL REDGET(INDIC,ISCAT,FLOTT,TEXT4,DFLOTT)
         ENDIF
         IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED.')
         IF(LDIFF) ISCAT=-ISCAT
      ELSE IF(TEXT4.EQ.'ADI') THEN
         CALL REDGET(INDIC,NADI,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('TRIVAT: INTEGER DATA EXPECTED.')
      ELSE IF(TEXT4.EQ.';') THEN
         GO TO 30
      ELSE
         CALL XABORT('TRIVAT: '//TEXT4//' IS AN INVALID KEY WORD.')
      ENDIF
      GO TO 15
*
   30 IF(TITLE.NE.' ') THEN
         CALL LCMPTC(KENTRY(1),'TITLE',72,1,TITLE)
      ENDIF
      IF((NLF.GT.0).AND.(IELEM.LT.0)) CALL XABORT('TRIVAT: SPN APPROXI'
     1 //'MATIONS LIMITED TO DUAL DISCRETIZATIONS.')
      TEXT12=HENTRY(2)
      CALL LCMPTC(KENTRY(1),'LINK.GEOM',12,1,TEXT12)
      IF(IMPX.GT.1) WRITE(6,100) TITLE
*
      IF(MAXPTS.EQ.0) CALL XABORT('TRIVAT: MAXPTS NOT DEFINED.')
      CALL TRITRK (MAXPTS,KENTRY(1),KENTRY(2),IMPX,IELEM,ICOL,ICHX,
     1 ISEG,IMPV,NLF,NVD,ISPN,ISCAT,NADI)
*
      IF(IMPX.GT.1) THEN
         CALL LCMGET(KENTRY(1),'STATE-VECTOR',IGP)
         WRITE(6,110) (IGP(I),I=1,16),IGP(24),(IGP(I),I=30,34)
         IF(IGP(17).NE.0) WRITE(6,120) (IGP(I),I=17,23)
         IF(IGP(12).EQ.2) WRITE(6,130) (IGP(I),I=25,29)
      ENDIF
      RETURN
*
  100 FORMAT(1H1,45HTTTTTTTT RRRRRR  IIIIII VV  VV   AA    CCCCC ,
     1 85(1H*)/47H TTTTTTTT RRRRRRR IIIIII VV  VV  AAAA  CCCCCCC ,
     2 46(1H*),38H MULTIGROUP VERSION.  A. HEBERT (1993)/
     3 46H    TT    RR   RR   II   VV  VV  AAAA  CC   CC/
     4 46H    TT    RRRRR     II   VV  VV AA  AA CC     /
     5 46H    TT    RRRRR     II   VV  VV AAAAAA CC     /
     6 46H    TT    RR RR     II   VV  VV AAAAAA CC   CC/
     7 46H    TT    RR  RR  IIIIII  VVVV  AA  AA CCCCCCC/
     8 46H    TT    RR   RR IIIIII   VV   AA  AA  CCCCC //1X,A72//)
  110 FORMAT(/14H STATE VECTOR:/
     1 7H NREG  ,I8,22H   (NUMBER OF REGIONS)/
     2 7H NUN   ,I8,23H   (NUMBER OF UNKNOWNS)/
     3 7H ILK   ,I8,39H   (0=LEAKAGE PRESENT/1=LEAKAGE ABSENT)/
     4 7H NBMIX ,I8,36H   (MAXIMUM NUMBER OF MIXTURES USED)/
     5 7H NSURF ,I8,29H   (NUMBER OF OUTER SURFACES)/
     6 7H ITYPE ,I8,21H   (TYPE OF GEOMETRY)/
     7 7H IHEX  ,I8,31H   (TYPE OF HEXAGONAL SYMMETRY)/
     8 7H IDIAG ,I8,41H   (0/1=DIAGONAL SYMMETRY ABSENT/PRESENT)/
     9 7H IELEM ,I8,28H   (TYPE OF FINITE ELEMENTS)/
     1 7H ICOL  ,I8,47H   (TYPE OF QUADRATURE USED TO INTEGRATE THE MA,
     2 10HSS MATRIX)/
     3 7H LL4   ,I8,46H   (ORDER OF THE MATRICES PER GROUP IN TRIVAC)/
     4 7H ICHX  ,I8,47H   (1=PRIMAL/2=THOMAS-RAVIART/3=NODAL COLLOCATI,
     5 10HON (MCFD))/
     6 7H ISPLH ,I8,37H   (TYPE OF HEXAGONAL MESH-SPLITTING)/
     7 7H LX    ,I8,40H   (NUMBER OF ELEMENTS ALONG THE X AXIS)/
     8 7H LY    ,I8,40H   (NUMBER OF ELEMENTS ALONG THE Y AXIS)/
     9 7H LZ    ,I8,40H   (NUMBER OF ELEMENTS ALONG THE Z AXIS)/
     1 7H NR0   ,I8,47H   (NUMBER OF RADII IN CYLINDRICAL CORRECTION A,
     2 9HLGORITHM)/
     3 7H NLF   ,I8,45H   (0=DIFFUSION/NB OF PN ORDERS FOR THE FLUX)/
     4 7H ISPN  ,I8,34H   (0=COMPLETE PN/1=SIMPLIFIED PN)/
     5 7H ISCAT ,I8,47H   (1=ISOTROPIC SOURCE/2=LINEARLY ANISOTROPIC S,
     6 6HOURCE)/
     7 7H NADI  ,I8,29H   (NUMBER OF ADI ITERATIONS)/
     8 7H NVD   ,I8,47H   (0=PN-TYPE VOID/1=SN-TYPE VOID/2=DIFFUSION-T,
     9 9HYPE VOID))
  120 FORMAT(/44H STATE VECTOR FOR SUPERVECTORIAL OPERATIONS:/
     1 7H ISEG  ,I8,46H   (NUMBER OF COMPONENTS IN A VECTOR REGISTER)/
     2 7H IMPV  ,I8,20H   (PRINT PARAMETER)/
     3 7H LTSW  ,I8,22H   (MAXIMUM BANDWIDTH)/
     4 7H LONW  ,I8,48H   (NB OF GROUPS OF LINEAR SYSTEMS ALONG W AXIS)/
     5 7H LONX  ,I8,48H   (NB OF GROUPS OF LINEAR SYSTEMS ALONG X AXIS)/
     6 7H LONY  ,I8,48H   (NB OF GROUPS OF LINEAR SYSTEMS ALONG Y AXIS)/
     7 7H LONZ  ,I8,48H   (NB OF GROUPS OF LINEAR SYSTEMS ALONG Z AXIS))
  130 FORMAT(/40H STATE VECTOR FOR THOMAS-RAVIART METHOD:/
     1 7H LL4F  ,I8,24H   (ORDER OF MATRICES T)/
     2 7H LL4W  ,I8,25H   (ORDER OF MATRICES AW)/
     3 7H LL4X  ,I8,25H   (ORDER OF MATRICES AX)/
     4 7H LL4Y  ,I8,25H   (ORDER OF MATRICES AY)/
     5 7H LL4Z  ,I8,25H   (ORDER OF MATRICES AZ))
      END