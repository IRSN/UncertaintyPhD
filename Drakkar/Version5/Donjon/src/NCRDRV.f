*DECK NCRDRV
      SUBROUTINE NCRDRV(IPCPO,LCUBIC,NMIX,IMPX,NMIL,NCAL,ITER,MAXNIS,
     1 MIXC,TERP,NISO,LISO,HISO,CONC)
*
*-----------------------------------------------------------------------
*
*Purpose:
* compute TERP factors for multicompo interpolation. Use user-defined
* global and local parameters.
*
*Copyright:
* Copyright (C) 2006 Ecole Polytechnique de Montreal
*
*Author(s): A. Hebert and R. Chambon
*
*Parameters: input
* IPCPO   address of the multicompo object.
* LCUBIC  =.TRUE.: cubic Ceschino interpolation; =.FALSE: linear
*         Lagrange interpolation.
* NMIX    maximum number of material mixtures in the microlib.
* IMPX    print parameter (equal to zero for no print).
* NMIL    number of material mixtures in the multicompo.
* NCAL    number of elementary calculations in the multicompo.
*
*Parameters: output
* ITER    completion flag (=0: all over; =1: use another multicompo;
*         =2 use another L_MAP + multicompo).
* MAXNIS  maximum value of NISO(I) in user data.
* MIXC    mixture index in the multicompo corresponding to each microlib
*         mixture.
* TERP    interpolation factors.
* NISO    number of user-selected isotopes.
* LISO    type of treatment (=.true.: ALL; =.false.: ONLY).
* HISO    name of the user-selected isotopes.
* CONC    user-defined number density of the user-selected isotopes. A
*         value of -99.99 is set to indicate that the multicompo value
*         is used.
*
*-----------------------------------------------------------------------
*
      USE GANLIB
      IMPLICIT NONE
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER, PARAMETER::MAXISD=200
      TYPE(C_PTR) IPCPO
      INTEGER NMIX,IMPX,NMIL,NCAL,ITER,MAXNIS,MIXC(NMIX),
     1 NISO(NMIX),HISO(2,NMIX,MAXISD)
      REAL TERP(NCAL,NMIX),CONC(NMIX,MAXISD)
      LOGICAL LCUBIC,LISO(NMIX)
*----
*  LOCAL VARIABLES
*----
      INTEGER, PARAMETER::IOUT=6
      INTEGER, PARAMETER::MAXLIN=50
      INTEGER, PARAMETER::MAXPAR=50
      INTEGER, PARAMETER::MAXVAL=200
      INTEGER, PARAMETER::NSTATE=40
      REAL, PARAMETER::REPS=1.0E-4
      REAL FLOTT, SUM
      INTEGER I0, IBMOLD, IBM, ICAL, INDIC, IPAR, ITYLCM, ITYPE, I, 
     & JBM, J, LENGTH, NCOMLI, NITMA, NLOC, NPAR
      CHARACTER TEXT12*12,PARKEY(MAXPAR)*12,PARFMT(MAXPAR)*8,
     1 PARKEL(MAXPAR)*12,HSMG*131,COMMEN(MAXLIN)*80,VALH(MAXPAR)*12,
     2 RECNAM*12,VCHAR(MAXVAL)*12,HCUBIC*12
      INTEGER ISTATE(NSTATE),VALI(MAXPAR),NVALUE(MAXPAR),VINTE(MAXVAL),
     1 MUPLET(2*MAXPAR),MUTYPE(2*MAXPAR)
      DOUBLE PRECISION DFLOTT
      REAL VALR(2*MAXPAR,2),VREAL(MAXVAL)
      LOGICAL LCUB2(MAXPAR)
      TYPE(C_PTR) JPCPO,KPCPO,LPCPO
      LOGICAL, ALLOCATABLE, DIMENSION(:) :: LDELTA
*----
*  SCRATCH STORAGE ALLOCATION
*----
      ALLOCATE(LDELTA(NMIX))
