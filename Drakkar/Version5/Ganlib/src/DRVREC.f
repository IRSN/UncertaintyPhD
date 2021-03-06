*DECK DRVREC
      SUBROUTINE DRVREC(NENTRY,HENTRY,IENTRY,JENTRY,KENTRY)
*
*-----------------------------------------------------------------------
*
* RECOVER ONE OR MANY LINKED LISTS OR FILES.
*
* INPUT/OUTPUT PARAMETERS:
*  NENTRY : NUMBER OF LINKED LISTS AND FILES USED BY THE MODULE.
*  HENTRY : CHARACTER*12 NAME OF EACH LINKED LIST OR FILE.
*  IENTRY : =0 CLE-2000 VARIABLE; =1 LINKED LIST; =2 XSM FILE;
*           =3 SEQUENTIAL BINARY FILE; =4 SEQUENTIAL ASCII FILE;
*           =5 DIRECT ACCESS FILE.
*  JENTRY : =0 THE LINKED LIST OR FILE IS CREATED.
*           =1 THE LINKED LIST OR FILE IS OPEN FOR MODIFICATIONS;
*           =2 THE LINKED LIST OR FILE IS OPEN IN READ-ONLY MODE.
*  KENTRY : FILE UNIT NUMBER OR LINKED LIST ADDRESS.
*           DIMENSION HENTRY(NENTRY),IENTRY(NENTRY),JENTRY(NENTRY),
*           KENTRY(NENTRY)
*
*-------------------------------------- AUTHOR: A. HEBERT ; 25/03/94 ---
*
      USE GANLIB
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER NENTRY,IENTRY(NENTRY),JENTRY(NENTRY)
      TYPE(C_PTR) KENTRY(NENTRY)
      CHARACTER HENTRY(NENTRY)*12
*----
*  LOCAL VARIABLES
*----
      TYPE(C_PTR) IPLIST,JPLIST
      CHARACTER HMEDIA*12,TEXT12*12,TEXT4*4,NAMT*12
      DOUBLE PRECISION DFLOTT
*
      IF(NENTRY.LE.1) CALL XABORT('DRVREC: TWO PARAMETERS EXPECTED.')
      ITYPE=0
      JPLIST=C_NULL_PTR
      DO 10 I=1,NENTRY
      IF(JENTRY(I).EQ.2) THEN
         ITYPE=IENTRY(I)
         IPLIST=KENTRY(I)
         HMEDIA=HENTRY(I)
         IF((IENTRY(I).NE.1).AND.(IENTRY(I).NE.2)) CALL XABORT('DRVREC:'
     1   //' RHS LINKED LIST OR XSM FILE EXPECTED.')
         GO TO 20
      ENDIF
   10 CONTINUE
      CALL XABORT('DRVREC: UNABLE TO FIND A BACKUP MEDIA OPEN IN READ-O'
     1 //'NLY MODE.')
*
   20 IMPX=1
   30 CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
      IF(INDIC.EQ.10) GO TO 40
      IF(INDIC.NE.3) CALL XABORT('DRVREC: CHARACTER DATA EXPECTED.')
      IF(TEXT4.EQ.'EDIT') THEN
         CALL REDGET(INDIC,IMPX,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.1) CALL XABORT('DRVREC: INTEGER DATA EXPECTED.')
      ELSE IF(TEXT4.EQ.'STEP') THEN
*        CHANGE THE HIERARCHICAL LEVEL ON THE LCM OBJECT.
         IF(ITYPE.GT.2) CALL XABORT('DRVREC: UNABLE TO STEP INTO A SE'
     1   //'QUENTIAL FILE.')
         CALL REDGET(INDIC,NITMA,FLOTT,TEXT4,DFLOTT)
         IF(INDIC.NE.3) CALL XABORT('DRVREC: CHARACTER DATA EXPECTED.')
         IF(TEXT4.EQ.'UP') THEN
            CALL REDGET(INDIC,NITMA,FLOTT,NAMT,DFLOTT)
            IF(INDIC.NE.3) CALL XABORT('DRVREC: CHARACTER DATA EXPECT'
     1      //'ED.')
            IF(IMPX.GT.0) WRITE (6,100) NAMT
            JPLIST=LCMGID(IPLIST,NAMT)
         ELSE IF(TEXT4.EQ.'AT') THEN
            CALL REDGET(INDIC,NITMA,FLOTT,NAMT,DFLOTT)
            IF(INDIC.NE.1) CALL XABORT('DRVREC: INTEGER EXPECTED.')
            IF(IMPX.GT.0) WRITE (6,110) NITMA
            JPLIST=LCMGIL(IPLIST,NITMA)
         ELSE
            CALL XABORT('DRVREC: UP OR AT EXPECTED.')
         ENDIF
         IPLIST=JPLIST
      ELSE IF(TEXT4.EQ.';') THEN
         GO TO 40
      ELSE
         CALL XABORT('DRVREC: '//TEXT4//' IS AN INVALID KEY WORD.')
      ENDIF
      GO TO 30
*
   40 CALL LCMGTC(IPLIST,'SIGNATURE',12,1,TEXT12)
      IF(TEXT12.NE.'L_ARCHIVES') THEN
         CALL XABORT('DRVREC: SIGNATURE OF '//HMEDIA//' IS '//TEXT12//
     1   '. L_ARCHIVES EXPECTED.')
      ENDIF
      DO 50 I=1,NENTRY
      IF((JENTRY(I).EQ.0).OR.(JENTRY(I).EQ.1)) THEN
         IF(IENTRY(I).GT.2) CALL XABORT('DRVREC: LHS LINKED LIST OR XSM'
     1   //' FILE EXPECTED.')
         IF(IMPX.GT.0) WRITE (6,'(/18H DRVREC: RECOVER '',A12,
     1   8H'' FROM '',A12,2H''.)') HENTRY(I),HMEDIA
         TEXT12=HENTRY(I)
         CALL LCMLEN(IPLIST,TEXT12,ILEN,ITYLCM)
         IF((ILEN.EQ.0).OR.(ITYLCM.NE.0)) THEN
            CALL LCMLIB(IPLIST)
            CALL XABORT('DRVREC: UNABLE TO FIND '//TEXT12//' ON THE BAC'
     1      //'KUP MEDIA NAMED '//HMEDIA//'.')
         ENDIF
         CALL LCMSIX(IPLIST,HENTRY(I),1)
         CALL LCMEQU(IPLIST,KENTRY(I))
         CALL LCMSIX(IPLIST,' ',2)
      ENDIF
   50 CONTINUE
      RETURN
*
  100 FORMAT (/27H DRVREC: STEP UP TO LEVEL ',A12,2H'.)
  110 FORMAT (/26H DRVREC: STEP AT COMPONENT,I6,1H.)
      END