*----
*  RECOVER TABLE-OF-CONTENT INFORMATION FOR THE MULTICOMPO.
*----
      CALL LCMGET(IPCPO,'STATE-VECTOR',ISTATE)
      NPAR=ISTATE(5)
      NLOC=ISTATE(6)
      NCOMLI=ISTATE(10)
      CALL LCMGTC(IPCPO,'COMMENT',80,NCOMLI,COMMEN)
      IF(NPAR.GT.0) THEN
         CALL LCMSIX(IPCPO,'GLOBAL',1)
         CALL LCMGTC(IPCPO,'PARKEY',12,NPAR,PARKEY)
         CALL LCMGTC(IPCPO,'PARFMT',8,NPAR,PARFMT)
         CALL LCMGET(IPCPO,'NVALUE',NVALUE)
         IF(IMPX.GT.0)THEN
           DO IPAR=1,NPAR
             WRITE(RECNAM,'(''pval'',I8.8)') IPAR
             IF(PARFMT(IPAR).EQ.'INTEGER') THEN
               CALL LCMGET(IPCPO,RECNAM,VINTE)
               WRITE(IOUT,'(13H NCRDRV: KEY=,A,18H TABULATED POINTS=,
     1         1P,6I12/(43X,6I12))') PARKEY(IPAR),(VINTE(I),I=1,
     2         NVALUE(IPAR))
             ELSE IF(PARFMT(IPAR).EQ.'REAL') THEN
               CALL LCMGET(IPCPO,RECNAM,VREAL)
               WRITE(IOUT,'(13H NCRDRV: KEY=,A,18H TABULATED POINTS=,
     1         1P,6E12.4/(43X,6E12.4))') PARKEY(IPAR),(VREAL(I),I=1,
     2         NVALUE(IPAR))
             ELSE IF(PARFMT(IPAR).EQ.'STRING') THEN
               CALL LCMGTC(IPCPO,RECNAM,12,NVALUE(IPAR),VCHAR)
               WRITE(IOUT,'(13H NCRDRV: KEY=,A,18H TABULATED POINTS=,
     1         1P,6A12/(43X,6A12))') PARKEY(IPAR),(VCHAR(I),I=1,
     2         NVALUE(IPAR))
             ENDIF
           ENDDO
         ENDIF
         CALL LCMSIX(IPCPO,' ',2)
      ENDIF
      IF(NLOC.GT.0) THEN
         CALL LCMSIX(IPCPO,'LOCAL',1)
         CALL LCMGTC(IPCPO,'PARKEY',12,NLOC,PARKEL)
         CALL LCMSIX(IPCPO,' ',2)
         JPCPO=LCMGID(IPCPO,'MIXTURES')
         DO IBMOLD=1,NMIL
           KPCPO=LCMGIL(JPCPO,IBMOLD)
           LPCPO=LCMGID(KPCPO,'TREE')
           CALL LCMGET(LPCPO,'NVALUE',NVALUE)
           IF(IMPX.GT.0)THEN
             WRITE(IOUT,'(17H NCRDRV: MIXTURE=,I6)') IBMOLD
             DO IPAR=1,NLOC
               WRITE(RECNAM,'(''pval'',I8.8)') IPAR
               CALL LCMGET(LPCPO,RECNAM,VREAL)
               WRITE(IOUT,'(13H NCRDRV: KEY=,A,18H TABULATED POINTS=,
     1         1P,6E12.4/(43X,6E12.4))') PARKEL(IPAR),(VREAL(I),I=1,
     2         NVALUE(IPAR))
             ENDDO
           ENDIF
         ENDDO
      ENDIF
      IF(IMPX.GT.0) THEN 
        WRITE(IOUT,'(43H NCRDRV: NUMBER OF CALCULATIONS IN MULTICOM,
     1  3HPO=,I5)') NCAL
        WRITE(IOUT,'(43H NCRDRV: NUMBER OF MATERIAL MIXTURES IN MUL,
     1  8HTICOMPO=,I5)') NMIL
        WRITE(IOUT,'(43H NCRDRV: NUMBER OF MATERIAL MIXTURES IN MIC,
     1  6HROLIB=,I6)') NMIX
        WRITE(IOUT,'(1X,A)') (COMMEN(I),I=1,NCOMLI)
      ENDIF
      TERP(:NCAL,:NMIX)=0.0
      MIXC(:NMIX)=0
*----
*  READ (INTERP_DATA) AND SET VALI, VALR AND VALH PARAMETERS
*  CORRESPONDING TO THE INTERPOLATION POINT. FILL MUPLET FOR
*  PARAMETERS SET WITHOUT INTERPOLATION.
*----
      IBM=0
      MAXNIS=0
      NISO(:NMIX)=0
      LISO(:NMIX)=.TRUE.
      LDELTA(:NMIX)=.FALSE.
   10 CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
      IF(INDIC.NE.3) CALL XABORT('NCRDRV: CHARACTER DATA EXPECTED.')
   20 IF(TEXT12.EQ.'MIX') THEN
         MUPLET(:NPAR+NLOC)=0
         MUTYPE(:NPAR+NLOC)=0
         VALI(:NPAR)=0
         VALR(:NPAR+NLOC,1)=0.0
         VALR(:NPAR+NLOC,2)=0.0
         DO 30 I=1,NPAR
   30    VALH(I)=' '
         LCUB2(:NPAR+NLOC)=LCUBIC
         CALL REDGET(INDIC,IBM,FLOTT,TEXT12,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('NCRDRV: INTEGER DATA EXPECTED.')
         IF(IBM.GT.NMIX) CALL XABORT('NCRDRV: NMIX OVERFLOW.')
         IBMOLD=1
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('NCRDRV: CHARACTER DATA EXPECTED.')
         IF(TEXT12.EQ.'FROM') THEN
            CALL REDGET(INDIC,IBMOLD,FLOTT,TEXT12,DFLOTT)
            IF(INDIC.NE.1) CALL XABORT('NCRDRV: INTEGER DATA EXPECTED.')
            MIXC(IBM)=IBMOLD
            GO TO 10
         ELSE IF(TEXT12.EQ.'USE') THEN
            MIXC(IBM)=IBM
            GO TO 10
         ENDIF
         MIXC(IBM)=IBMOLD
         GO TO 20
      ELSE IF(TEXT12.EQ.'MICRO') THEN
         IF(IBM.EQ.0) CALL XABORT('NCRDRV: MIX NOT SET (1).')
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('NCRDRV: CHARACTER DATA EXPECTED.')
         IF(TEXT12.EQ.'ALL') THEN
            LISO(IBM)=.TRUE.
         ELSE IF(TEXT12.EQ.'ONLY') THEN
            LISO(IBM)=.FALSE.
         ENDIF
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('NCRDRV: CHARACTER DATA EXPECTED.')
   40    IF(TEXT12.EQ.'ENDMIX') THEN
            GO TO 20
         ELSE
            NISO(IBM)=NISO(IBM)+1
            IF(NISO(IBM).GT.MAXISD) CALL XABORT('NCRDRV: MAXISD OVERFL'
     1      //'OW.')
            MAXNIS=MAX(MAXNIS,NISO(IBM))
            READ(TEXT12,'(2A4)') (HISO(I0,IBM,NISO(IBM)),I0=1,2)
            CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
            IF(INDIC.EQ.2) THEN
               CONC(IBM,NISO(IBM))=FLOTT
            ELSE IF((INDIC.EQ.3).AND.(TEXT12.EQ.'*')) THEN
               CONC(IBM,NISO(IBM))=-99.99
            ELSE
               CALL XABORT('NCRDRV: INVALID HISO DATA.')
            ENDIF
            CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
            IF(INDIC.NE.3) CALL XABORT('NCRDRV: CHARACTER DATA EXPECTE'
     1      //'D.')
            GO TO 40
         ENDIF
      ELSE IF((TEXT12.EQ.'SET').OR.(TEXT12.EQ.'DELTA')) THEN
         IF(IBM.EQ.0) CALL XABORT('NCRDRV: MIX NOT SET (2).')
         ITYPE=0
         IF(TEXT12.EQ.'SET') THEN
            ITYPE=1
         ELSE IF(TEXT12.EQ.'DELTA') THEN
            ITYPE=2
            LDELTA(IBM)=.TRUE.
         ENDIF
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('NCRDRV: CHARACTER DATA EXPECTED.')
         IF((TEXT12.EQ.'LINEAR').OR.(TEXT12.EQ.'CUBIC')) THEN
            HCUBIC=TEXT12
            CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
         ELSE
            HCUBIC=' '
         ENDIF
         IF(INDIC.NE.3) CALL XABORT('NCRDRV: CHARACTER DATA EXPECTED.')
         DO 50 I=1,NPAR
         IF(TEXT12.EQ.PARKEY(I)) THEN
            IPAR=I
            GO TO 60
         ENDIF
   50    CONTINUE
         GO TO 100
   60    IF(HCUBIC.EQ.'LINEAR') THEN
            LCUB2(IPAR)=.FALSE.
         ELSE IF(HCUBIC.EQ.'CUBIC') THEN
            LCUB2(IPAR)=.TRUE.
         ENDIF
         LPCPO=LCMGID(IPCPO,'GLOBAL')
         CALL LCMGET(LPCPO,'NVALUE',NVALUE)
         IF(NVALUE(IPAR).GT.MAXVAL) CALL XABORT('NCRDRV: MAXVAL OVERFL'
     1   //'OW.')
         WRITE(RECNAM,'(''pval'',I8.8)') IPAR
         CALL LCMLEN(LPCPO,RECNAM,LENGTH,ITYLCM)
         IF(LENGTH.EQ.0) THEN
            WRITE(HSMG,'(25HNCRDRV: GLOBAL PARAMETER ,A,9H NOT SET.)')
     1      PARKEY(IPAR)
            CALL XABORT(HSMG)
         ENDIF
         IF(PARFMT(IPAR).EQ.'INTEGER') THEN
            IF(ITYPE.NE.1) CALL XABORT('NCRDRV: SET MANDATORY WITH INT'
     1      //'EGER PARAMETERS.')
            CALL REDGET(INDIC,VALI(IPAR),FLOTT,TEXT12,DFLOTT)
            IF(INDIC.NE.1) CALL XABORT('NCRDRV: INTEGER DATA EXPECTED.')
            CALL LCMGET(LPCPO,RECNAM,VINTE)
            DO 70 J=1,NVALUE(IPAR)
            IF(VALI(IPAR).EQ.VINTE(J)) THEN
               MUPLET(IPAR)=J
               MUTYPE(IPAR)=ITYPE
               GO TO 10
            ENDIF
   70       CONTINUE
            WRITE(HSMG,'(26HNCRDRV: INTEGER PARAMETER ,A,11H WITH VALUE,
     1      I5,34H NOT FOUND IN MULTICOMPO DATABASE.)') PARKEY(IPAR),
     2      VALI(IPAR)
            CALL XABORT(HSMG)
         ELSE IF(PARFMT(IPAR).EQ.'REAL') THEN
            CALL REDGET(INDIC,NITMA,VALR(IPAR,1),TEXT12,DFLOTT)
            IF(INDIC.NE.2) CALL XABORT('NCRDRV: REAL DATA EXPECTED.')
            VALR(IPAR,2)=VALR(IPAR,1)
            CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
            IF(INDIC.EQ.2) THEN
               VALR(IPAR,2)=FLOTT
               CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
            ENDIF
            CALL LCMGET(LPCPO,RECNAM,VREAL)
            IF(VALR(IPAR,1).EQ.VALR(IPAR,2)) THEN
               DO 80 J=1,NVALUE(IPAR)
               IF(ABS(VALR(IPAR,1)-VREAL(J)).LE.REPS*ABS(VREAL(J))) THEN
                  MUPLET(IPAR)=J
                  IF(ITYPE.NE.1) MUPLET(IPAR)=-1
                  MUTYPE(IPAR)=ITYPE
                  GO TO 20
               ENDIF
   80          CONTINUE
            ENDIF
            IF(VALR(IPAR,1).LT.VREAL(1)) THEN
               WRITE(HSMG,'(23HNCRDRV: REAL PARAMETER ,A,10H WITH VALU,
     1         1HE,1P,E12.4,25H IS OUTSIDE THE DOMAIN (<,E12.4,1H))')
     2         PARKEY(IPAR),VALR(IPAR,1),VREAL(1)
               CALL XABORT(HSMG)
            ELSE IF(VALR(IPAR,2).GT.VREAL(NVALUE(IPAR))) THEN
               WRITE(HSMG,'(23HNCRDRV: REAL PARAMETER ,A,10H WITH VALU,
     1         1HE,1P,E12.4,25H IS OUTSIDE THE DOMAIN (>,E12.4,1H))')
     2         PARKEY(IPAR),VALR(IPAR,1),VREAL(NVALUE(IPAR))
               CALL XABORT(HSMG)
            ELSE IF(VALR(IPAR,1).GT.VALR(IPAR,2)) THEN
               WRITE(HSMG,'(23HNCRDRV: REAL PARAMETER ,A,9H IS DEFIN,
     1         7HED WITH,1P,E12.4,2H >,E12.4,1H.)') PARKEY(IPAR),
     2         VALR(IPAR,1),VALR(IPAR,2)
               CALL XABORT(HSMG)
            ENDIF
            MUPLET(IPAR)=-1
            MUTYPE(IPAR)=ITYPE
            GO TO 20
         ELSE IF(PARFMT(IPAR).EQ.'STRING') THEN
            IF(ITYPE.NE.1) CALL XABORT('NCRDRV: SET MANDATORY WITH STR'
     1      //'ING PARAMETERS.')
            CALL REDGET(INDIC,NITMA,FLOTT,VALH(IPAR),DFLOTT)
            IF(INDIC.NE.3) CALL XABORT('NCRDRV: STRING DATA EXPECTED.')
            CALL LCMGTC(LPCPO,RECNAM,12,NVALUE(IPAR),VCHAR)
            DO 90 J=1,NVALUE(IPAR)
            IF(VALH(IPAR).EQ.VCHAR(J)) THEN
               MUPLET(IPAR)=J
               MUTYPE(IPAR)=ITYPE
               GO TO 10
            ENDIF
   90       CONTINUE
            WRITE(HSMG,'(25HNCRDRV: STRING PARAMETER ,A,12H WITH VALUE ,
     1      A12,34H NOT FOUND IN MULTICOMPO DATABASE.)') PARKEY(IPAR),
     2      VALH(IPAR)
            CALL XABORT(HSMG)
         ENDIF
  100    DO 110 I=1,NLOC
         IF(TEXT12.EQ.PARKEL(I)) THEN
            IPAR=NPAR+I
            GO TO 120
         ENDIF
  110    CONTINUE
         CALL XABORT('NCRDRV: PARAMETER '//TEXT12//' NOT FOUND.')
  120    LCUB2(IPAR)=LCUBIC
         JPCPO=LCMGID(IPCPO,'MIXTURES')
         IBMOLD=MIXC(IBM)
         KPCPO=LCMGIL(JPCPO,IBMOLD)
         LPCPO=LCMGID(KPCPO,'TREE')
         CALL LCMGET(LPCPO,'NVALUE',NVALUE)
         CALL REDGET(INDIC,NITMA,VALR(IPAR,1),TEXT12,DFLOTT)
         IF(INDIC.NE.2) CALL XABORT('NCRDRV: REAL DATA EXPECTED.')
         VALR(IPAR,2)=VALR(IPAR,1)
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
         IF(INDIC.EQ.2) THEN
            VALR(IPAR,2)=FLOTT
            CALL REDGET(INDIC,NITMA,FLOTT,TEXT12,DFLOTT)
         ENDIF
         WRITE(RECNAM,'(''pval'',I8.8)') IPAR-NPAR
         CALL LCMLEN(LPCPO,RECNAM,LENGTH,ITYLCM)
         IF(LENGTH.EQ.0) THEN
            WRITE(HSMG,'(24HNCRDRV: LOCAL PARAMETER ,A,9H NOT SET.)')
     1      PARKEL(IPAR-NPAR)
            CALL XABORT(HSMG)
         ELSE IF(LENGTH.GT.MAXVAL) THEN
            CALL XABORT('NCRDRV: MAXVAL OVERFLOW.')
         ENDIF
         CALL LCMGET(LPCPO,RECNAM,VREAL)
         IF(VALR(IPAR,1).EQ.VALR(IPAR,2)) THEN
            DO 130 J=1,NVALUE(IPAR-NPAR)
            IF(ABS(VALR(IPAR,1)-VREAL(J)).LE.REPS*ABS(VREAL(J))) THEN
               MUPLET(IPAR)=J
               IF(ITYPE.NE.1) MUPLET(IPAR)=-1
               MUTYPE(IPAR)=ITYPE
               GO TO 20
            ENDIF
  130       CONTINUE
         ENDIF
         IF(VALR(IPAR,1).LT.VREAL(1)) THEN
            WRITE(HSMG,'(23HNCRDRV: REAL PARAMETER ,A,11H WITH VALUE,
     1      1P,E12.4,25H IS OUTSIDE THE DOMAIN (<,E12.4,1H))')
     2      PARKEL(IPAR-NPAR),VALR(IPAR,1),VREAL(1)
            CALL XABORT(HSMG)
         ELSE IF(VALR(IPAR,2).GT.VREAL(NVALUE(IPAR-NPAR))) THEN
            WRITE(HSMG,'(23HNCRDRV: REAL PARAMETER ,A,11H WITH VALUE,
     1      1P,E12.4,25H IS OUTSIDE THE DOMAIN (>,E12.4,1H))')
     2      PARKEL(IPAR-NPAR),VALR(IPAR,2),VREAL(NVALUE(IPAR-NPAR))
            CALL XABORT(HSMG)
         ELSE IF(VALR(IPAR,1).GT.VALR(IPAR,2)) THEN
            WRITE(HSMG,'(23HNCRDRV: REAL PARAMETER ,A,9H IS DEFIN,
     1      7HED WITH,1P,E12.4,2H >,E12.4,1H.)') PARKEL(IPAR-NPAR),
     2      VALR(IPAR,1),VALR(IPAR,2)
            CALL XABORT(HSMG)
         ENDIF
         MUPLET(IPAR)=-1
         MUTYPE(IPAR)=ITYPE
         GO TO 20
      ELSE IF(TEXT12.EQ.'ENDMIX') THEN
*----
*  COMPUTE THE TERP FACTORS USING TABLE-OF-CONTENT INFORMATION.
*----
         IF(IMPX.GT.0) THEN
           DO IPAR=1,NPAR
             IF(PARFMT(IPAR).EQ.'REAL')THEN
               IF(LCUB2(IPAR)) THEN
                 WRITE(IOUT,'(26H NCRDRV: GLOBAL PARAMETER:,A12,5H ->CU,
     1           18HBIC INTERPOLATION.)') PARKEY(IPAR)
               ELSE
                 WRITE(IOUT,'(26H NCRDRV: GLOBAL PARAMETER:,A12,5H ->LI,
     1           19HNEAR INTERPOLATION.)') PARKEY(IPAR)
               ENDIF
             ENDIF
           ENDDO
           DO IPAR=1,NLOC
             IF(LCUB2(NPAR+IPAR)) THEN
               WRITE(IOUT,'(25H NCRDRV: LOCAL PARAMETER:,A12,8H ->CUBIC,
     1         14HINTERPOLATION.)') PARKEL(IPAR)
             ELSE
               WRITE(IOUT,'(25H NCRDRV: LOCAL PARAMETER:,A12,8H ->LINEA,
     1         16HR INTERPOLATION.)') PARKEL(IPAR)
             ENDIF
           ENDDO
         ENDIF
         IF(IBMOLD.GT.NMIL) CALL XABORT('NCRDRV: MIX OVERFLOW (COMPO).')
         IF(IBM.GT.NMIX) CALL XABORT('NCRDRV: MIX OVERFLOW (MICROLIB).')
         IF(NCAL.EQ.1) THEN
           TERP(1,IBM)=1.0
         ELSE
           CALL NCRTRP(IPCPO,LCUB2,IMPX,IBMOLD,NPAR,NLOC,NCAL,MUPLET,
     1     MUTYPE,VALR,0.0,TERP(1,IBM))
         ENDIF
         IBM=0
      ELSE IF((TEXT12.EQ.'COMPO').OR.(TEXT12.EQ.'TABLE').OR.
     1   (TEXT12.EQ.';')) THEN
*----
*  CHECK TERP FACTORS AND RETURN
*----
         IF(TEXT12.EQ.';') ITER=0
         IF(TEXT12.EQ.'COMPO') ITER=1
         IF(TEXT12.EQ.'TABLE') ITER=2
         DO 150 IBM=1,NMIX
         IBMOLD=MIXC(IBM)
         IF(IBMOLD.EQ.0) GO TO 150
         IF(NISO(IBM).GT.MAXNIS) CALL XABORT('NCRDRV: MAXNIS OVERFLOW.')
         IF(LDELTA(IBM)) THEN
            SUM=0.0
         ELSE
            SUM=1.0
         ENDIF
         DO 140 ICAL=1,NCAL
  140    SUM=SUM-TERP(ICAL,IBM)
         IF(ABS(SUM).GT.1.0E-4) THEN
            WRITE(HSMG,'(43HNCRDRV: INVALID INTERPOLATION FACTORS IN MI,
     1      5HXTURE,I4,1H.)') IBM
            CALL XABORT(HSMG)
         ENDIF
  150    CONTINUE
         GO TO 160
      ELSE
         CALL XABORT('NCRDRV: '//TEXT12//' IS AN INVALID KEYWORD.')
      ENDIF
      GO TO 10
*----
*  PRINT INTERPOLATION (TERP) FACTORS
*----
  160 IF(IMPX.GT.2) THEN
        WRITE(IOUT,'(/30H NCRDRV: INTERPOLATION FACTORS)')
        DO ICAL=1,NCAL
          DO IBM=1,NMIX
            IF(TERP(ICAL,IBM).NE.0.0) THEN
              WRITE(IOUT,170) ICAL,(TERP(ICAL,JBM),JBM=1,NMIX)
              EXIT
            ENDIF
          ENDDO
        ENDDO
      ENDIF
*----
*  SCRATCH STORAGE DEALLOCATION
*----
      DEALLOCATE(LDELTA)
      RETURN
  170 FORMAT(6H CALC=,I8,6H TERP=,1P,8E13.5/(20X,8E13.5))
      END
